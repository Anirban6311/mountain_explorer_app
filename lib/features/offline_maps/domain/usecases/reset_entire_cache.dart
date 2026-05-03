import '../../../../core/errors/result.dart';
import '../repositories/offline_maps_repository.dart';

class ResetEntireCache {
  final OfflineMapsRepository _repo;
  const ResetEntireCache(this._repo);

  Future<Result<void>> call() => _repo.resetEntireCache();
}
