import 'dart:convert';

import 'package:basic_crud_flutter/core/storage/local_db.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sos_alerts_remote_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sos_outbox_local_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/repositories/sos_outbox_repository_impl.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/sos_alert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockRemote extends Mock implements SosAlertsRemoteDataSource {}

const _alert = SosAlert(
  uid: 'u1',
  lat: 1,
  lng: 2,
  userName: 'n',
  userEmail: 'e',
  contactsNotified: [],
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late LocalDb localDb;
  late SqfliteSosOutboxLocalDataSource ds;
  late _MockRemote remote;
  late SosOutboxRepositoryImpl repo;

  setUp(() async {
    localDb = SqfliteLocalDb(path: inMemoryDatabasePath);
    await localDb.open();
    ds = SqfliteSosOutboxLocalDataSource(localDb);
    remote = _MockRemote();
    repo = SosOutboxRepositoryImpl(localDs: ds, remoteDs: remote);
  });

  tearDown(() => localDb.close());

  test('enqueueAlert writes a row with attempts=0', () async {
    final result = await repo.enqueueAlert(_alert);
    expect(result.fold(onSuccess: (_) => true, onFailure: (_) => false), isTrue);
    final due = await ds.dueRows(DateTime.now().millisecondsSinceEpoch);
    expect(due, hasLength(1));
    expect(due.first.attempts, 0);
    final decoded = jsonDecode(due.first.payloadJson) as Map<String, Object?>;
    expect(decoded['uid'], 'u1');
  });

  test('processDue success deletes the row', () async {
    when(() => remote.createFromJson(any()))
        .thenAnswer((_) async => 'alert-1');
    await repo.enqueueAlert(_alert);
    await repo.processDue();
    final remaining = await ds.dueRows(DateTime.now().millisecondsSinceEpoch);
    expect(remaining, isEmpty);
  });

  test('processDue failure increments attempts and reschedules', () async {
    when(() => remote.createFromJson(any())).thenThrow(Exception('boom'));
    await repo.enqueueAlert(_alert);
    final t0 = DateTime.now().millisecondsSinceEpoch;
    await repo.processDue();
    final rows = await ds.dueRows(t0 + 1000 * 60 * 60); // 1h horizon
    expect(rows, hasLength(1));
    expect(rows.first.attempts, 1);
    expect(rows.first.nextAttemptAt, greaterThan(t0));
  });
}
