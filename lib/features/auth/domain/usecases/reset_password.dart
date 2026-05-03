import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class ResetPassword {
  final AuthRepository _repo;
  const ResetPassword(this._repo);

  Future<Result<void>> call(String email) => _repo.resetPassword(email);
}
