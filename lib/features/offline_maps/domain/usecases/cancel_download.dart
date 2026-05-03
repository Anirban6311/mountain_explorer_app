import '../../../../core/errors/result.dart';
import '../repositories/offline_maps_repository.dart';

class CancelDownload {
  final OfflineMapsRepository _repo;
  const CancelDownload(this._repo);

  Future<Result<void>> call(String regionId) => _repo.cancelDownload(regionId);
}
