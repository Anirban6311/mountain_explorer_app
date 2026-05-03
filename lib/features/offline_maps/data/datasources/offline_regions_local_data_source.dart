import 'dart:async';

import '../../../../core/storage/local_db.dart';
import '../../domain/entities/offline_region.dart';
import '../models/offline_region_model.dart';

abstract class OfflineRegionsLocalDataSource {
  Future<void> insert(OfflineRegion region);
  Future<void> update(OfflineRegion region);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<OfflineRegion?> getById(String id);
  Future<List<OfflineRegion>> getAll();
  Future<int> totalSizeBytes();
  Stream<List<OfflineRegion>> watchRegions();
}

class SqfliteOfflineRegionsLocalDataSource
    implements OfflineRegionsLocalDataSource {
  SqfliteOfflineRegionsLocalDataSource(this._localDb);

  final LocalDb _localDb;
  final StreamController<List<OfflineRegion>> _mutations =
      StreamController<List<OfflineRegion>>.broadcast();

  static const String _table = 'offline_regions';

  @override
  Future<void> insert(OfflineRegion region) async {
    await _localDb.db.insert(_table, OfflineRegionModel.toRow(region));
    await _emitCurrent();
  }

  @override
  Future<void> update(OfflineRegion region) async {
    await _localDb.db.update(
      _table,
      OfflineRegionModel.toRow(region),
      where: 'id = ?',
      whereArgs: [region.id],
    );
    await _emitCurrent();
  }

  @override
  Future<void> delete(String id) async {
    await _localDb.db.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _emitCurrent();
  }

  @override
  Future<void> deleteAll() async {
    await _localDb.db.delete(_table);
    await _emitCurrent();
  }

  @override
  Future<OfflineRegion?> getById(String id) async {
    final rows = await _localDb.db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineRegionModel.fromRow(rows.first);
  }

  @override
  Future<List<OfflineRegion>> getAll() async {
    final rows =
        await _localDb.db.query(_table, orderBy: 'downloaded_at DESC');
    return rows.map(OfflineRegionModel.fromRow).toList();
  }

  @override
  Future<int> totalSizeBytes() async {
    // Quota accounting sums complete AND in-flight (downloading/partial)
    // rows so concurrent downloads can't bypass the quota check via the
    // downloading-row blind spot. `failed` rows are excluded because their
    // tiles were never committed to the cache.
    final rows = await _localDb.db.rawQuery(
      'SELECT COALESCE(SUM(size_bytes), 0) AS total '
      'FROM $_table WHERE status IN (?, ?, ?)',
      [
        OfflineRegionStatus.complete.name,
        OfflineRegionStatus.downloading.name,
        OfflineRegionStatus.partial.name,
      ],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  @override
  Stream<List<OfflineRegion>> watchRegions() {
    // Every subscriber receives the current snapshot first, then all
    // subsequent mutations. Using a per-subscriber async* avoids the bug
    // where late subscribers miss events already buffered on the
    // broadcast controller.
    late StreamController<List<OfflineRegion>> controller;
    StreamSubscription<List<OfflineRegion>>? upstream;
    controller = StreamController<List<OfflineRegion>>(
      onListen: () async {
        try {
          controller.add(await getAll());
        } catch (e, st) {
          controller.addError(e, st);
        }
        upstream = _mutations.stream.listen(
          controller.add,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await upstream?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> _emitCurrent() async {
    if (_mutations.isClosed) return;
    _mutations.add(await getAll());
  }

  /// Releases the broadcast controller. Tests call this during teardown;
  /// product code does not need to call it because the DAO lives for the
  /// process lifetime.
  Future<void> dispose() async {
    await _mutations.close();
  }
}
