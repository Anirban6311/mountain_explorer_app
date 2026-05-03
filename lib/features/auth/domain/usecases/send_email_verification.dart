import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification {
  final AuthRepository _repo;
  const SendEmailVerification(this._repo);

  Future<Result<void>> call() => _repo.sendEmailVerification();
}
