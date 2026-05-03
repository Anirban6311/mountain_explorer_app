import 'package:flutter_map/flutter_map.dart';

import '../../../../core/errors/result.dart';
import '../entities/download_estimate.dart';
import '../repositories/offline_maps_repository.dart';

class EstimateDownload {
  final OfflineMapsRepository _repo;
  const EstimateDownload(this._repo);

  Future<Result<DownloadEstimate>> call({
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  }) =>
      _repo.estimate(bbox: bbox, minZoom: minZoom, maxZoom: maxZoom);
}
