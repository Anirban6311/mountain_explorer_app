import '../entities/emergency_contact.dart';
import '../repositories/emergency_contacts_repository.dart';

class WatchContacts {
  final EmergencyContactsRepository _repo;
  const WatchContacts(this._repo);

  Stream<List<EmergencyContact>> call(String uid) => _repo.watch(uid);
}
