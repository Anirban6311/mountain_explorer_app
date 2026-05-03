import 'package:basic_crud_flutter/core/storage/local_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SqfliteLocalDb', () {
    late LocalDb localDb;

    setUp(() {
      localDb = SqfliteLocalDb(path: inMemoryDatabasePath);
    });

    tearDown(() async {
      await localDb.close();
    });

    test('open() resolves to a usable Database', () async {
      final db = await localDb.open();
      expect(db.isOpen, isTrue);
    });

    test('open() is idempotent — second call returns same handle', () async {
      final db1 = await localDb.open();
      final db2 = await localDb.open();
      expect(identical(db1, db2), isTrue);
    });

    test('db getter returns the handle after open()', () async {
      await localDb.open();
      expect(localDb.db.isOpen, isTrue);
    });

    test('creates all four tables on first open', () async {
      final db = await localDb.open();
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
      );
      final tables = rows.map((r) => r['name'] as String).toSet();
      expect(tables, containsAll([
        'offline_regions',
        'trek_breadcrumbs',
        'sos_outbox',
        'offline_routes',
      ]));
    });

    test('enables PRAGMA foreign_keys', () async {
      final db = await localDb.open();
      final rows = await db.rawQuery('PRAGMA foreign_keys');
      expect(rows.first.values.first, 1);
    });

    test('close() then open() reopens cleanly', () async {
      await localDb.open();
      await localDb.close();
      final db = await localDb.open();
      expect(db.isOpen, isTrue);
    });

    test('db getter before open() throws StateError', () {
      expect(() => localDb.db, throwsStateError);
    });
  });
}
