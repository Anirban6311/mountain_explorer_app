import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/battery_service.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sms_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sos_alerts_remote_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/emergency_contact.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/sos_alert.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/sos_dispatch_result.dart';
import 'package:basic_crud_flutter/features/sos/domain/repositories/sos_outbox_repository.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/latest_trek_breadcrumbs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockBattery extends Mock implements BatteryService {}

class _MockSms extends Mock implements SmsDataSource {}

class _MockAlerts extends Mock implements SosAlertsRemoteDataSource {}

class _MockOutbox extends Mock implements SosOutboxRepository {}

class _MockLatestBreadcrumbs extends Mock implements LatestTrekBreadcrumbs {}

class _FakeAlert extends Fake implements SosAlert {}

Position _pos() => Position(
      latitude: 27.7,
      longitude: 88.15,
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
    registerFallbackValue(_FakeAlert());
    registerFallbackValue(LocationAccuracy.high);
    registerFallbackValue(const Duration(seconds: 15));
  });

  late _MockLocation location;
  late _MockBattery battery;
  late _MockSms sms;
  late _MockAlerts alerts;
  late _MockOutbox outbox;
  late _MockLatestBreadcrumbs latestBreadcrumbs;
  late SosRepositoryImpl repo;

  const contacts = [
    EmergencyContact(
      id: 'c1',
      name: 'Alice',
      phone: '+919876543210',
      isPrimary: true,
    ),
    EmergencyContact(
      id: 'c2',
      name: 'Bob',
      phone: '+12025550100',
    ),
  ];

  setUp(() {
    location = _MockLocation();
    battery = _MockBattery();
    sms = _MockSms();
    alerts = _MockAlerts();
    outbox = _MockOutbox();
    latestBreadcrumbs = _MockLatestBreadcrumbs();
    repo = SosRepositoryImpl(
      location: location,
      battery: battery,
      sms: sms,
      alertsDs: alerts,
      outbox: outbox,
      latestBreadcrumbs: latestBreadcrumbs,
    );
    when(() => location.hasForegroundPermission())
        .thenAnswer((_) async => true);
    when(() => location.getCurrentPosition(
          accuracy: any(named: 'accuracy'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => _pos());
    when(() => battery.level()).thenAnswer((_) async => 73);
    when(() => sms.sendSms(
          phone: any(named: 'phone'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => true);
    when(() => outbox.enqueueAlert(any()))
        .thenAnswer((_) async => const Success<int>(1));
    when(() => latestBreadcrumbs(limit: any(named: 'limit')))
        .thenAnswer((_) async => const <Breadcrumb>[]);
  });

  test('happy path: returns alertId, queued=false, contactsCount', () async {
    when(() => alerts.create(any())).thenAnswer((_) async => 'alert-123');
    final result = await repo.fire(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contacts: contacts,
    );
    expect(result, isA<Success<SosDispatchResult>>());
    final v = (result as Success<SosDispatchResult>).value;
    expect(v.alertId, 'alert-123');
    expect(v.queued, isFalse);
    expect(v.contactsCount, 2);
    verify(() => sms.sendSms(
          phone: '+919876543210',
          body: any(named: 'body'),
        )).called(1);
    verify(() => sms.sendSms(
          phone: '+12025550100',
          body: any(named: 'body'),
        )).called(1);
  });

  test('Firestore failure → outbox enqueue, queued=true', () async {
    when(() => alerts.create(any())).thenThrow(Exception('offline'));
    final result = await repo.fire(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contacts: contacts,
    );
    expect(result, isA<Success<SosDispatchResult>>());
    final v = (result as Success<SosDispatchResult>).value;
    // After the H2-sec fix, the queued path encodes the outbox row id
    // in the alertId so SosCubit.cancelDispatched can delete the row.
    expect(v.alertId, startsWith('pending:'));
    expect(v.queued, isTrue);
    verify(() => outbox.enqueueAlert(any())).called(1);
  });

  test('no permission → PermissionError', () async {
    when(() => location.hasForegroundPermission())
        .thenAnswer((_) async => false);
    final result = await repo.fire(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contacts: contacts,
    );
    expect(result, isA<Failure<SosDispatchResult>>());
    expect((result as Failure<SosDispatchResult>).error, isA<PermissionError>());
  });

  test('attaches the latest 50 trek breadcrumbs to the live alert', () async {
    final crumbs = [
      Breadcrumb(
        ts: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
        lat: 27.7,
        lng: 88.15,
      ),
    ];
    when(() => latestBreadcrumbs(limit: 50))
        .thenAnswer((_) async => crumbs);
    when(() => alerts.create(any())).thenAnswer((_) async => 'alert-456');
    await repo.fire(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contacts: contacts,
    );
    final captured = verify(() => alerts.create(captureAny())).captured;
    expect(captured, hasLength(1));
    final alert = captured.single as SosAlert;
    expect(alert.trekBreadcrumbs, crumbs);
    verify(() => latestBreadcrumbs(limit: 50)).called(1);
  });

  test('breadcrumb fetch failure does not abort the alert', () async {
    when(() => latestBreadcrumbs(limit: any(named: 'limit')))
        .thenThrow(Exception('sqflite read error'));
    when(() => alerts.create(any())).thenAnswer((_) async => 'alert-789');
    final result = await repo.fire(
      uid: 'u1',
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contacts: contacts,
    );
    expect(result, isA<Success<SosDispatchResult>>());
    final captured = verify(() => alerts.create(captureAny())).captured;
    expect((captured.single as SosAlert).trekBreadcrumbs, isEmpty);
  });

  test('empty contacts → ValidationError', () async {
    final result = await repo.fire(
      uid: 'u1',
      userName: 'n',
      userEmail: 'e',
      contacts: const [],
    );
    expect(result, isA<Failure<SosDispatchResult>>());
    expect((result as Failure<SosDispatchResult>).error,
        isA<ValidationError>());
  });
}
