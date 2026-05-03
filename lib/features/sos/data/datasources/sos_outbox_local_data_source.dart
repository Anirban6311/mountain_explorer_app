import 'dart:async';

import '../../../../core/storage/local_db.dart';

class OutboxRow {
  final int id;
  final String payloadJson;
  final String kind;
  final int attempts;
  final int nextAttemptAt;
  final int createdAt;
  const OutboxRow({
    required this.id,
    required this.payloadJson,
    required this.kind,
    required this.attempts,
    required this.nextAttemptAt,
    required this.createdAt,
  });

  factory OutboxRow.fromMap(Map<String, Object?> m) => OutboxRow(
        id: m['id']! as int,
        payloadJson: m['payload_json']! as String,
        kind: m['kind']! as String,
        attempts: m['attempts']! as int,
        nextAttemptAt: m['next_attempt_at']! as int,
        createdAt: m['created_at']! as int,
      );
}

abstract class SosOutboxLocalDataSource {
  Future<int> enqueue({
    required String payloadJson,
    required String kind,
    required int nextAttemptAt,
  });

  Future<List<OutboxRow>> dueRows(int now);

  Future<void> markAttempt({
    required int id,
    required int attempts,
    required int nextAttemptAt,
  });

  Future<void> delete(int id);
}

class SqfliteSosOutboxLocalDataSource implements SosOutboxLocalDataSource {
  SqfliteSosOutboxLocalDataSource(this._localDb);

  final LocalDb _localDb;
  static const String _table = 'sos_outbox';

  @override
  Future<int> enqueue({
    required String payloadJson,
    required String kind,
    required int nextAttemptAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _localDb.db.insert(_table, {
      'payload_json': payloadJson,
      'kind': kind,
      'attempts': 0,
      'next_attempt_at': nextAttemptAt,
      'created_at': now,
    });
  }

  @override
  Future<List<OutboxRow>> dueRows(int now) async {
    final rows = await _localDb.db.query(
      _table,
      where: 'next_attempt_at <= ?',
      whereArgs: [now],
      orderBy: 'next_attempt_at ASC',
    );
    return rows.map(OutboxRow.fromMap).toList();
  }

  @override
  Future<void> markAttempt({
    required int id,
    required int attempts,
    required int nextAttemptAt,
  }) =>
      _localDb.db.update(
        _table,
        {'attempts': attempts, 'next_attempt_at': nextAttemptAt},
        where: 'id = ?',
        whereArgs: [id],
      );

  @override
  Future<void> delete(int id) =>
      _localDb.db.delete(_table, where: 'id = ?', whereArgs: [id]);
}
