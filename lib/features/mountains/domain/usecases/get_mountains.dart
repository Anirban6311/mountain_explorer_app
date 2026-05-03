import '../../../../core/errors/result.dart';
import '../entities/mountain.dart';
import '../repositories/mountains_repository.dart';

class GetMountains {
  final MountainsRepository _repo;
  const GetMountains(this._repo);

  Future<Result<List<Mountain>>> call() => _repo.getMountains();
}
