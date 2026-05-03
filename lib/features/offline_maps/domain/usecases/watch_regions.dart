import '../entities/offline_region.dart';
import '../repositories/offline_maps_repository.dart';

class WatchRegions {
  final OfflineMapsRepository _repo;
  const WatchRegions(this._repo);

  Stream<List<OfflineRegion>> call() => _repo.watchRegions();
}
