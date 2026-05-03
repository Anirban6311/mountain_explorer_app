import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Fixed id of the Kangchenjunga demo region seeded on first map-open.
const String kDemoRegionId = 'demo_kangchenjunga';
const String kDemoRegionName = 'Kangchenjunga';

/// Shared FMTC store name. FMTC v9 only supports one store per
/// [TileProvider], so all region downloads write to this store and the map
/// page browses from it. Per-region boundaries are tracked in sqflite
/// (`offline_regions`) for metadata only; eviction is currently cache-wide.
const String kBrowseStoreName = 'tile_cache';

/// Hard ceiling on tiles per user-initiated download. Prevents tile-bomb
/// abuse (e.g. a world-wide bbox at zoom 18 would estimate 60+ billion
/// tiles before FMTC even started the download).
const int kMaxTilesPerDownload = 50000;

/// Kangchenjunga area — ~20km square around the summit.
final LatLngBounds kDemoRegionBounds = LatLngBounds(
  const LatLng(27.60, 88.05), // south-west
  const LatLng(27.78, 88.25), // north-east
);

const int kDemoRegionMinZoom = 10;
const int kDemoRegionMaxZoom = 14;

/// Average bytes per MapTiler Outdoor tile. Used for pre-flight quota
/// estimation; the actual size replaces this at download completion.
const int kTileSizeBytesEstimate = 30 * 1024;

/// User-agent required by MapTiler / OSM-derived tile providers.
const String kTileUserAgent = 'com.mountainexplorer.app';
