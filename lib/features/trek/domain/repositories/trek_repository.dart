import '../../../../core/errors/result.dart';
import '../entities/breadcrumb.dart';

abstract class TrekRepository {
  /// Starts a new trek session. Returns the session id, or a Failure
  /// when background-location permission is missing or the position
  /// stream fails to start.
  Future<Result<String>> start();

  /// Stops the active session. Idempotent — safe to call when there is
  /// no active session.
  Future<Result<void>> stop();

  /// Emits the active session id (or null) on every change.
  Stream<String?> watchActiveSessionId();

  /// Emits the running breadcrumb count for the active session.
  /// Resets to 0 on stop.
  Stream<int> watchBreadcrumbCount();

  /// Reads the [limit] most recent breadcrumbs from sqflite. Used by
  /// the SOS dispatch path to attach the latest trail.
  Future<List<Breadcrumb>> latest({int limit = 50});

  /// Cancels the position subscription and dismisses the foreground-
  /// service notification, but leaves [AppPrefs.activeTrekSessionId]
  /// intact so a subsequent [resume] re-subscribes the same session.
  /// Used by the SOS active-tracking path (Iter 5b decision #47:
  /// mutually exclusive geolocator subscriptions). Idempotent.
  Future<void> suspend();

  /// Re-subscribes the position stream when [AppPrefs.activeTrekSessionId]
  /// is non-null AND no subscription is currently live. No-op otherwise.
  /// Idempotent.
  Future<void> resume();
}
