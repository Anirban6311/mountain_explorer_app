import 'dart:convert';
import 'dart:math' as math;

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/repositories/sos_outbox_repository.dart';
import '../datasources/sos_alerts_remote_data_source.dart';
import '../datasources/sos_outbox_local_data_source.dart';
import '../models/sos_alert_model.dart';

class SosOutboxRepositoryImpl implements SosOutboxRepository {
  SosOutboxRepositoryImpl({
    required SosOutboxLocalDataSource localDs,
    required SosAlertsRemoteDataSource remoteDs,
  })  : _local = localDs,
        _remote = remoteDs;

  final SosOutboxLocalDataSource _local;
  final SosAlertsRemoteDataSource _remote;

  /// Backoff base. Each retry waits `_backoffBaseSeconds * 2^attempts`,
  /// capped at 1h.
  static const int _backoffBaseSeconds = 60;
  static const int _maxBackoffSeconds = 3600;

  @override
  Future<Result<int>> enqueueAlert(SosAlert alert) async {
    try {
      final json = jsonEncode(SosAlertModel.toJson(alert));
      final id = await _local.enqueue(
        payloadJson: json,
        kind: 'alert',
        nextAttemptAt: DateTime.now().millisecondsSinceEpoch,
      );
      return Success<int>(id);
    } catch (e) {
      return Failure<int>(
        UnknownError('Failed to enqueue SOS payload.', cause: e),
      );
    }
  }

  @override
  Future<void> deleteQueued(int id) => _local.delete(id);

  @override
  Future<void> processDue() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = await _local.dueRows(now);
    for (final row in due) {
      try {
        final payload = jsonDecode(row.payloadJson) as Map<String, Object?>;
        await _remote.createFromJson(payload);
        await _local.delete(row.id);
      } catch (_) {
        final attempts = row.attempts + 1;
        final waitSeconds = math.min(
          _maxBackoffSeconds,
          _backoffBaseSeconds * (1 << attempts.clamp(0, 6)),
        );
        await _local.markAttempt(
          id: row.id,
          attempts: attempts,
          nextAttemptAt: now + waitSeconds * 1000,
        );
      }
    }
  }
}
