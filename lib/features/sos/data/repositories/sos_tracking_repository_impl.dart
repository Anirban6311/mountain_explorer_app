import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/battery_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../trek/domain/entities/breadcrumb.dart';
import '../../../trek/domain/repositories/trek_repository.dart';
import '../../domain/repositories/sos_tracking_repository.dart';
import '../datasources/sos_breadcrumbs_remote_data_source.dart';

class SosTrackingRepositoryImpl implements SosTrackingRepository {
  SosTrackingRepositoryImpl({
    required LocationService location,
    required BatteryService battery,
    required SosBreadcrumbsRemoteDataSource breadcrumbs,
    required TrekRepository trek,
  })  : _location = location,
        _battery = battery,
        _breadcrumbs = breadcrumbs,
        _trek = trek;

  /// Iter 5b §10 Phase 4: 30 s default cadence; 120 s when battery is
  /// below the threshold. Mirrors the TrekRepositoryImpl flip pattern,
  /// only the constants differ.
  static const Duration _normalCadence = Duration(seconds: 30);
  static const Duration _lowBatteryCadence = Duration(seconds: 120);
  static const int _lowBatteryThreshold = 20;

  static const String _notificationTitle = 'SOS active — tracking';
  static const String _notificationBody =
      'Tap to open Mountain Explorer.';

  final LocationService _location;
  final BatteryService _battery;
  final SosBreadcrumbsRemoteDataSource _breadcrumbs;
  final TrekRepository _trek;

  StreamSubscription<Position>? _positionSub;
  Duration _activeCadence = _normalCadence;
  String? _activeAlertId;

  final StreamController<String?> _alertController =
      StreamController<String?>.broadcast();

  @override
  Future<Result<void>> start(String alertId) async {
    // Idempotency guard: a second start for the same alertId leaves the
    // subscription untouched. Different alertId mid-flight is treated
    // as a programmer error — the cubit must stop() first.
    if (_activeAlertId == alertId && _positionSub != null) {
      return const Success<void>(null);
    }
    try {
      await _trek.suspend();
      _activeAlertId = alertId;
      _activeCadence = _normalCadence;
      _alertController.add(alertId);
      await _subscribeStream();
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to start SOS tracking.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> stop() async {
    Object? cancelError;
    try {
      try {
        await _positionSub?.cancel();
      } catch (e) {
        // Capture but don't rethrow yet — we still need to resume trek
        // so it doesn't stay suspended forever after a stop failure.
        cancelError = e;
      } finally {
        _positionSub = null;
        _activeAlertId = null;
        _alertController.add(null);
      }
      await _trek.resume();
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to stop SOS tracking.', cause: e),
      );
    }
    if (cancelError != null) {
      return Failure<void>(
        UnknownError('Failed to cancel SOS position stream.',
            cause: cancelError),
      );
    }
    return const Success<void>(null);
  }

  @override
  Stream<String?> watchActiveAlertId() async* {
    yield _activeAlertId;
    yield* _alertController.stream;
  }

  /// Releases the broadcast controller and any live subscription. Called
  /// by the get_it `dispose:` callback when the singleton is unregistered
  /// (test teardown). Production lifetime is the full process — this is
  /// effectively a test-hygiene method.
  Future<void> dispose() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _alertController.close();
  }

  Future<void> _subscribeStream() async {
    await _positionSub?.cancel();
    _positionSub = _location
        .trekPositionStream(
          interval: _activeCadence,
          notificationTitle: _notificationTitle,
          notificationBody: _notificationBody,
        )
        .listen(_onPosition, onError: (Object e) {
      _alertController.addError(e);
    });
  }

  Future<void> _onPosition(Position p) async {
    final alertId = _activeAlertId;
    if (alertId == null) return;
    final battery = await _battery.level();
    final crumb = Breadcrumb(
      ts: p.timestamp,
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      altitude: p.altitude,
      battery: battery,
    );
    await _breadcrumbs.append(alertId, crumb);

    final shouldBeLow =
        battery != null && battery < _lowBatteryThreshold;
    final isLow = _activeCadence == _lowBatteryCadence;
    if (shouldBeLow && !isLow) {
      _activeCadence = _lowBatteryCadence;
      await _subscribeStream();
    } else if (!shouldBeLow && isLow) {
      _activeCadence = _normalCadence;
      await _subscribeStream();
    }
  }
}
