import '../../../../core/errors/result.dart';
import '../repositories/offline_maps_repository.dart';

class TotalSizeBytes {
  final OfflineMapsRepository _repo;
  const TotalSizeBytes(this._repo);

  Future<Result<int>> call() => _repo.totalSizeBytes();
}
