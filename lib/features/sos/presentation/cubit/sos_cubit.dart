import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/sos_outbox_repository.dart';
import '../../domain/usecases/cancel_sos.dart';
import '../../domain/usecases/fire_sos.dart';
import '../../domain/usecases/flush_expired_alerts.dart';
import '../../domain/usecases/process_sos_outbox.dart';
import '../../domain/usecases/start_sos_tracking.dart';
import '../../domain/usecases/stop_sos_tracking.dart';
import 'sos_state.dart';

class SosCubit extends Cubit<SosState> {
  SosCubit({
    required FireSos fireSos,
    required CancelSos cancelSos,
    required ProcessSosOutbox processOutbox,
    required SosOutboxRepository outbox,
    required ConnectivityService connectivity,
    required LocationService location,
    required StartSosTracking startTracking,
    required StopSosTracking stopTracking,
    required FlushExpiredAlerts flushExpired,
  })  : _fire = fireSos,
        _cancel = cancelSos,
        _processOutbox = processOutbox,
        _outbox = outbox,
        _connectivity = connectivity,
        _location = location,
        _startTracking = startTracking,
        _stopTracking = stopTracking,
        _flushExpired = flushExpired,
        super(const SosIdle()) {
    _connSub = _connectivity.onConnectivityChanged().listen(
      (online) {
        if (online) unawaited(_processOutbox());
      },
      // Don't let a transient stream error tear down the singleton's
      // outbox-retry trigger.
      onError: (Object _) {},
      cancelOnError: false,
    );
    // Cold-start retry — fire-and-forget so we don't block construction.
    unawaited(_processOutbox());
    unawaited(_refreshPermissionFlag());
  }

  final FireSos _fire;
  final CancelSos _cancel;
  final ProcessSosOutbox _processOutbox;
  final SosOutboxRepository _outbox;
  final ConnectivityService _connectivity;
  final LocationService _location;
  final StartSosTracking _startTracking;
  final StopSosTracking _stopTracking;
  final FlushExpiredAlerts _flushExpired;

  /// Iter 5b EC-3: cold-start 6 h timeout flush. Called from outside
  /// the cubit (`SosBootstrap` via the auth-state listener) once a UID
  /// is available, since the cubit itself is constructed before auth
  /// resolves. Idempotent — repeated calls just re-query Firestore.
  Future<void> flushExpiredOnBoot(String uid) async {
    await _flushExpired(uid);
  }

  StreamSubscription<bool>? _connSub;
  Timer? _countdownTimer;

  /// Updated by the contacts page on every emit so the FAB pre-flight
  /// can trust [SosState.hasPrimaryContact].
  void onContactsChanged(List<EmergencyContact> contacts) {
    final hasPrimary = contacts.any((c) => c.isPrimary);
    final next = _rebuild(hasPrimaryContact: hasPrimary);
    if (next != state) emit(next);
  }

  Future<void> _refreshPermissionFlag() async {
    final granted = await _location.hasForegroundPermission();
    if (isClosed) return;
    final next = _rebuild(locationPermissionGranted: granted);
    if (next != state) emit(next);
  }

  Future<void> onFabPressed({
    required String uid,
    required String userName,
    required String userEmail,
    required List<EmergencyContact> contacts,
  }) async {
    if (isClosed) return;
    if (state is SosCountdown || state is SosDispatching) return;
    if (!contacts.any((c) => c.isPrimary)) {
      emit(SosError(
        message: 'Add a primary emergency contact in Settings → Safety.',
        hasPrimaryContact: false,
        locationPermissionGranted: state.locationPermissionGranted,
      ));
      return;
    }
    final granted = await _location.requestForegroundPermission();
    if (isClosed) return;
    if (!granted) {
      emit(SosError(
        message: 'Location permission required to send SOS.',
        hasPrimaryContact: state.hasPrimaryContact,
        locationPermissionGranted: false,
      ));
      return;
    }
    _startCountdown(uid, userName, userEmail, contacts);
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (state is SosCountdown) emit(_rebuildIdle());
  }

