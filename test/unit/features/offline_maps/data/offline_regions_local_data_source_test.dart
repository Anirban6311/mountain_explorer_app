import 'package:basic_crud_flutter/core/storage/local_db.dart';
import 'package:basic_crud_flutter/features/offline_maps/data/datasources/offline_regions_local_data_source.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/offline_region.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

OfflineRegion _region({
  String id = 'r1',
  OfflineRegionStatus status = OfflineRegionStatus.complete,
  int sizeBytes = 1024,
  DateTime? downloadedAt,
}) =>
    OfflineRegion(
      id: id,
      name: 'Test',
      bbox: LatLngBounds(
        const LatLng(27.60, 88.05),
        const LatLng(27.78, 88.25),
      ),
      minZoom: 10,
      maxZoom: 14,
      tileCount: 100,
      sizeBytes: sizeBytes,
      downloadedAt: downloadedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: status,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocalDb localDb;
  late SqfliteOfflineRegionsLocalDataSource ds;

  setUp(() async {
    localDb = SqfliteLocalDb(path: inMemoryDatabasePath);
    await localDb.open();
    ds = SqfliteOfflineRegionsLocalDataSource(localDb);
  });

  tearDown(() => localDb.close());

  group('SqfliteOfflineRegionsLocalDataSource', () {
    test('insert + getById round-trip', () async {
      final r = _region();
      await ds.insert(r);
      final got = await ds.getById('r1');
      expect(got, isNotNull);
      expect(got!.id, 'r1');
      expect(got.sizeBytes, 1024);
      expect(got.status, OfflineRegionStatus.complete);
    });

    test('getById returns null when missing', () async {
      expect(await ds.getById('nope'), isNull);
    });

    test('update replaces status and size', () async {
      await ds.insert(_region(status: OfflineRegionStatus.downloading));
      await ds.update(_region(
        status: OfflineRegionStatus.complete,
        sizeBytes: 9999,
      ));
      final got = await ds.getById('r1');
      expect(got!.status, OfflineRegionStatus.complete);
      expect(got.sizeBytes, 9999);
    });

    test('delete removes the row', () async {
      await ds.insert(_region());
      await ds.delete('r1');
      expect(await ds.getById('r1'), isNull);
    });

    test('getAll returns all rows ordered by downloadedAt desc', () async {
      await ds.insert(_region(
        id: 'a',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(100),
      ));
      await ds.insert(_region(
        id: 'b',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(300),
      ));
      await ds.insert(_region(
        id: 'c',
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(200),
      ));
      final all = await ds.getAll();
      expect(all.map((r) => r.id).toList(), ['b', 'c', 'a']);
    });

    test('totalSizeBytes sums complete + downloading + partial; excludes failed',
        () async {
      await ds.insert(_region(
        id: 'a',
        status: OfflineRegionStatus.complete,
        sizeBytes: 1000,
      ));
      await ds.insert(_region(
        id: 'b',
        status: OfflineRegionStatus.partial,
        sizeBytes: 500,
      ));
      await ds.insert(_region(
        id: 'c',
        status: OfflineRegionStatus.complete,
        sizeBytes: 2000,
      ));
      await ds.insert(_region(
        id: 'd',
        status: OfflineRegionStatus.downloading,
        sizeBytes: 250,
      ));
      await ds.insert(_region(
        id: 'e',
        status: OfflineRegionStatus.failed,
        sizeBytes: 999,
      ));
      // 1000 (complete) + 500 (partial) + 2000 (complete) + 250 (downloading)
      // = 3750. The failed row's bytes are excluded.
      expect(await ds.totalSizeBytes(), 3750);
    });

    test('totalSizeBytes returns 0 when table is empty', () async {
      expect(await ds.totalSizeBytes(), 0);
    });

    test('deleteAll removes every row and emits empty list', () async {
      await ds.insert(_region(id: 'a'));
      await ds.insert(_region(id: 'b'));
      await ds.deleteAll();
      expect(await ds.getAll(), isEmpty);
    });

    test('watchRegions emits initial list and updates on insert', () async {
      await ds.insert(_region(id: 'a'));
      final stream = ds.watchRegions();
      final emitted = <List<OfflineRegion>>[];
      final sub = stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await ds.insert(_region(id: 'b'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(emitted.length, greaterThanOrEqualTo(2));
      expect(emitted.first.map((r) => r.id), ['a']);
      expect(emitted.last.map((r) => r.id).toSet(), {'a', 'b'});
    });
  });
}
