import 'dart:async';

import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/battery_service.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sos_breadcrumbs_remote_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/repositories/sos_tracking_repository_impl.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:basic_crud_flutter/features/trek/domain/repositories/trek_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockBattery extends Mock implements BatteryService {}

class _MockBreadcrumbs extends Mock
    implements SosBreadcrumbsRemoteDataSource {}

class _MockTrek extends Mock implements TrekRepository {}

class _FakeBreadcrumb extends Fake implements Breadcrumb {}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
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

  late _MockLocation location;
  late _MockBattery battery;
  late _MockBreadcrumbs breadcrumbs;
  late _MockTrek trek;
  late SosTrackingRepositoryImpl repo;
  late StreamController<Position> positionController;

  setUp(() {
    location = _MockLocation();
    battery = _MockBattery();
    breadcrumbs = _MockBreadcrumbs();
    trek = _MockTrek();
    positionController = StreamController<Position>.broadcast();
    repo = SosTrackingRepositoryImpl(
      location: location,
      battery: battery,
      breadcrumbs: breadcrumbs,
      trek: trek,
    );
    when(() => location.trekPositionStream(
          interval: any(named: 'interval'),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).thenAnswer((_) => positionController.stream);
    when(() => battery.level()).thenAnswer((_) async => 80);
    when(() => breadcrumbs.append(any(), any())).thenAnswer((_) async {});
    when(() => trek.suspend()).thenAnswer((_) async {});
    when(() => trek.resume()).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (!positionController.isClosed) await positionController.close();
  });

  test('start suspends trek and subscribes at 30s cadence', () async {
    final result = await repo.start('alert-1');
    expect(result, isA<Success<void>>());
    verify(() => trek.suspend()).called(1);
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 30),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('position events append breadcrumbs to the parent alert', () async {
    await repo.start('alert-1');
    positionController.add(_pos(27.7, 88.15));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final captured = verify(
      () => breadcrumbs.append(captureAny(), captureAny()),
    ).captured;
    expect(captured, hasLength(2)); // alertId + breadcrumb
    expect(captured[0], 'alert-1');
    expect(captured[1], isA<Breadcrumb>());
    final crumb = captured[1] as Breadcrumb;
    expect(crumb.lat, 27.7);
    expect(crumb.lng, 88.15);
    expect(crumb.battery, 80);
  });

  test('battery < 20% triggers re-subscribe with 120s cadence', () async {
    when(() => battery.level()).thenAnswer((_) async => 15);
    await repo.start('alert-1');
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('battery recovery flips back from 120s to 30s cadence', () async {
    when(() => battery.level()).thenAnswer((_) async => 15);
    await repo.start('alert-1');
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    when(() => battery.level()).thenAnswer((_) async => 80);
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Initial 30s + flip-back to 30s after recovery = 2 subscribes at 30s.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 30),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(2);
    // One flip-down to 120s in between.
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 120),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('stop cancels the subscription and resumes trek exactly once',
      () async {
    await repo.start('alert-1');
    final result = await repo.stop();
    expect(result, isA<Success<void>>());
    // After stop, position events should NOT trigger appends.
    positionController.add(_pos(1, 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verifyNever(() => breadcrumbs.append(any(), any()));
    verify(() => trek.resume()).called(1);
  });

  test('start is idempotent — second start with the same alertId is a no-op',
      () async {
    await repo.start('alert-1');
    await repo.start('alert-1');
    verify(() => trek.suspend()).called(1);
    verify(() => location.trekPositionStream(
          interval: const Duration(seconds: 30),
          notificationTitle: any(named: 'notificationTitle'),
          notificationBody: any(named: 'notificationBody'),
        )).called(1);
  });

  test('watchActiveAlertId emits null at idle and the alertId after start',
      () async {
    final emissions = <String?>[];
    final sub = repo.watchActiveAlertId().listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.start('alert-2');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.stop();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(emissions, [null, 'alert-2', null]);
    await sub.cancel();
  });
}
