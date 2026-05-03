import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

/// Facade isolating the rest of the app from `flutter_map_tile_caching`'s
/// static/top-level API surface.
///
/// Iterations 2+ interact with offline tiles exclusively through this
/// interface so that tests can substitute an in-memory fake and FMTC
/// version bumps don't ripple into feature code.
abstract class OfflineTileStore {
  /// Initialises the backing tile store. Idempotent — calling more than
  /// once is safe. Must be called once at app startup.
  Future<void> initialise();

  /// Returns a [TileProvider] that serves cached tiles when available and
  /// falls back to the network when the device is online. FMTC v9 scopes
  /// tile providers to a single store — callers pass the shared browse
  /// store name ([kBrowseStoreName] from constants).
  TileProvider browseTileProvider({
    required String storeName,
    required String userAgentPackageName,
  });

  /// Estimates the number of tiles a rectangular download would produce.
  /// The estimation uses [storeName] for bookkeeping — pass the intended
  /// download target.
  Future<int> estimateTileCount({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
  });

  /// Starts a foreground tile download into [storeName]. The returned
  /// stream emits progress events and completes when the download finishes
  /// or is cancelled via [cancel].
  ///
  /// When [skipExistingTiles] is true, FMTC skips re-downloading tiles
  /// that are already cached — the path used by Iter 3's resume flow.
  Stream<TileDownloadEvent> download({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
    Map<String, String> additionalOptions = const {},
    int parallelThreads = 4,
    bool skipExistingTiles = false,
  });

  Future<void> cancel(String storeName);
  Future<int> sizeBytes(String storeName);
  Future<void> deleteStore(String storeName);

  /// Wipes the shared browse store entirely. Used by the catalog's
  /// "Reset entire cache" action.
  Future<void> resetAll(String storeName);
}

/// Progress snapshot emitted during a tile download.
class TileDownloadEvent extends Equatable {
  final int tilesDone;
  final int tilesTotal;
  final int bytesDone;
  final bool isComplete;

  /// Set only when the download terminated because of an error. `null` for
  /// normal completion and for cancellation.
  final String? errorMessage;

  const TileDownloadEvent({
    required this.tilesDone,
    required this.tilesTotal,
    required this.bytesDone,
    required this.isComplete,
    this.errorMessage,
  });

  @override
  List<Object?> get props =>
      [tilesDone, tilesTotal, bytesDone, isComplete, errorMessage];
}

class FmtcOfflineTileStore implements OfflineTileStore {
  bool _initialised = false;

  @override
  Future<void> initialise() async {
    if (_initialised) return;
    await FMTCObjectBoxBackend().initialise();
    _initialised = true;
  }

  @override
  TileProvider browseTileProvider({
    required String storeName,
    required String userAgentPackageName,
  }) {
    return FMTCStore(storeName).getTileProvider(
      headers: {'User-Agent': userAgentPackageName},
      settings: FMTCTileProviderSettings(
        behavior: CacheBehavior.cacheFirst,
        obscuredQueryParams: const ['apiKey', 'key'],
      ),
    );
  }

  @override
  Future<int> estimateTileCount({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
  }) async {
    final region = RectangleRegion(bbox).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: urlTemplate,
        userAgentPackageName: userAgentPackageName,
      ),
    );
    return FMTCStore(storeName).download.check(region);
  }

  @override
  Stream<TileDownloadEvent> download({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
    Map<String, String> additionalOptions = const {},
    int parallelThreads = 4,
    bool skipExistingTiles = false,
  }) async* {
    await FMTCStore(storeName).manage.create();
    final region = RectangleRegion(bbox).toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: urlTemplate,
        userAgentPackageName: userAgentPackageName,
        additionalOptions: additionalOptions,
      ),
    );
    try {
      await for (final p in FMTCStore(storeName).download.startForeground(
        region: region,
        parallelThreads: parallelThreads,
        skipExistingTiles: skipExistingTiles,
        obscuredQueryParams: const ['apiKey', 'key'],
      )) {
        yield TileDownloadEvent(
          tilesDone: p.cachedTiles,
          tilesTotal: p.maxTiles,
          bytesDone: (p.cachedSize * 1024).round(),
          isComplete: p.isComplete,
        );
      }
    } catch (e) {
      yield TileDownloadEvent(
        tilesDone: 0,
        tilesTotal: 0,
        bytesDone: 0,
        isComplete: true,
        errorMessage: _sanitize(e.toString()),
      );
    }
  }

  @override
  Future<void> cancel(String storeName) =>
      FMTCStore(storeName).download.cancel();

  @override
  Future<int> sizeBytes(String storeName) async {
    final kb = await FMTCStore(storeName).stats.size;
    return (kb * 1024).round();
  }

  @override
  Future<void> deleteStore(String storeName) =>
      FMTCStore(storeName).manage.delete();

  @override
  Future<void> resetAll(String storeName) async {
    await FMTCStore(storeName).manage.delete();
    // Recreate empty so subsequent browse calls don't error.
    await FMTCStore(storeName).manage.create();
  }

  /// Strips anything that looks like a URL query so an `apiKey=…` parameter
  /// captured in an exception message can't leak through to a user-facing
  /// snackbar or log line.
  static String _sanitize(String message) {
    return message.replaceAll(RegExp(r'\?[^\s]*'), '?<redacted>');
  }
}
