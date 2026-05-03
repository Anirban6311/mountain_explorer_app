import '../../../../core/storage/local_db.dart';
import '../../domain/entities/breadcrumb.dart';
import '../models/breadcrumb_model.dart';

abstract class TrekBreadcrumbsLocalDataSource {
  /// Inserts a new breadcrumb and trims the table to the [maxRows]
  /// most-recent entries (oldest by `ts` are dropped).
  Future<void> insert(Breadcrumb b);

  /// Returns the [limit] most recent breadcrumbs, ordered by `ts` DESC.
  Future<List<Breadcrumb>> latest({int limit = 50});

  Future<int> count();

  Future<void> clear();
}

class SqfliteTrekBreadcrumbsLocalDataSource
    implements TrekBreadcrumbsLocalDataSource {
  SqfliteTrekBreadcrumbsLocalDataSource(this._localDb);

  final LocalDb _localDb;
  static const String _table = 'trek_breadcrumbs';

  /// Ring-buffer cap. After each insert the DAO trims any row whose id
  /// is not in the top-`maxRows` set ordered by ts DESC.
  static const int maxRows = 500;

  @override
  Future<void> insert(Breadcrumb b) async {
    final db = _localDb.db;
    await db.insert(_table, BreadcrumbModel.toRow(b));
    // Single-statement trim: select the top-maxRows ids, delete the rest.
    // Exploits the existing idx_trek_breadcrumbs_ts_desc index.
    await db.rawDelete(
      'DELETE FROM $_table WHERE id NOT IN '
      '(SELECT id FROM $_table ORDER BY ts DESC LIMIT ?)',
      [maxRows],
    );
  }

  @override
  Future<List<Breadcrumb>> latest({int limit = 50}) async {
    final rows = await _localDb.db.query(
      _table,
      orderBy: 'ts DESC',
      limit: limit,
    );
    return rows.map(BreadcrumbModel.fromRow).toList();
  }

  @override
  Future<int> count() async {
    final rows = await _localDb.db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return (rows.first['c'] as int?) ?? 0;
  }

  @override
  Future<void> clear() => _localDb.db.delete(_table);
}
