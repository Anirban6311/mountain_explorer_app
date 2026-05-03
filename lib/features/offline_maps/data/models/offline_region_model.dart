import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/offline_region.dart';

/// Translates between [OfflineRegion] and sqflite rows. Static helpers only;
/// this class is never instantiated.
class OfflineRegionModel {
  const OfflineRegionModel._();

  static Map<String, Object?> toRow(OfflineRegion r) {
    return {
      'id': r.id,
      'name': r.name,
      'bbox_wkt': _bboxToWkt(r.bbox),
      'min_zoom': r.minZoom,
      'max_zoom': r.maxZoom,
      'tile_count': r.tileCount,
      'size_bytes': r.sizeBytes,
      'downloaded_at': r.downloadedAt.millisecondsSinceEpoch,
      'status': r.status.name,
    };
  }

  static OfflineRegion fromRow(Map<String, Object?> row) {
    final bbox = _wktToBbox(row['bbox_wkt']! as String);
    return OfflineRegion(
      id: row['id']! as String,
      name: row['name']! as String,
      bbox: bbox,
      minZoom: row['min_zoom']! as int,
      maxZoom: row['max_zoom']! as int,
      tileCount: row['tile_count']! as int,
      sizeBytes: row['size_bytes']! as int,
      downloadedAt:
          DateTime.fromMillisecondsSinceEpoch(row['downloaded_at']! as int),
      status: _statusFromName(row['status']! as String),
    );
  }

  // --- WKT helpers -------------------------------------------------------

  /// Serializes [bbox] as a closed WKT polygon starting at the SW corner,
  /// going counter-clockwise (SW → SE → NE → NW → SW).
  static String _bboxToWkt(LatLngBounds bbox) {
    final sw = bbox.southWest;
    final ne = bbox.northEast;
    final swPair = '${sw.longitude} ${sw.latitude}';
    final sePair = '${ne.longitude} ${sw.latitude}';
    final nePair = '${ne.longitude} ${ne.latitude}';
    final nwPair = '${sw.longitude} ${ne.latitude}';
    return 'POLYGON(($swPair, $sePair, $nePair, $nwPair, $swPair))';
  }

  /// Parses the WKT format produced by [_bboxToWkt]. Only the SW and NE
  /// corners are used to reconstruct the bounds. Falls back to a
  /// neutral worldwide bbox when the input is malformed so that one bad
  /// row cannot DOS the regions stream.
  static LatLngBounds _wktToBbox(String wkt) {
    try {
      final body =
          wkt.replaceAll('POLYGON((', '').replaceAll('))', '').trim();
      final pairs = body
          .split(',')
          .map((s) => s.trim().split(RegExp(r'\s+')))
          .toList();
      if (pairs.length < 3) throw const FormatException('too few corners');
      final swParts = pairs[0];
      final neParts = pairs[2];
      if (swParts.length != 2 || neParts.length != 2) {
        throw const FormatException('coordinate pair shape');
      }
      final swLng = double.parse(swParts[0]);
      final swLat = double.parse(swParts[1]);
      final neLng = double.parse(neParts[0]);
      final neLat = double.parse(neParts[1]);
      return LatLngBounds(LatLng(swLat, swLng), LatLng(neLat, neLng));
    } catch (_) {
      return LatLngBounds(const LatLng(-1, -1), const LatLng(1, 1));
    }
  }

  static OfflineRegionStatus _statusFromName(String name) {
    for (final s in OfflineRegionStatus.values) {
      if (s.name == name) return s;
    }
    return OfflineRegionStatus.failed;
  }
}
