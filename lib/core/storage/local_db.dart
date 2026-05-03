import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

abstract class LocalDb {
  /// Opens the underlying sqflite database. Idempotent — subsequent calls
  /// return the same [Database] handle.
  Future<Database> open();

  /// Raw handle for feature-owned DAOs. Must be called after [open] has
  /// resolved at least once.
  Database get db;

  /// Closes the database. Product code never closes; this exists for test
  /// teardown and graceful app shutdown.
  Future<void> close();
}

class SqfliteLocalDb implements LocalDb {
  /// When [path] is null, the database lives under `getDatabasesPath()` as
  /// `mountain_explorer.db`. Tests pass `inMemoryDatabasePath` to run
  /// entirely in RAM.
  SqfliteLocalDb({String? path}) : _overridePath = path;

  static const String _fileName = 'mountain_explorer.db';

  final String? _overridePath;
  Database? _db;
  Future<Database>? _pending;

  @override
  Future<Database> open() {
    final existing = _db;
    if (existing != null) return Future.value(existing);
    return _pending ??= _openOnce();
  }

  Future<Database> _openOnce() async {
    try {
      final resolvedPath =
          _overridePath ?? p.join(await getDatabasesPath(), _fileName);
      final db = await openDatabase(
        resolvedPath,
        version: allMigrations.last.version,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.transaction((txn) async {
            for (final m in allMigrations) {
              if (m.version <= version) await m.up(txn);
            }
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.transaction((txn) async {
            for (final m in allMigrations) {
              if (m.version > oldVersion && m.version <= newVersion) {
                await m.up(txn);
              }
            }
          });
        },
      );
      _db = db;
      return db;
    } finally {
      _pending = null;
    }
  }

  @override
  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('LocalDb.open() must resolve before accessing db.');
    }
    return d;
  }

  @override
  Future<void> close() async {
    // Drain any in-flight open so we don't close a handle that hasn't
    // been assigned yet — but don't surface its failure here.
    final pending = _pending;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        // Open failed; nothing to close.
      }
    }
    await _db?.close();
    _db = null;
    _pending = null;
  }
}
