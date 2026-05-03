import 'package:flutter_map/flutter_map.dart';

import '../../../../core/errors/result.dart';
import '../entities/download_estimate.dart';
import '../entities/download_progress.dart';
import '../entities/offline_region.dart';

abstract class OfflineMapsRepository {
  /// Emits the full region list on every mutation.
  Stream<List<OfflineRegion>> watchRegions();

  Future<Result<OfflineRegion?>> getRegion(String id);

  Future<Result<bool>> hasCompletedRegion(String id);

  Future<Result<DownloadEstimate>> estimate({
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  });

  Future<Result<int>> totalSizeBytes();

  /// Starts a download and emits progress. Caller cancels via
  /// [cancelDownload] with the matching [regionId].
  Stream<DownloadProgress> download({
    required String regionId,
    required String name,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  });

  Future<Result<void>> cancelDownload(String regionId);

  Future<Result<void>> deleteRegion(String regionId);

  /// Resume a partial / failed region. Re-runs the download with the
  /// stored bbox + zoom range and `skipExistingTiles: true` so cached
  /// tiles are not re-fetched.
  Stream<DownloadProgress> resume(String regionId);

  /// Drops every cached tile from the shared FMTC store and clears the
  /// regions table.
  Future<Result<void>> resetEntireCache();
}
