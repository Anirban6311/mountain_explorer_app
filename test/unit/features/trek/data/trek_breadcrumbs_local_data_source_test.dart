import 'package:basic_crud_flutter/core/storage/local_db.dart';
import 'package:basic_crud_flutter/features/trek/data/datasources/trek_breadcrumbs_local_data_source.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Breadcrumb _b(int tsMs, {double lat = 1, double lng = 2}) => Breadcrumb(
      ts: DateTime.fromMillisecondsSinceEpoch(tsMs),
      lat: lat,
      lng: lng,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocalDb localDb;
  late SqfliteTrekBreadcrumbsLocalDataSource ds;

  setUp(() async {
    localDb = SqfliteLocalDb(path: inMemoryDatabasePath);
    await localDb.open();
    ds = SqfliteTrekBreadcrumbsLocalDataSource(localDb);
  });

  tearDown(() => localDb.close());

  test('insert + count', () async {
    await ds.insert(_b(1));
    await ds.insert(_b(2));
    expect(await ds.count(), 2);
  });

  test('latest(n) returns rows ordered by ts DESC', () async {
    await ds.insert(_b(100));
    await ds.insert(_b(300));
    await ds.insert(_b(200));
    final latest = await ds.latest(limit: 2);
    expect(latest.map((b) => b.ts.millisecondsSinceEpoch).toList(),
        [300, 200]);
  });

  test('insert beyond 500 trims oldest by ts', () async {
    // Insert 510 breadcrumbs with monotonically increasing ts.
    for (var i = 0; i < 510; i++) {
      await ds.insert(_b(i));
    }
    expect(await ds.count(), 500);
    final latest = await ds.latest(limit: 1);
    expect(latest.first.ts.millisecondsSinceEpoch, 509);
    final all = await ds.latest(limit: 500);
    // The trimmed-out breadcrumbs should be ts 0–9.
    final minRetained = all.map((b) => b.ts.millisecondsSinceEpoch)
        .reduce((a, b) => a < b ? a : b);
    expect(minRetained, 10);
  });

  test('clear removes every row', () async {
    await ds.insert(_b(1));
    await ds.insert(_b(2));
    await ds.clear();
    expect(await ds.count(), 0);
  });
}
