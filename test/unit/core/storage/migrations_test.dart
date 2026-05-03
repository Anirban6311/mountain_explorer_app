import 'package:basic_crud_flutter/core/storage/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> _openInMemory() async {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async =>
          db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        for (final m in allMigrations) {
          await m.up(db);
        }
      },
    ),
  );
}

Future<List<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
  );
  return rows.map((r) => r['name'] as String).toList()..sort();
}

Future<List<String>> _indexNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
  );
  return rows.map((r) => r['name'] as String).toList()..sort();
}

Future<List<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((r) => r['name'] as String).toList();
}

void main() {
  sqfliteFfiInit();

  group('migrations — schema v1', () {
    late Database db;
    setUp(() async => db = await _openInMemory());
    tearDown(() async => db.close());

    test('creates all four tables', () async {
      final tables = await _tableNames(db);
      expect(
        tables,
        containsAll([
          'offline_regions',
          'trek_breadcrumbs',
          'sos_outbox',
          'offline_routes',
        ]),
      );
    });

    test('creates expected indexes', () async {
      final indexes = await _indexNames(db);
      expect(
        indexes,
        containsAll([
          'idx_trek_breadcrumbs_ts_desc',
          'idx_sos_outbox_next',
          'idx_offline_routes_region',
        ]),
      );
    });

    test('offline_regions has expected columns', () async {
      expect(await _columnNames(db, 'offline_regions'), [
        'id',
        'name',
        'bbox_wkt',
        'min_zoom',
        'max_zoom',
        'tile_count',
        'size_bytes',
        'downloaded_at',
        'status',
      ]);
    });

    test('trek_breadcrumbs has expected columns', () async {
      expect(await _columnNames(db, 'trek_breadcrumbs'), [
        'id',
        'ts',
        'lat',
        'lng',
        'accuracy',
        'altitude',
        'battery',
      ]);
    });

    test('sos_outbox has expected columns', () async {
      expect(await _columnNames(db, 'sos_outbox'), [
        'id',
        'payload_json',
        'kind',
        'attempts',
        'next_attempt_at',
        'created_at',
      ]);
    });

    test('offline_routes has expected columns', () async {
      expect(await _columnNames(db, 'offline_routes'), [
        'id',
        'region_id',
        'name',
        'geojson',
      ]);
    });

    test('foreign keys are enabled', () async {
      final rows = await db.rawQuery('PRAGMA foreign_keys');
      expect(rows.first.values.first, 1);
    });

    test('offline_routes cascades on region delete', () async {
      await db.insert('offline_regions', {
        'id': 'r1',
        'name': 'Test',
        'bbox_wkt': 'POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))',
        'min_zoom': 10,
        'max_zoom': 14,
        'tile_count': 0,
        'size_bytes': 0,
        'downloaded_at': 0,
        'status': 'complete',
      });
      await db.insert('offline_routes', {
        'id': 'rt1',
        'region_id': 'r1',
        'name': 'Trail A',
        'geojson': '{}',
      });
      await db.delete('offline_regions', where: 'id = ?', whereArgs: ['r1']);
      final remaining = await db.query('offline_routes');
      expect(remaining, isEmpty);
    });
  });
}
