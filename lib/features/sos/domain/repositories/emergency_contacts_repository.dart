import '../../../../core/errors/result.dart';
import '../entities/emergency_contact.dart';

abstract class EmergencyContactsRepository {
  Stream<List<EmergencyContact>> watch(String uid);

  /// Add a new contact. Auto-marks `isPrimary: true` when the user has no
  /// contacts yet so the SOS button is enabled immediately.
  Future<Result<EmergencyContact>> add({
    required String uid,
    required EmergencyContact draft,
  });

  Future<Result<void>> update({
    required String uid,
    required EmergencyContact contact,
  });

  Future<Result<void>> delete({
    required String uid,
    required String contactId,
  });

  /// Atomic flip of the primary flag. Looks up the current primary first,
  /// then issues a single Firestore [WriteBatch] toggling both rows.
  Future<Result<void>> setPrimary({
    required String uid,
    required String contactId,
  });
}
