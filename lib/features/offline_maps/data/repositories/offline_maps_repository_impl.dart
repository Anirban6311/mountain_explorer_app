import 'dart:async';

import 'package:flutter_map/flutter_map.dart';

import '../../../../core/env/env.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/offline_tile_store.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../domain/constants.dart';
import '../../domain/entities/download_estimate.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/offline_region.dart';
import '../../domain/repositories/offline_maps_repository.dart';
import '../datasources/offline_regions_local_data_source.dart';

class OfflineMapsRepositoryImpl implements OfflineMapsRepository {
  OfflineMapsRepositoryImpl({
    required OfflineRegionsLocalDataSource ds,
    required OfflineTileStore tileStore,
    required AppPrefs prefs,
    required Env env,
  })  : _ds = ds,
        _tileStore = tileStore,
        _prefs = prefs,
        _env = env;

  final OfflineRegionsLocalDataSource _ds;
  final OfflineTileStore _tileStore;
  final AppPrefs _prefs;
  final Env _env;

  @override
  Stream<List<OfflineRegion>> watchRegions() => _ds.watchRegions();

  @override
  Future<Result<OfflineRegion?>> getRegion(String id) async {
    try {
      return Success<OfflineRegion?>(await _ds.getById(id));
    } catch (e) {
      return Failure<OfflineRegion?>(
        UnknownError('Failed to read region.', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> hasCompletedRegion(String id) async {
    try {
      final row = await _ds.getById(id);
      return Success<bool>(
        row != null && row.status == OfflineRegionStatus.complete,
      );
    } catch (e) {
      return Failure<bool>(UnknownError('Failed to read region.', cause: e));
    }
  }

  @override
  Future<Result<DownloadEstimate>> estimate({
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  }) async {
    try {
      final tileCount = await _tileStore.estimateTileCount(
        storeName: kBrowseStoreName,
        bbox: bbox,
        minZoom: minZoom,
        maxZoom: maxZoom,
        urlTemplate: _env.osmTileUrlTemplate,
        userAgentPackageName: kTileUserAgent,
      );
      return Success<DownloadEstimate>(
        DownloadEstimate(
          tileCount: tileCount,
          estimatedBytes: tileCount * kTileSizeBytesEstimate,
        ),
      );
    } catch (e) {
      return Failure<DownloadEstimate>(
        UnknownError('Failed to estimate download.', cause: e),
      );
    }
  }

  @override
  Future<Result<int>> totalSizeBytes() async {
    try {
      return Success<int>(await _ds.totalSizeBytes());
    } catch (e) {
      return Failure<int>(
        UnknownError('Failed to read quota usage.', cause: e),
      );
    }
  }

  @override
  Stream<DownloadProgress> download({
    required String regionId,
    required String name,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  }) =>
      _downloadInternal(
        regionId: regionId,
        name: name,
        bbox: bbox,
        minZoom: minZoom,
        maxZoom: maxZoom,
        skipExistingTiles: false,
      );

  @override
  Stream<DownloadProgress> resume(String regionId) async* {
    final existing = await _ds.getById(regionId);
    if (existing == null) {
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: 0,
        bytesDone: 0,
        isComplete: true,
        errorMessage: 'Region not found.',
      );
      return;
    }
    if (existing.status == OfflineRegionStatus.complete) {
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: existing.tileCount,
        tilesTotal: existing.tileCount,
        bytesDone: existing.sizeBytes,
        isComplete: true,
      );
      return;
    }
    yield* _downloadInternal(
      regionId: regionId,
      name: existing.name,
      bbox: existing.bbox,
      minZoom: existing.minZoom,
      maxZoom: existing.maxZoom,
      skipExistingTiles: true,
    );
  }

  @override
  Future<Result<void>> resetEntireCache() async {
    try {
      await _tileStore.resetAll(kBrowseStoreName);
      await _ds.deleteAll();
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to reset cache.', cause: e),
      );
    }
  }

  Stream<DownloadProgress> _downloadInternal({
    required String regionId,
    required String name,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required bool skipExistingTiles,
  }) async* {
    // Pre-flight: estimate + quota check.
    final int tileCount;
    try {
      tileCount = await _tileStore.estimateTileCount(
        storeName: kBrowseStoreName,
        bbox: bbox,
        minZoom: minZoom,
        maxZoom: maxZoom,
        urlTemplate: _env.osmTileUrlTemplate,
        userAgentPackageName: kTileUserAgent,
      );
    } catch (e) {
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: 0,
        bytesDone: 0,
        isComplete: true,
        errorMessage:
            'Failed to estimate download: ${_sanitize(e.toString())}',
      );
      return;
    }

    // Hard ceiling before we touch anything else: prevents tile-bomb abuse.
    if (tileCount > kMaxTilesPerDownload) {
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: tileCount,
        bytesDone: 0,
        isComplete: true,
        errorMessage:
            'Region is too large ($tileCount tiles). Zoom in or pick a '
            'smaller area; max is $kMaxTilesPerDownload tiles.',
      );
      return;
    }

