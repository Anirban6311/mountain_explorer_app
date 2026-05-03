import '../../../../core/errors/result.dart';
import '../repositories/emergency_contacts_repository.dart';

class DeleteContact {
  final EmergencyContactsRepository _repo;
  const DeleteContact(this._repo);

  Future<Result<void>> call({
    required String uid,
    required String contactId,
  }) =>
      _repo.delete(uid: uid, contactId: contactId);
}