  void _startCountdown(
    String uid,
    String userName,
    String userEmail,
    List<EmergencyContact> contacts,
  ) {
    var remaining = 3;
    emit(SosCountdown(
      remainingSeconds: remaining,
      hasPrimaryContact: state.hasPrimaryContact,
      locationPermissionGranted: state.locationPermissionGranted,
    ));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (isClosed) {
        t.cancel();
        return;
      }
      remaining -= 1;
      if (remaining <= 0) {
        t.cancel();
        await _dispatch(uid, userName, userEmail, contacts);
      } else {
        emit(SosCountdown(
          remainingSeconds: remaining,
          hasPrimaryContact: state.hasPrimaryContact,
          locationPermissionGranted: state.locationPermissionGranted,
        ));
      }
    });
  }

  Future<void> _dispatch(
    String uid,
    String userName,
    String userEmail,
    List<EmergencyContact> contacts,
  ) async {
    if (isClosed) return;
    emit(SosDispatching(
      hasPrimaryContact: state.hasPrimaryContact,
      locationPermissionGranted: state.locationPermissionGranted,
    ));
    final result = await _fire(
      uid: uid,
      userName: userName,
      userEmail: userEmail,
      contacts: contacts,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final value):
        if (value.queued) {
          // Queued path: outbox processor handles retry; no live
          // tracking against a `pending:<rowId>` alertId (would fail
          // the parent-uid Firestore rule on every breadcrumb).
          emit(SosDispatched(
            alertId: value.alertId,
            queued: true,
            contactsCount: value.contactsCount,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
          return;
        }
        // Iter 5b: live SOS tracking opens a long-running position
        // stream that on iOS would trigger the OS "Allow Always"
        // upgrade prompt when the app first backgrounds — without our
        // in-app disclosure ever being shown. We must not invite that
        // prompt cold. If background permission isn't already granted,
        // the SOS still dispatches (single-shot GPS + SMS + Firestore
        // write all succeed in foreground), but no live trail flows.
        // The user can grant background permission later via the trek
        // consent flow and a future SOS will then track live.
        final hasBgPerm = await _location.hasBackgroundPermission();
        if (isClosed) return;
        if (!hasBgPerm) {
          emit(SosDispatched(
            alertId: value.alertId,
            queued: false,
            contactsCount: value.contactsCount,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
          return;
        }
        // Live path: open the active-tracking subscription before
        // emitting any post-dispatch state, so a fast cancel cannot
        // race the SosActive emit. On tracking failure we surface
        // SosError per plan §7 #2.
        final track = await _startTracking(value.alertId);
        if (isClosed) return;
        if (track is Failure<void>) {
          // Best-effort cancel of the alert doc since live tracking
          // never started — leaving it `active` would let the 6h
          // flush eventually clean it up, but immediate cancel is
          // honest about the SOS state.
          unawaited(_cancel(value.alertId));
          emit(SosError(
            message: track.error.message,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
          return;
        }
        emit(SosActive(
          alertId: value.alertId,
          hasPrimaryContact: state.hasPrimaryContact,
          locationPermissionGranted: state.locationPermissionGranted,
        ));
      case Failure(:final error):
        emit(SosError(
          message: error.message,
          hasPrimaryContact: state.hasPrimaryContact,
          locationPermissionGranted: state.locationPermissionGranted,
        ));
    }
  }

  Future<void> cancelDispatched() async {
    final s = state;
    // Iter 5b: SosActive is the live-tracking state that succeeds
    // SosDispatched(queued=false). Both terminate via cancelDispatched.
    if (s is SosDispatched) {
      if (s.queued) {
        // Cancelling an offline (queued) SOS deletes the outbox row so
        // the retry processor never replays it after reconnect. The id
        // is encoded as `pending:<rowId>` by SosRepositoryImpl.fire.
        final parts = s.alertId.split(':');
        if (parts.length == 2 && parts[0] == 'pending') {
          final rowId = int.tryParse(parts[1]);
          if (rowId != null && rowId >= 0) {
            await _outbox.deleteQueued(rowId);
          }
        }
        emit(SosCancelledState(
          alertId: s.alertId,
          hasPrimaryContact: state.hasPrimaryContact,
          locationPermissionGranted: state.locationPermissionGranted,
        ));
        return;
      }
      final result = await _cancel(s.alertId);
      if (isClosed) return;
      switch (result) {
        case Success():
          emit(SosCancelledState(
            alertId: s.alertId,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
        case Failure(:final error):
          emit(SosError(
            message: error.message,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
      }
      return;
    }
    if (s is SosActive) {
      // Stop the live position stream (which also resumes any
      // suspended trek session) before flipping the alert status.
      await _stopTracking();
      if (isClosed) return;
      final result = await _cancel(s.alertId);
      if (isClosed) return;
      switch (result) {
        case Success():
          emit(SosCancelledState(
            alertId: s.alertId,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
        case Failure(:final error):
          emit(SosError(
            message: error.message,
            hasPrimaryContact: state.hasPrimaryContact,
            locationPermissionGranted: state.locationPermissionGranted,
          ));
      }
      return;
    }
  }

  void clearError() {
    if (state is SosError) emit(_rebuildIdle());
  }

  SosState _rebuild({
    bool? hasPrimaryContact,
    bool? locationPermissionGranted,
  }) {
    final hp = hasPrimaryContact ?? state.hasPrimaryContact;
    final lp = locationPermissionGranted ?? state.locationPermissionGranted;
    return switch (state) {
      SosIdle() => SosIdle(
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosCountdown(:final remainingSeconds) => SosCountdown(
          remainingSeconds: remainingSeconds,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosDispatching() => SosDispatching(
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosDispatched(:final alertId, :final queued, :final contactsCount) =>
        SosDispatched(
          alertId: alertId,
          queued: queued,
          contactsCount: contactsCount,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosActive(:final alertId, :final breadcrumbsSent) => SosActive(
          alertId: alertId,
          breadcrumbsSent: breadcrumbsSent,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosCancelledState(:final alertId) => SosCancelledState(
          alertId: alertId,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosTimedOut(:final alertId) => SosTimedOut(
          alertId: alertId,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
      SosError(:final message) => SosError(
          message: message,
          hasPrimaryContact: hp,
          locationPermissionGranted: lp,
        ),
    };
  }

  SosState _rebuildIdle() => SosIdle(
        hasPrimaryContact: state.hasPrimaryContact,
        locationPermissionGranted: state.locationPermissionGranted,
      );

  @override
  Future<void> close() async {
    _countdownTimer?.cancel();
    await _connSub?.cancel();
    return super.close();
  }
}
