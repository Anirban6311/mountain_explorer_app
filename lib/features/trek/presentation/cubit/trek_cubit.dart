import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../domain/usecases/start_trek.dart';
import '../../domain/usecases/stop_trek.dart';
import '../../domain/usecases/watch_active_session.dart';
import '../../domain/usecases/watch_breadcrumb_count.dart';
import 'trek_state.dart';

class TrekCubit extends Cubit<TrekState> {
  TrekCubit({
    required StartTrek startTrek,
    required StopTrek stopTrek,
    required WatchActiveTrekSession watchSession,
    required WatchBreadcrumbCount watchCount,
    required LocationService location,
    required AppPrefs prefs,
  })  : _start = startTrek,
        _stop = stopTrek,
        _watchSession = watchSession,
        _watchCount = watchCount,
        _location = location,
        _prefs = prefs,
        super(const TrekIdle()) {
    _sessionSub = _watchSession().listen(
      _onSession,
      onError: _onSessionError,
    );
    _countSub = _watchCount().listen(_onCount);
  }

  final StartTrek _start;
  final StopTrek _stop;
  final WatchActiveTrekSession _watchSession;
  final WatchBreadcrumbCount _watchCount;
  final LocationService _location;
  final AppPrefs _prefs;

  StreamSubscription<String?>? _sessionSub;
  StreamSubscription<int>? _countSub;

  /// Resumes an active trek if `AppPrefs.activeTrekSessionId` is set
  /// AND background-location permission is still granted. Idempotent.
  Future<void> bootstrap() async {
    if (isClosed) return;
    final hasPerm = await _location.hasBackgroundPermission();
    final stored = _prefs.getActiveTrekSessionId();
    if (stored == null) {
      emit(TrekIdle(hasBackgroundPermission: hasPerm));
      return;
    }
    if (!hasPerm) {
      // Permission was revoked while the app was backgrounded/killed.
      // Clear the stale id and surface idle.
      await _prefs.setActiveTrekSessionId(null);
      emit(const TrekIdle(hasBackgroundPermission: false));
      return;
    }
    // Resume by re-issuing start; the repo will mint a new id since the
    // old session's stream is gone. Cleaner than trying to re-attach.
    await _start();
  }

  /// Initiates a trek. If background-location permission is missing the
  /// user is shown the consent disclosure (Iter 1 page); on Allow we
  /// request permission and proceed.
  Future<void> start(BuildContext context) async {
    if (isClosed) return;
    if (state is TrekActive) return;

    final hasPerm = await _location.hasBackgroundPermission();
    if (!hasPerm) {
      if (!context.mounted) return;
      final accepted =
          await context.push<bool>(Routes.backgroundLocationConsent);
      if (accepted != true) {
        emit(TrekError(
          message: 'Background location declined.',
          hasBackgroundPermission: false,
        ));
        return;
      }
      // Android 11+ (and iOS) require foreground location to be granted
      // BEFORE the background-location prompt can be shown. The
      // LocationService throws a Bad-state error otherwise, so we
      // upgrade the foreground grant first. On a fresh install or for
      // a user who hit Start Trek before ever using the Map/SOS, this
      // is the first prompt they see; on devices that already granted
      // foreground (via SOS), this is a fast no-op.
      final fgGranted = await _location.requestForegroundPermission();
      if (!fgGranted) {
        emit(const TrekError(
          message: 'Location permission denied.',
          hasBackgroundPermission: false,
        ));
        return;
      }
      final granted = await _location.requestBackgroundPermission();
      if (!granted) {
        emit(const TrekError(
          message: 'Background location permission denied.',
          hasBackgroundPermission: false,
        ));
        return;
      }
      // Refresh the flag so any state emitted after _start() (notably
      // the _onSession TrekActive transition) carries the up-to-date
      // permission status.
      emit(const TrekIdle(hasBackgroundPermission: true));
    }

    final result = await _start();
    if (isClosed) return;
    if (result is Failure<String>) {
      emit(TrekError(
        message: result.error.message,
        hasBackgroundPermission: state.hasBackgroundPermission,
      ));
    }
    // Success → the watchActiveSession stream emits and _onSession
    // transitions us to TrekActive.
  }

  Future<void> stop() async {
    if (isClosed) return;
    final result = await _stop();
    if (isClosed) return;
    if (result is Failure<void>) {
      emit(TrekError(
        message: result.error.message,
        hasBackgroundPermission: state.hasBackgroundPermission,
      ));
    }
    // Success → watchActiveSession emits null and _onSession
    // transitions us back to TrekIdle.
  }

  void _onSession(String? id) {
    if (isClosed) return;
    if (id == null) {
      emit(TrekIdle(
        hasBackgroundPermission: state.hasBackgroundPermission,
      ));
    } else {
      final count = state is TrekActive
          ? (state as TrekActive).breadcrumbCount
          : 0;
      emit(TrekActive(
        sessionId: id,
        breadcrumbCount: count,
        hasBackgroundPermission: state.hasBackgroundPermission,
      ));
    }
  }

  void _onCount(int count) {
    if (isClosed) return;
    final s = state;
    if (s is TrekActive) {
      emit(s.copyWith(breadcrumbCount: count));
    }
  }

  /// Reached when the position stream errors mid-trek (typically the user
  /// revoking background-location at runtime or the foreground service
  /// being killed by the OS). Plan §7 #1: clear the active session pref
  /// and surface a user-visible TrekError so the cold-start resume path
  /// won't re-issue against the now-revoked permission.
  Future<void> _onSessionError(Object e, StackTrace _) async {
    if (isClosed) return;
    await _prefs.setActiveTrekSessionId(null);
    emit(const TrekError(
      message: 'Background location permission revoked or unavailable.',
      hasBackgroundPermission: false,
    ));
  }

  @override
  Future<void> close() async {
    await _sessionSub?.cancel();
    await _countSub?.cancel();
    return super.close();
  }
}