    final estimatedBytes = tileCount * kTileSizeBytesEstimate;
    // Include in-flight + partial rows so concurrent starts don't bypass
    // the quota via the downloading-row blind spot.
    final existing = await _ds.totalSizeBytes();
    final quotaBytes = _prefs.getQuotaMb() * 1024 * 1024;
    if (existing + estimatedBytes > quotaBytes) {
      final neededMb =
          ((existing + estimatedBytes) / 1024 / 1024).ceil();
      final quotaMb = _prefs.getQuotaMb();
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: tileCount,
        bytesDone: 0,
        isComplete: true,
        errorMessage:
            'Over quota: needs $neededMb MB, only $quotaMb MB allowed.',
      );
      return;
    }

    // Dedupe: if a non-complete row already exists for this id (e.g. the
    // Kangchenjunga demo region was left in `failed` or `partial` from a
    // prior run), remove it so the placeholder insert doesn't fail with a
    // primary-key violation.
    final existingRow = await _ds.getById(regionId);
    if (existingRow != null &&
        existingRow.status != OfflineRegionStatus.complete) {
      await _ds.delete(regionId);
    } else if (existingRow != null) {
      // Already complete — nothing to do. Short-circuit with a synthetic
      // completion event so callers can close their progress UI.
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: existingRow.tileCount,
        tilesTotal: existingRow.tileCount,
        bytesDone: existingRow.sizeBytes,
        isComplete: true,
      );
      return;
    }

    // Insert placeholder row.
    final now = DateTime.now();
    final initial = OfflineRegion(
      id: regionId,
      name: name,
      bbox: bbox,
      minZoom: minZoom,
      maxZoom: maxZoom,
      tileCount: tileCount,
      sizeBytes: estimatedBytes,
      downloadedAt: now,
      status: OfflineRegionStatus.downloading,
    );
    try {
      await _ds.insert(initial);
    } catch (e) {
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: tileCount,
        bytesDone: 0,
        isComplete: true,
        errorMessage: 'Failed to persist region row: $e',
      );
      return;
    }

    // Forward progress events — tiles land in the shared browse store so
    // the map can serve them offline regardless of which region they
    // belong to.
    TileDownloadEvent? last;
    try {
      await for (final e in _tileStore.download(
        storeName: kBrowseStoreName,
        bbox: bbox,
        minZoom: minZoom,
        maxZoom: maxZoom,
        urlTemplate: _env.osmTileUrlTemplate,
        userAgentPackageName: kTileUserAgent,
        additionalOptions: {'apiKey': _env.maptilerApiKey},
        skipExistingTiles: skipExistingTiles,
      )) {
        last = e;
        yield DownloadProgress(
          regionId: regionId,
          tilesDone: e.tilesDone,
          tilesTotal: e.tilesTotal == 0 ? tileCount : e.tilesTotal,
          bytesDone: e.bytesDone,
          isComplete: e.isComplete && e.errorMessage == null,
          errorMessage: e.errorMessage,
        );
      }
    } catch (e) {
      final msg = _sanitize(e.toString());
      last = TileDownloadEvent(
        tilesDone: 0,
        tilesTotal: tileCount,
        bytesDone: 0,
        isComplete: true,
        errorMessage: msg,
      );
      yield DownloadProgress(
        regionId: regionId,
        tilesDone: 0,
        tilesTotal: tileCount,
        bytesDone: 0,
        isComplete: true,
        errorMessage: msg,
      );
    }

    // Persist the final outcome. If the stream terminated without a
    // clean completion marker, assume cancellation → `partial`.
    final actualBytes = last?.bytesDone ?? 0;
    final OfflineRegionStatus finalStatus;
    if (last?.errorMessage != null) {
      finalStatus = OfflineRegionStatus.failed;
    } else if (last == null || !last.isComplete) {
      finalStatus = OfflineRegionStatus.partial;
    } else {
      finalStatus = OfflineRegionStatus.complete;
    }
    try {
      await _ds.update(initial.copyWith(
        status: finalStatus,
        sizeBytes: actualBytes > 0 ? actualBytes : estimatedBytes,
        tileCount: last?.tilesDone ?? tileCount,
      ));
    } catch (_) {
      // Swallow: progress already emitted to the caller.
    }
  }

  @override
  Future<Result<void>> cancelDownload(String regionId) async {
    try {
      await _tileStore.cancel(regionId);
      final existing = await _ds.getById(regionId);
      if (existing != null) {
        final size = await _safeSize(regionId);
        await _ds.update(existing.copyWith(
          status: OfflineRegionStatus.partial,
          sizeBytes: size > 0 ? size : existing.sizeBytes,
        ));
      }
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to cancel download.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> deleteRegion(String regionId) async {
    // Iter 3 decision #24: row-only delete. The shared FMTC `tile_cache`
    // store holds tiles for every region; per-region tile eviction isn't
    // possible in FMTC v9. Use `resetEntireCache()` to free tile bytes.
    try {
      await _ds.delete(regionId);
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(
        UnknownError('Failed to delete region.', cause: e),
      );
    }
  }

  Future<int> _safeSize(String regionId) async {
    try {
      return await _tileStore.sizeBytes(regionId);
    } catch (_) {
      return 0;
    }
  }

  /// Redacts query strings from diagnostic messages so a MapTiler
  /// `apiKey=…` embedded in a thrown URL never reaches a snackbar or log.
  static String _sanitize(String message) {
    return message.replaceAll(RegExp(r'\?[^\s]*'), '?<redacted>');
  }
}
