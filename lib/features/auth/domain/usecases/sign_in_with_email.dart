import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repo;
  const SignInWithEmail(this._repo);

  Future<Result<AppUser>> call({
    required String email,
    required String password,
  }) =>
      _repo.signInWithEmail(email: email, password: password);
}
