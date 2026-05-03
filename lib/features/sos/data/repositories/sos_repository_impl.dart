import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/battery_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../trek/domain/entities/breadcrumb.dart';
import '../../../trek/domain/usecases/latest_trek_breadcrumbs.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/entities/sos_dispatch_result.dart';
import '../../domain/repositories/sos_outbox_repository.dart';
import '../../domain/repositories/sos_repository.dart';
import '../datasources/sms_data_source.dart';
import '../datasources/sos_alerts_remote_data_source.dart';

class SosRepositoryImpl implements SosRepository {
  SosRepositoryImpl({
    required LocationService location,
    required BatteryService battery,
    required SmsDataSource sms,
    required SosAlertsRemoteDataSource alertsDs,
    required SosOutboxRepository outbox,
    required LatestTrekBreadcrumbs latestBreadcrumbs,
  })  : _location = location,
        _battery = battery,
        _sms = sms,
        _alerts = alertsDs,
        _outbox = outbox,
        _latestBreadcrumbs = latestBreadcrumbs;

  /// Iter 5a: number of recent breadcrumbs piggybacked on each SOS alert
  /// so responders can see the last known trail.
  static const int _breadcrumbAttachLimit = 50;

  final LocationService _location;
  final BatteryService _battery;
  final SmsDataSource _sms;
  final SosAlertsRemoteDataSource _alerts;
  final SosOutboxRepository _outbox;
  final LatestTrekBreadcrumbs _latestBreadcrumbs;

  @override
  Future<Result<SosDispatchResult>> fire({
    required String uid,
    required String userName,
    required String userEmail,
    required List<EmergencyContact> contacts,
  }) async {
    if (contacts.isEmpty) {
      return Failure<SosDispatchResult>(
        const ValidationError('No emergency contacts configured.'),
      );
    }

    final hasPerm = await _location.hasForegroundPermission();
    if (!hasPerm) {
      return Failure<SosDispatchResult>(
        const PermissionError('Location permission required.'),
      );
    }

    // Single-shot GPS + battery in parallel.
    try {
      final fixFuture = _location.getCurrentPosition();
      final battFuture = _battery.level();
      final fix = await fixFuture;
      final batt = await battFuture;

      // Trail attachment is best-effort — a sqflite read failure must not
      // block dispatch.
      List<Breadcrumb> crumbs = const [];
      try {
        crumbs = await _latestBreadcrumbs(limit: _breadcrumbAttachLimit);
      } catch (_) {
        crumbs = const [];
      }

      final notified = contacts
          .map((c) => NotifiedContact(
                name: c.name,
                phone: c.phone,
                isPrimary: c.isPrimary,
              ))
          .toList();
      final alert = SosAlert(
        uid: uid,
        lat: fix.latitude,
        lng: fix.longitude,
        accuracy: fix.accuracy,
        altitude: fix.altitude,
        batteryLevel: batt,
        userName: userName,
        userEmail: userEmail,
        contactsNotified: notified,
        trekBreadcrumbs: crumbs,
      );

      // SMS deep-links — one per contact, fire-and-forget. Failures are
      // logged via the launcher but never block the Firestore write.
      final body = _smsBody(userName, fix.latitude, fix.longitude);
      for (final c in contacts) {
        try {
          await _sms.sendSms(phone: c.phone, body: body);
        } catch (_) {
          // Swallow — SMS open failure shouldn't abort the alert.
        }
      }

      // Firestore write; on failure, queue.
      try {
        final alertId = await _alerts.create(alert);
        return Success<SosDispatchResult>(SosDispatchResult(
          alertId: alertId,
          queued: false,
          contactsCount: contacts.length,
        ));
      } catch (_) {
        final enqueued = await _outbox.enqueueAlert(alert);
        // Surface the outbox row id in the alertId so SosCubit can
        // delete the row on cancel before the retry processor sends it.
        final rowId = switch (enqueued) {
          Success<int>(:final value) => value,
          Failure<int>() => -1,
        };
        return Success<SosDispatchResult>(SosDispatchResult(
          alertId: 'pending:$rowId',
          queued: true,
          contactsCount: contacts.length,
        ));
      }
    } on PermissionError catch (e) {
      return Failure<SosDispatchResult>(e);
    } catch (e) {
      return Failure<SosDispatchResult>(
        NetworkError('Failed to acquire SOS payload.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> cancel(String alertId) async {
    try {
      await _alerts.cancel(alertId);
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to cancel SOS.', cause: e),
      );
    }
  }

  @override
  Future<Result<int>> flushExpired(
    String uid, {
    Duration ttl = const Duration(hours: 6),
  }) async {
    try {
      final cutoff = DateTime.now().subtract(ttl);
      final ids = await _alerts.findExpiredActiveIds(uid, cutoff);
      for (final id in ids) {
        await _alerts.markTimedOut(id);
      }
      return Success<int>(ids.length);
    } catch (e) {
      return Failure<int>(
        NetworkError('Failed to flush expired SOS alerts.', cause: e),
      );
    }
  }

  static String _smsBody(String userName, double lat, double lng) {
    return 'SOS from $userName. My location: '
        'https://maps.google.com/?q=$lat,$lng';
  }
}
