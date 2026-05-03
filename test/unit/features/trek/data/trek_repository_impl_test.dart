import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/battery_service.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/trek/data/datasources/trek_breadcrumbs_local_data_source.dart';
import 'package:basic_crud_flutter/features/trek/data/repositories/trek_repository_impl.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockBattery extends Mock implements BatteryService {}

class _MockDs extends Mock implements TrekBreadcrumbsLocalDataSource {}

class _FakeBreadcrumb extends Fake implements Breadcrumb {}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      accuracy: 10,
      altitude: 1500,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBreadcrumb());
    registerFallbackValue(const Duration(seconds: 0));
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLocation location;
  late _MockBattery battery;
  late _MockDs ds;
  late AppPrefs prefs;
  late TrekRepositoryImpl repo;
  late StreamController<Position> positionController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPrefs.create();
    location = _MockLocation();
    battery = _MockBattery();
    ds = _MockDs();
    // Broadcast so the repo can re-subscribe on cadence flips without
    // colliding with the prior listener.
    positionController = StreamController<Position>.broadcast();
    repo = TrekRepositoryImpl(
      location: location,
      battery: battery,
      ds: ds,
      prefs: prefs,
    );
    when(() => location.hasBackgroundPermission()).thenAnswer((_) async => true);
    when(() => location.trekPositionStream(
          interval: any(named: 'interval'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).thenAnswer((_) => positionController.stream);
    when(() => battery.level()).thenAnswer((_) async => 80);
    when(() => ds.insert(any())).thenAnswer((_) async {});
    when(() => ds.count()).thenAnswer((_) async => 0);
    when(() => ds.latest(limit: any(named: 'limit')))
        .thenAnswer((_) async => <Breadcrumb>[]);
  });

  tearDown(() async {
    if (!positionController.isClosed) await positionController.close();
  });

  test('start writes session id to prefs and subscribes to stream', () async {
    final result = await repo.start();
    expect(result, isA<Success<String>>());
    final id = (result as Success<String>).value;
    expect(id, isNotEmpty);
    expect(prefs.getActiveTrekSessionId(), id);
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('start without bg permission returns Failure(PermissionError)',
      () async {
    when(() => location.hasBackgroundPermission())
        .thenAnswer((_) async => false);
    final result = await repo.start();
    expect(result, isA<Failure<String>>());
    expect((result as Failure<String>).error, isA<PermissionError>());
    expect(prefs.getActiveTrekSessionId(), isNull);
    verifyNever(() => location.trekPositionStream(
          interval: any(named: 'interval'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        ));
  });

  test('position events insert breadcrumbs into the DAO', () async {
    await repo.start();
    positionController.add(_pos(27.7, 88.15));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => ds.insert(any())).called(1);
  });

  test('battery < 20% triggers re-subscribe with 300s interval', () async {
    when(() => battery.level()).thenAnswer((_) async => 15);
    await repo.start();
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // The re-subscribe means trekPositionStream is called twice — once
    // at start (120s) and once after the cadence flip (300s).
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 300),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('battery recovery (<20% then ≥20%) flips back to 120s', () async {
    // Start in low-battery mode.
    when(() => battery.level()).thenAnswer((_) async => 15);
    await repo.start();
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Battery recovers — next position should flip back to 120s.
    when(() => battery.level()).thenAnswer((_) async => 80);
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Initial 120s subscribe + flip-down to 300s + flip-back to 120s.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(2);
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 300),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('start is idempotent — second call reuses persisted session id',
      () async {
    final first = await repo.start();
    final id = (first as Success<String>).value;
    final second = await repo.start();
    expect((second as Success<String>).value, id);
    // Only one subscribe call across both invocations.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('stop clears session id and idle stream emits null', () async {
    await repo.start();
    final emissions = <String?>[];
    final sub = repo.watchActiveSessionId().listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.stop();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(prefs.getActiveTrekSessionId(), isNull);
    expect(emissions.last, isNull);
    await sub.cancel();
  });

  test('latest delegates to the DAO', () async {
    when(() => ds.latest(limit: 50))
        .thenAnswer((_) async => <Breadcrumb>[]);
    await repo.latest(limit: 50);
    verify(() => ds.latest(limit: 50)).called(1);
  });

  test('suspend cancels the position subscription but leaves prefs intact',
      () async {
    final start = await repo.start();
    final id = (start as Success<String>).value;
    await repo.suspend();
    // After suspend, a position event should NOT trigger an insert
    // because the subscription was cancelled.
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => ds.insert(any()));
    expect(prefs.getActiveTrekSessionId(), id);
  });

  test('resume re-subscribes when AppPrefs has a session id', () async {
    await repo.start();
    await repo.suspend();
    await repo.resume();
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verify(() => ds.insert(any())).called(1);
  });

  test('resume is a no-op when AppPrefs has no session id', () async {
    // Never started → no pref set.
    await repo.resume();
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNever(() => ds.insert(any()));
    // trekPositionStream should never have been called via resume.
    verifyNever(() => location.trekPositionStream(
          interval: any(named: 'interval'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        ));
  });

  test('resume is a no-op when already running (does not double-subscribe)',
      () async {
    await repo.start();
    await repo.resume();
    // Only one subscribe across start + resume.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('low-battery cadence is preserved across suspend → resume', () async {
    // Drive the repo into low-battery mode first.
    when(() => battery.level()).thenAnswer((_) async => 15);
    await repo.start();
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    // Suspend (e.g. SOS active) then resume.
    await repo.suspend();
    await repo.resume();
    // The post-resume subscription must inherit the low-battery cadence
    // (300s), not silently revert to the 120s default. Total subscribes:
    // 1 (start@120s) + 1 (flip@300s) + 1 (resume@300s) = 2 with 300s.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 300),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(2);
  });

  test('start → suspend → resume → suspend → resume settles cleanly',
      () async {
    await repo.start();
    await repo.suspend();
    await repo.resume();
    await repo.suspend();
    await repo.resume();
    // Position events after the final resume should still write.
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    verify(() => ds.insert(any())).called(1);
    // Across the two resumes (each preceded by a suspend), trekPositionStream
    // is called 1 (start) + 1 (1st resume) + 1 (2nd resume) = 3 times.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(3);
  });
}
