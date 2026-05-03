import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../../mountains/domain/entities/mountain.dart';
import '../../domain/constants.dart';
import '../../domain/entities/download_estimate.dart';
import '../../domain/entities/download_progress.dart';
import '../../domain/entities/offline_region.dart';
import '../../domain/usecases/cancel_download.dart';
import '../../domain/usecases/delete_region.dart';
import '../../domain/usecases/estimate_download.dart';
import '../../domain/usecases/has_completed_region.dart';
import '../../domain/usecases/reset_entire_cache.dart';
import '../../domain/usecases/resume_download.dart';
import '../../domain/usecases/start_download.dart';
import '../../domain/usecases/total_size_bytes.dart';
import '../../domain/usecases/watch_regions.dart';
import 'offline_maps_state.dart';

class OfflineMapsCubit extends Cubit<OfflineMapsState> {
  OfflineMapsCubit({
    required WatchRegions watchRegions,
    required EstimateDownload estimateDownload,
    required StartDownload startDownload,
    required CancelDownload cancelDownload,
    required HasCompletedRegion hasCompletedRegion,
    required TotalSizeBytes totalSizeBytes,
    required ResumeDownload resumeDownload,
    required DeleteRegion deleteRegion,
    required ResetEntireCache resetEntireCache,
    required ConnectivityService connectivity,
    required AppPrefs prefs,
  })  : _watch = watchRegions,
        _estimate = estimateDownload,
        _start = startDownload,
        _cancelUseCase = cancelDownload,
        _hasCompleted = hasCompletedRegion,
        _totalBytes = totalSizeBytes,
        _resume = resumeDownload,
        _deleteUseCase = deleteRegion,
        _resetCache = resetEntireCache,
        _connectivity = connectivity,
        _prefs = prefs,
        super(const MapInitial()) {
    _regionsSub = _watch().listen(_onRegions);
    _connSub = _connectivity.onConnectivityChanged().listen(_onConnectivity);
  }

  final WatchRegions _watch;
  final EstimateDownload _estimate;
  final StartDownload _start;
  final CancelDownload _cancelUseCase;
  final HasCompletedRegion _hasCompleted;
  final TotalSizeBytes _totalBytes;
  final ResumeDownload _resume;
  final DeleteRegion _deleteUseCase;
  final ResetEntireCache _resetCache;
  final ConnectivityService _connectivity;
  final AppPrefs _prefs;

  StreamSubscription<List<OfflineRegion>>? _regionsSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<DownloadProgress>? _downloadSub;
  String? _activeDownloadId;
  MapController? _mapController;
  LatLng? _pendingCenter;
  double? _pendingZoom;

  /// Lets the [OfflineMapsPage] hand its `MapController` to the cubit so
  /// `startDownloadOfMountain` can re-center the map. Called once from
  /// `_OfflineMapsPageState.initState`. Any move queued via
  /// [startDownloadOfMountain] / [centerOnMountain] before this call
  /// is applied here (plan §7 EC-11).
  void attachMapController(MapController controller) {
    _mapController = controller;
    final center = _pendingCenter;
    if (center != null) {
      controller.move(center, _pendingZoom ?? 12);
      _pendingCenter = null;
      _pendingZoom = null;
    }
  }

  void _moveOrQueue(LatLng center, double zoom) {
    final controller = _mapController;
    if (controller != null) {
      controller.move(center, zoom);
    } else {
      _pendingCenter = center;
      _pendingZoom = zoom;
    }
  }

  Future<void> onMapVisible() async {
    if (isClosed) return;
    if (_prefs.hasSeenDemoPrompt()) {
      _emitReady();
      return;
    }
    final demoDone = await _hasCompleted(kDemoRegionId);
    if (demoDone is Success<bool> && demoDone.value) {
      _emitReady();
      return;
    }
    final online = await _connectivity.isOnline();
    if (!online) {
      _emitReady();
      return;
    }
    _emitWith((s) => MapShowDemoPrompt(
          isOnline: s.isOnline,
          regions: s.regions,
        ));
  }

  Future<void> acceptDemoRegion() async {
    // Persist the "seen" flag before we start the download so a crash
    // mid-download does not re-prompt the user.
    await _prefs.markDemoPromptSeen();
    _startDownloadInternal(
      regionId: kDemoRegionId,
      name: kDemoRegionName,
      bbox: kDemoRegionBounds,
      minZoom: kDemoRegionMinZoom,
      maxZoom: kDemoRegionMaxZoom,
    );
  }

