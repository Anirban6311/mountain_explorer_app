import 'package:flutter_map/flutter_map.dart';

import '../entities/download_progress.dart';
import '../repositories/offline_maps_repository.dart';

class StartDownload {
  final OfflineMapsRepository _repo;
  const StartDownload(this._repo);

  Stream<DownloadProgress> call({
    required String regionId,
    required String name,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  }) =>
      _repo.download(
        regionId: regionId,
        name: name,
        bbox: bbox,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );
}
