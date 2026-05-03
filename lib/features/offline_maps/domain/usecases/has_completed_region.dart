import '../../../../core/errors/result.dart';
import '../repositories/offline_maps_repository.dart';

class HasCompletedRegion {
  final OfflineMapsRepository _repo;
  const HasCompletedRegion(this._repo);

  Future<Result<bool>> call(String id) => _repo.hasCompletedRegion(id);
}
