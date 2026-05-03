import '../../../../core/errors/result.dart';
import '../entities/emergency_contact.dart';
import '../entities/sos_dispatch_result.dart';

abstract class SosRepository {
  /// Single-shot SOS dispatch. Captures GPS + battery, snapshots the
  /// contact list, opens an SMS deep-link per contact, and writes the
  /// alert doc to Firestore. On Firestore failure, the payload is
  /// queued in the local outbox and the result carries `queued: true`.
  Future<Result<SosDispatchResult>> fire({
    required String uid,
    required String userName,
    required String userEmail,
    required List<EmergencyContact> contacts,
  });

  Future<Result<void>> cancel(String alertId);

  /// Iter 5b EC-3: client-side 6 h timeout enforcement. Queries the
  /// caller's own `sos_alerts` for `status == 'active'` docs older
  /// than [ttl] and updates them to `status: 'timed_out'`. Returns
  /// the count of updated alerts.
  Future<Result<int>> flushExpired(
    String uid, {
    Duration ttl = const Duration(hours: 6),
  });
}
