import '../../../../core/errors/result.dart';
import '../entities/emergency_contact.dart';
import '../repositories/emergency_contacts_repository.dart';

class AddContact {
  final EmergencyContactsRepository _repo;
  const AddContact(this._repo);

  Future<Result<EmergencyContact>> call({
    required String uid,
    required EmergencyContact draft,
  }) =>
      _repo.add(uid: uid, draft: draft);
}
