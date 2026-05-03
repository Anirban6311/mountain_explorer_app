import '../../../../core/errors/result.dart';
import '../entities/sos_alert.dart';

abstract class SosOutboxRepository {
  /// Adds an alert payload to the local outbox so it can be replayed
  /// when connectivity returns.
  Future<Result<int>> enqueueAlert(SosAlert alert);

  /// Processes due rows: tries to write each to Firestore. On success,
  /// deletes the row. On failure, applies exponential backoff to the
  /// `next_attempt_at` field, capped at 1h.
  Future<void> processDue();

  /// Removes a queued alert before the retry processor sends it. Used
  /// by `SosCubit.cancelDispatched` to honour an offline cancellation.
  Future<void> deleteQueued(int id);
}