  Future<void> skipDemoRegion() async {
    await _prefs.markDemoPromptSeen();
    _emitReady();
  }

  Future<void> startDownloadOfViewport(
    LatLngBounds bbox,
    int currentZoom,
  ) async {
    if (isClosed) return;
    if (_activeDownloadId != null) return;

    final int minZoom = math.max(0, currentZoom - 1);
    final int maxZoom = math.min(18, currentZoom + 2);

    final estResult =
        await _estimate(bbox: bbox, minZoom: minZoom, maxZoom: maxZoom);
    if (estResult is Failure<DownloadEstimate>) {
      _emitWith((s) => MapError(
            message: estResult.error.message,
            isOnline: s.isOnline,
            regions: s.regions,
          ));
      return;
    }
    final estimate = (estResult as Success<DownloadEstimate>).value;

    final totalResult = await _totalBytes();
    final int existing = switch (totalResult) {
      Success<int>(:final value) => value,
      Failure<int>() => 0,
    };
    final quotaBytes = _prefs.getQuotaMb() * 1024 * 1024;
    if (existing + estimate.estimatedBytes > quotaBytes) {
      _emitWith((s) => MapQuotaExceeded(
            neededBytes: existing + estimate.estimatedBytes,
            quotaBytes: quotaBytes,
            isOnline: s.isOnline,
            regions: s.regions,
          ));
      return;
    }

    final id = const Uuid().v4();
    final name = 'Saved region · ${_niceTimestamp(DateTime.now())}';
    _startDownloadInternal(
      regionId: id,
      name: name,
      bbox: bbox,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  Future<void> cancelActiveDownload() async {
    final id = _activeDownloadId;
    if (id == null) return;
    // Let the repository mark the row `partial` before the stream
    // terminates. Do NOT cancel the subscription locally first — the
    // repository's `download` coroutine needs to run its final update.
    await _cancelUseCase(id);
  }

  /// Resume a `partial` or `failed` region. Re-uses the same progress
  /// dialog flow as a fresh download.
  Future<void> resumeDownload(String regionId) async {
    if (isClosed) return;
    // Gate on the synchronously-set _activeDownloadId, not on the state,
    // because the state takes a tick to transition to MapDownloading
    // after a download starts (plan review H3).
    if (_activeDownloadId != null) return;
    _activeDownloadId = regionId;
    _downloadSub?.cancel();
    _downloadSub = _resume(regionId).listen(
      _onDownloadProgress,
      onError: (Object e) {
        if (isClosed) return;
        _activeDownloadId = null;
        _emitWith((s) => MapError(
              message: e.toString(),
              isOnline: s.isOnline,
              regions: s.regions,
            ));
      },
      onDone: () {
        if (isClosed) return;
        if (state is MapDownloading) _emitReady();
        _activeDownloadId = null;
      },
    );
  }

  Future<void> deleteRegion(String regionId) async {
    if (isClosed) return;
    final result = await _deleteUseCase(regionId);
    if (isClosed) return;
    if (result is Failure<void>) {
      _emitWith((s) => MapError(
            message: result.error.message,
            isOnline: s.isOnline,
            regions: s.regions,
          ));
    }
  }

  Future<void> resetEntireCache() async {
    if (isClosed) return;
    // Use _activeDownloadId (set synchronously) rather than state, so
    // a reset issued during the download warm-up window still cancels
    // (plan review H2).
    if (_activeDownloadId != null) {
      await cancelActiveDownload();
      // Drain the cancelled stream before nuking FMTC + DB.
      try {
        await _downloadSub?.asFuture<void>();
      } catch (_) {
        // Cancellation propagates as an error in some Stream impls.
      }
    }
    final result = await _resetCache();
    if (isClosed) return;
    if (result is Failure<void>) {
      _emitWith((s) => MapError(
            message: result.error.message,
            isOnline: s.isOnline,
            regions: s.regions,
          ));
    }
  }

  /// Switches the map to be centered on [m] and (when an `OfflineMapsPage`
  /// has registered its `MapController` via [attachMapController]) starts
  /// a `±0.05°` download around the mountain's coordinates.
  Future<void> startDownloadOfMountain(Mountain m) async {
    if (isClosed) return;
    if (!m.hasCoordinates) {
      _emitWith((s) => MapError(
            message: '${m.name} has no coordinates yet.',
            isOnline: s.isOnline,
            regions: s.regions,
          ));
      return;
    }
    if (_activeDownloadId != null) {
      _emitWith((s) => MapError(
            message: 'A download is already in progress.',
            isOnline: s.isOnline,
            regions: s.regions,
          ));
      return;
    }
    final center = LatLng(m.lat!, m.lng!);
    _moveOrQueue(center, 12);
    final bbox = LatLngBounds(
      LatLng(m.lat! - 0.05, m.lng! - 0.05),
      LatLng(m.lat! + 0.05, m.lng! + 0.05),
    );
    await startDownloadOfViewport(bbox, 12);
  }

  /// Re-centers the map on a mountain without starting a download. If the
  /// `MapController` hasn't been attached yet (long-press fired before the
  /// Map tab built), the move is queued and applied on attach.
  void centerOnMountain(Mountain m) {
    if (!m.hasCoordinates) return;
    _moveOrQueue(LatLng(m.lat!, m.lng!), 12);
  }

  void _startDownloadInternal({
    required String regionId,
    required String name,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
  }) {
    _activeDownloadId = regionId;
    _downloadSub?.cancel();
    _downloadSub = _start(
      regionId: regionId,
      name: name,
      bbox: bbox,
      minZoom: minZoom,
      maxZoom: maxZoom,
    ).listen(
      _onDownloadProgress,
      onError: (Object e) {
        if (isClosed) return;
        _activeDownloadId = null;
        _emitWith((s) => MapError(
              message: e.toString(),
              isOnline: s.isOnline,
              regions: s.regions,
            ));
      },
      onDone: () {
        if (isClosed) return;
        if (state is MapDownloading) _emitReady();
        _activeDownloadId = null;
      },
    );
  }

  void _onDownloadProgress(DownloadProgress progress) {
    if (isClosed) return;
    if (progress.hasError) {
      _emitWith((s) => MapError(
            message: progress.errorMessage ?? 'Download failed.',
            isOnline: s.isOnline,
            regions: s.regions,
          ));
      _activeDownloadId = null;
      return;
    }
    if (progress.isComplete) {
      _activeDownloadId = null;
      _emitReady();
    } else {
      _emitWith((s) => MapDownloading(
            progress: progress,
            isOnline: s.isOnline,
            regions: s.regions,
          ));
    }
  }

  void _onRegions(List<OfflineRegion> regions) {
    if (isClosed) return;
    _emitWith((s) => _rebuild(s, regions: regions));
  }

  void _onConnectivity(bool isOnline) {
    if (isClosed) return;
    // ignore: avoid_print
    print('[connectivity] stream emitted isOnline=$isOnline');
    _emitWith((s) => _rebuild(s, isOnline: isOnline));
  }

  void _emitReady() {
    _emitWith((s) => MapReady(isOnline: s.isOnline, regions: s.regions));
  }

  void _emitWith(OfflineMapsState Function(OfflineMapsState) build) {
    emit(build(state));
  }

  OfflineMapsState _rebuild(
    OfflineMapsState s, {
    bool? isOnline,
    List<OfflineRegion>? regions,
  }) {
    final online = isOnline ?? s.isOnline;
    final list = regions ?? s.regions;
    return switch (s) {
      MapInitial() => MapReady(isOnline: online, regions: list),
      MapReady() => MapReady(isOnline: online, regions: list),
      MapShowDemoPrompt() =>
        MapShowDemoPrompt(isOnline: online, regions: list),
      MapDownloading(:final progress) =>
        MapDownloading(progress: progress, isOnline: online, regions: list),
      MapQuotaExceeded(:final neededBytes, :final quotaBytes) =>
        MapQuotaExceeded(
          neededBytes: neededBytes,
          quotaBytes: quotaBytes,
          isOnline: online,
          regions: list,
        ),
      MapError(:final message) =>
        MapError(message: message, isOnline: online, regions: list),
    };
  }

  static String _niceTimestamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Future<void> close() async {
    await _regionsSub?.cancel();
    await _connSub?.cancel();
    await _downloadSub?.cancel();
    return super.close();
  }
}
