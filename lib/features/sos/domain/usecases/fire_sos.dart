import '../../../../core/errors/result.dart';
import '../entities/emergency_contact.dart';
import '../entities/sos_dispatch_result.dart';
import '../repositories/sos_repository.dart';

class FireSos {
  final SosRepository _repo;
  const FireSos(this._repo);

  Future<Result<SosDispatchResult>> call({
    required String uid,
    required String userName,
    required String userEmail,
    required List<EmergencyContact> contacts,
  }) =>
      _repo.fire(
        uid: uid,
        userName: userName,
        userEmail: userEmail,
        contacts: contacts,
      );
}
