import 'package:sqflite/sqflite.dart';

/// A single schema migration. `version` is the target schema version the
/// migration advances the database to; `up` runs in a transaction owned by
/// [SqfliteLocalDb].
class Migration {
  final int version;
  final Future<void> Function(DatabaseExecutor db) up;
  const Migration({required this.version, required this.up});
}

final List<Migration> allMigrations = [
  Migration(version: 1, up: _migration1),
];

Future<void> _migration1(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE offline_regions (
      id             TEXT    PRIMARY KEY,
      name           TEXT    NOT NULL,
      bbox_wkt       TEXT    NOT NULL,
      min_zoom       INTEGER NOT NULL,
      max_zoom       INTEGER NOT NULL,
      tile_count     INTEGER NOT NULL DEFAULT 0,
      size_bytes     INTEGER NOT NULL DEFAULT 0,
      downloaded_at  INTEGER NOT NULL,
      status         TEXT    NOT NULL DEFAULT 'pending'
    )
  ''');

  await db.execute('''
    CREATE TABLE trek_breadcrumbs (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      ts        INTEGER NOT NULL,
      lat       REAL    NOT NULL,
      lng       REAL    NOT NULL,
      accuracy  REAL,
      altitude  REAL,
      battery   INTEGER
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_trek_breadcrumbs_ts_desc ON trek_breadcrumbs(ts DESC)',
  );

  await db.execute('''
    CREATE TABLE sos_outbox (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      payload_json    TEXT    NOT NULL,
      kind            TEXT    NOT NULL,
      attempts        INTEGER NOT NULL DEFAULT 0,
      next_attempt_at INTEGER NOT NULL,
      created_at      INTEGER NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_sos_outbox_next ON sos_outbox(next_attempt_at ASC)',
  );

  await db.execute('''
    CREATE TABLE offline_routes (
      id        TEXT PRIMARY KEY,
      region_id TEXT NOT NULL,
      name      TEXT NOT NULL,
      geojson   TEXT NOT NULL,
      FOREIGN KEY (region_id) REFERENCES offline_regions(id) ON DELETE CASCADE
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_offline_routes_region ON offline_routes(region_id)',
  );
}
