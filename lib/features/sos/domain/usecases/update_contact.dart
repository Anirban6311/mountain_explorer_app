import '../../../../core/errors/result.dart';
import '../entities/emergency_contact.dart';
import '../repositories/emergency_contacts_repository.dart';

class UpdateContact {
  final EmergencyContactsRepository _repo;
  const UpdateContact(this._repo);

  Future<Result<void>> call({
    required String uid,
    required EmergencyContact contact,
  }) =>
      _repo.update(uid: uid, contact: contact);
}
