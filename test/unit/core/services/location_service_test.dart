import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockFacade extends Mock implements GeolocatorFacade {}

class _FakeLocationSettings extends Fake implements LocationSettings {}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeLocationSettings());
  });

  group('GeolocatorLocationService', () {
    late _MockFacade facade;
    late GeolocatorLocationService service;

    setUp(() {
      facade = _MockFacade();
      service = GeolocatorLocationService(facade: facade);
    });

    group('hasForegroundPermission', () {
      test('returns true for whileInUse', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        expect(await service.hasForegroundPermission(), isTrue);
      });

      test('returns true for always', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.always);
        expect(await service.hasForegroundPermission(), isTrue);
      });

      test('returns false for denied', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        expect(await service.hasForegroundPermission(), isFalse);
      });

      test('returns false for deniedForever', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.deniedForever);
        expect(await service.hasForegroundPermission(), isFalse);
      });
    });

    group('hasBackgroundPermission', () {
      test('returns true only for always', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.always);
        expect(await service.hasBackgroundPermission(), isTrue);
      });

      test('returns false for whileInUse', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        expect(await service.hasBackgroundPermission(), isFalse);
      });
    });

    group('requestBackgroundPermission', () {
      test('throws StateError when foreground not yet granted', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        expect(
          () => service.requestBackgroundPermission(),
          throwsA(isA<StateError>()),
        );
      });

      test('returns true when escalation to always succeeds', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => facade.requestPermission())
            .thenAnswer((_) async => LocationPermission.always);
        expect(await service.requestBackgroundPermission(), isTrue);
      });
    });

    group('getCurrentPosition', () {
      test('throws PermissionError when no foreground permission', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        await expectLater(
          service.getCurrentPosition(),
          throwsA(isA<PermissionError>()),
        );
      });

      test('returns the facade Position on success', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => facade.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenAnswer((_) async => _pos(27.7, 88.15));
        final got = await service.getCurrentPosition();
        expect(got.latitude, 27.7);
        expect(got.longitude, 88.15);
      });

      test('maps LocationServiceDisabledException to PermissionError',
          () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => facade.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenThrow(LocationServiceDisabledException());
        await expectLater(
          service.getCurrentPosition(),
          throwsA(isA<PermissionError>()),
        );
      });

      test('maps an unknown throw to UnknownError', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        when(() => facade.getCurrentPosition(
              locationSettings: any(named: 'locationSettings'),
            )).thenThrow(Exception('boom'));
        await expectLater(
          service.getCurrentPosition(),
          throwsA(isA<UnknownError>()),
        );
      });
    });

    group('requestForegroundPermission', () {
      test('returns true when already granted (whileInUse)', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        expect(await service.requestForegroundPermission(), isTrue);
      });

      test('calls requestPermission when currently denied', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(() => facade.requestPermission())
            .thenAnswer((_) async => LocationPermission.whileInUse);
        expect(await service.requestForegroundPermission(), isTrue);
        verify(() => facade.requestPermission()).called(1);
      });

      test('returns false when the user declines the prompt', () async {
        when(() => facade.checkPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        when(() => facade.requestPermission())
            .thenAnswer((_) async => LocationPermission.denied);
        expect(await service.requestForegroundPermission(), isFalse);
      });

      test('returns false when facade throws (plugin-not-ready)', () async {
        when(() => facade.checkPermission()).thenThrow(Exception('not ready'));
        expect(await service.requestForegroundPermission(), isFalse);
      });
    });

    test('isLocationServiceEnabled forwards to facade', () async {
      when(() => facade.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      expect(await service.isLocationServiceEnabled(), isTrue);
    });
  });
}
