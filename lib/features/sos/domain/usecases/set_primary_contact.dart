import '../../../../core/errors/result.dart';
import '../repositories/emergency_contacts_repository.dart';

class SetPrimaryContact {
  final EmergencyContactsRepository _repo;
  const SetPrimaryContact(this._repo);

  Future<Result<void>> call({
    required String uid,
    required String contactId,
  }) =>
      _repo.setPrimary(uid: uid, contactId: contactId);
}
