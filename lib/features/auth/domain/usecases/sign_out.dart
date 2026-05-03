import '../../../../core/errors/result.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repo;
  const SignOut(this._repo);

  Future<Result<void>> call() => _repo.signOut();
}
