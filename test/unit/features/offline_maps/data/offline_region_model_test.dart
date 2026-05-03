import 'package:basic_crud_flutter/features/offline_maps/data/models/offline_region_model.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/offline_region.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('OfflineRegionModel', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final bounds = LatLngBounds(
      const LatLng(27.60, 88.05),
      const LatLng(27.78, 88.25),
    );
    final region = OfflineRegion(
      id: 'r1',
      name: 'Kangchenjunga',
      bbox: bounds,
      minZoom: 10,
      maxZoom: 14,
      tileCount: 512,
      sizeBytes: 15728640,
      downloadedAt: ts,
      status: OfflineRegionStatus.complete,
    );

    test('toRow -> fromRow is lossless', () {
      final row = OfflineRegionModel.toRow(region);
      final back = OfflineRegionModel.fromRow(row);
      expect(back.id, region.id);
      expect(back.name, region.name);
      expect(back.bbox.southWest.latitude, closeTo(27.60, 1e-9));
      expect(back.bbox.southWest.longitude, closeTo(88.05, 1e-9));
      expect(back.bbox.northEast.latitude, closeTo(27.78, 1e-9));
      expect(back.bbox.northEast.longitude, closeTo(88.25, 1e-9));
      expect(back.minZoom, 10);
      expect(back.maxZoom, 14);
      expect(back.tileCount, 512);
      expect(back.sizeBytes, 15728640);
      expect(back.downloadedAt, ts);
      expect(back.status, OfflineRegionStatus.complete);
    });

    test('status round-trips through text column', () {
      for (final s in OfflineRegionStatus.values) {
        final row = OfflineRegionModel.toRow(region.copyWith(status: s));
        final back = OfflineRegionModel.fromRow(row);
        expect(back.status, s);
      }
    });

    test('bboxWkt is a closed polygon with 5 vertices', () {
      final row = OfflineRegionModel.toRow(region);
      final wkt = row['bbox_wkt'] as String;
      expect(wkt, startsWith('POLYGON(('));
      expect(wkt, endsWith('))'));
      // 5 coordinate pairs (4 corners + closing repeat)
      final pairs = wkt
          .replaceAll('POLYGON((', '')
          .replaceAll('))', '')
          .split(',');
      expect(pairs.length, 5);
    });

    test('fromRow defaults unknown status to failed', () {
      final row = <String, Object?>{
        'id': 'r1',
        'name': 'Test',
        'bbox_wkt':
            'POLYGON((88.05 27.60, 88.25 27.60, 88.25 27.78, 88.05 27.78, 88.05 27.60))',
        'min_zoom': 10,
        'max_zoom': 14,
        'tile_count': 0,
        'size_bytes': 0,
        'downloaded_at': ts.millisecondsSinceEpoch,
        'status': 'wat',
      };
      final back = OfflineRegionModel.fromRow(row);
      expect(back.status, OfflineRegionStatus.failed);
    });
  });
}
