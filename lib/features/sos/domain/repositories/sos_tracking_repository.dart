import '../../../../core/errors/result.dart';

abstract class SosTrackingRepository {
  /// Opens a 30 s (120 s when battery < 20 %) position subscription
  /// and appends each fix to `sos_alerts/{alertId}/breadcrumbs/{tsMs}`.
  /// Calls `TrekRepository.suspend()` before opening so trek + SOS
  /// remain mutually exclusive on the radio. Idempotent — second start
  /// with the same alertId is a no-op.
  Future<Result<void>> start(String alertId);

  /// Cancels the active subscription and calls `TrekRepository.resume()`.
  /// Idempotent.
  Future<Result<void>> stop();

  /// Emits the alertId currently being tracked, or null when idle.
  Stream<String?> watchActiveAlertId();
}
