import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/connectivity_service.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/emergency_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/sos_dispatch_result.dart';
import 'package:basic_crud_flutter/features/sos/domain/repositories/sos_outbox_repository.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/cancel_sos.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/fire_sos.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/flush_expired_alerts.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/process_sos_outbox.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/start_sos_tracking.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/stop_sos_tracking.dart';
import 'package:basic_crud_flutter/features/sos/presentation/cubit/sos_cubit.dart';
import 'package:basic_crud_flutter/features/sos/presentation/cubit/sos_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFire extends Mock implements FireSos {}

class _MockCancel extends Mock implements CancelSos {}

class _MockProcess extends Mock implements ProcessSosOutbox {}

class _MockOutbox extends Mock implements SosOutboxRepository {}

class _MockConn extends Mock implements ConnectivityService {}

class _MockLoc extends Mock implements LocationService {}

class _MockStartTracking extends Mock implements StartSosTracking {}

class _MockStopTracking extends Mock implements StopSosTracking {}

class _MockFlushExpired extends Mock implements FlushExpiredAlerts {}

const _contacts = [
  EmergencyContact(
    id: 'c1',
    name: 'Alice',
    phone: '+919876543210',
    isPrimary: true,
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 0));
  });

  late _MockFire fire;
  late _MockCancel cancel;
  late _MockProcess process;
  late _MockOutbox outbox;
  late _MockConn conn;
  late _MockLoc loc;
  late _MockStartTracking startTracking;
  late _MockStopTracking stopTracking;
  late _MockFlushExpired flushExpired;

  SosCubit build() => SosCubit(
        fireSos: fire,
        cancelSos: cancel,
        processOutbox: process,
        outbox: outbox,
        connectivity: conn,
        location: loc,
        startTracking: startTracking,
        stopTracking: stopTracking,
        flushExpired: flushExpired,
      );

  setUp(() {
    fire = _MockFire();
    cancel = _MockCancel();
    process = _MockProcess();
    outbox = _MockOutbox();
    conn = _MockConn();
    loc = _MockLoc();
    startTracking = _MockStartTracking();
    stopTracking = _MockStopTracking();
    flushExpired = _MockFlushExpired();
    when(() => process()).thenAnswer((_) async {});
    when(() => conn.onConnectivityChanged())
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => loc.hasForegroundPermission()).thenAnswer((_) async => true);
    when(() => loc.requestForegroundPermission())
        .thenAnswer((_) async => true);
    when(() => loc.hasBackgroundPermission())
        .thenAnswer((_) async => true);
    when(() => startTracking(any()))
        .thenAnswer((_) async => const Success<void>(null));
    when(() => stopTracking())
        .thenAnswer((_) async => const Success<void>(null));
    when(() => flushExpired(any(),
            ttl: any(named: 'ttl'))).thenAnswer((_) async => const Success<int>(0));
  });

  test('cold-start triggers outbox processor', () async {
    final cubit = build();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    verify(() => process()).called(1);
    await cubit.close();
  });

  test('onFabPressed without primary contact emits SosError', () async {
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: const [],
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, isA<SosError>());
    expect((cubit.state as SosError).message, contains('contact'));
    await cubit.close();
  });

  test('onFabPressed with permission denied emits SosError', () async {
    when(() => loc.requestForegroundPermission())
        .thenAnswer((_) async => false);
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, isA<SosError>());
    expect((cubit.state as SosError).message, contains('Location'));
    await cubit.close();
  });

  test('onFabPressed enters countdown then dispatches and tracks', () async {
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'alert-1',
            queued: false,
            contactsCount: 1,
          ),
        ));
    final cubit = build();
    // Pin the full state-machine ordering for the live path so a
    // regression that drops Dispatching or skips Active doesn't slip
    // through unnoticed. The leading SosIdle comes from the cubit's
    // ctor-time `_refreshPermissionFlag` emit; the three SosCountdown
    // emissions are remaining=3,2,1.
    final ordered = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<SosIdle>(),
        isA<SosCountdown>(),
        isA<SosCountdown>(),
        isA<SosCountdown>(),
        isA<SosDispatching>(),
        isA<SosActive>(),
      ]),
    );
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    // Wait for permission check + initial countdown emit.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state, isA<SosCountdown>());

    // Run the countdown to completion.
    await Future<void>.delayed(const Duration(seconds: 4));
    // Iter 5b: live (non-queued) dispatches transition through
    // SosDispatching into SosActive once tracking starts.
    expect(cubit.state, isA<SosActive>());
    expect((cubit.state as SosActive).alertId, 'alert-1');
    verify(() => startTracking('alert-1')).called(1);
    await ordered;
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('live dispatch without bg permission stays in SosDispatched (no track)',
      () async {
    when(() => loc.hasBackgroundPermission())
        .thenAnswer((_) async => false);
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'alert-no-bg',
            queued: false,
            contactsCount: 1,
          ),
        ));
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(cubit.state, isA<SosDispatched>());
    expect((cubit.state as SosDispatched).queued, isFalse);
    verifyNever(() => startTracking(any()));
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('tracking-start Failure surfaces SosError and cancels the alert',
      () async {
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'alert-fail',
            queued: false,
            contactsCount: 1,
          ),
        ));
    when(() => startTracking(any())).thenAnswer((_) async =>
        const Failure<void>(UnknownError('background revoked')));
    when(() => cancel(any()))
        .thenAnswer((_) async => const Success<void>(null));
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(cubit.state, isA<SosError>());
    expect((cubit.state as SosError).message, contains('background'));
    verify(() => cancel('alert-fail')).called(1);
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('queued dispatch stays in SosDispatched and does not start tracking',
      () async {
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'pending:7',
            queued: true,
            contactsCount: 1,
          ),
        ));
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(cubit.state, isA<SosDispatched>());
    expect((cubit.state as SosDispatched).queued, isTrue);
    verifyNever(() => startTracking(any()));
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('cancelDispatched while SosActive stops tracking before cancelling',
      () async {
    when(() => cancel(any()))
        .thenAnswer((_) async => const Success<void>(null));
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'alert-3',
            queued: false,
            contactsCount: 1,
          ),
        ));
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    expect(cubit.state, isA<SosActive>());
    await cubit.cancelDispatched();
    expect(cubit.state, isA<SosCancelledState>());
    verify(() => stopTracking()).called(1);
    verify(() => cancel('alert-3')).called(1);
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('flushExpiredOnBoot dispatches the use case', () async {
    final cubit = build();
    await cubit.flushExpiredOnBoot('u1');
    verify(() => flushExpired('u1', ttl: any(named: 'ttl'))).called(1);
    await cubit.close();
  });

  test('cancelCountdown returns to idle', () async {
    final cubit = build();
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state, isA<SosCountdown>());
    cubit.cancelCountdown();
    expect(cubit.state, isA<SosIdle>());
    await cubit.close();
  });

  test('cancelDispatched calls cancel use case for non-queued alert',
      () async {
    when(() => cancel(any()))
        .thenAnswer((_) async => const Success<void>(null));
    final cubit = build();
    // Drive cubit into SosDispatched directly by emit-equivalent: fire then
    // cancel. Use the public flow.
    when(() => fire(
          uid: any(named: 'uid'),
          userName: any(named: 'userName'),
          userEmail: any(named: 'userEmail'),
          contacts: any(named: 'contacts'),
        )).thenAnswer((_) async => const Success<SosDispatchResult>(
          SosDispatchResult(
            alertId: 'alert-2',
            queued: false,
            contactsCount: 1,
          ),
        ));
    cubit.onFabPressed(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'a@e.com',
      contacts: _contacts,
    );
    await Future<void>.delayed(const Duration(seconds: 4));
    // Iter 5b: live dispatches now settle in SosActive after tracking
    // starts; cancelDispatched still flips to SosCancelledState.
    expect(cubit.state, isA<SosActive>());
    await cubit.cancelDispatched();
    expect(cubit.state, isA<SosCancelledState>());
    verify(() => cancel('alert-2')).called(1);
    await cubit.close();
  }, timeout: const Timeout(Duration(seconds: 15)));
}
