import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repo;
  const SignInWithGoogle(this._repo);

  Future<Result<AppUser>> call() => _repo.signInWithGoogle();
}
