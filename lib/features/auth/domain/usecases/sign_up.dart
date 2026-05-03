import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository _repo;
  const SignUp(this._repo);

  Future<Result<AppUser>> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
}
