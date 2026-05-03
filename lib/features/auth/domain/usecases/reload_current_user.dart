import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class ReloadCurrentUser {
  final AuthRepository _repo;
  const ReloadCurrentUser(this._repo);

  Future<Result<AppUser?>> call() => _repo.reloadCurrentUser();
}
