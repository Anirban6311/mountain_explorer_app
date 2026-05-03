import '../../../../core/errors/result.dart';
import '../repositories/offline_maps_repository.dart';

class DeleteRegion {
  final OfflineMapsRepository _repo;
  const DeleteRegion(this._repo);

  Future<Result<void>> call(String regionId) =>
      _repo.deleteRegion(regionId);
}
