import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInAnonymously {
  final AuthRepository _repo;
  const SignInAnonymously(this._repo);

  Future<Result<AppUser>> call() => _repo.signInAnonymously();
}
