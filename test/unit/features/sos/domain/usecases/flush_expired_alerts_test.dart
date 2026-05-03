import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/battery_service.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sms_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/sos_alerts_remote_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/repositories/sos_repository_impl.dart';
import 'package:basic_crud_flutter/features/sos/domain/repositories/sos_outbox_repository.dart';
import 'package:basic_crud_flutter/features/sos/domain/usecases/flush_expired_alerts.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/latest_trek_breadcrumbs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocation extends Mock implements LocationService {}

class _MockBattery extends Mock implements BatteryService {}

class _MockSms extends Mock implements SmsDataSource {}

class _MockOutbox extends Mock implements SosOutboxRepository {}

class _MockLatest extends Mock implements LatestTrekBreadcrumbs {}

void main() {
  group('FlushExpiredAlerts', () {
    late FakeFirebaseFirestore firestore;
    late FlushExpiredAlerts flush;
    const me = 'me';
    const otherUid = 'other';

    Future<String> seedAlert({
      required String uid,
      required String status,
      required DateTime createdAt,
    }) async {
      final ref = await firestore.collection('sos_alerts').add({
        'uid': uid,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'lat': 0,
        'lng': 0,
        'userName': '',
        'userEmail': '',
        'contactsNotified': <Map<String, Object?>>[],
      });
      return ref.id;
    }

    setUp(() {
      firestore = FakeFirebaseFirestore();
      // Build the repo with only the alerts datasource — flushExpired
      // doesn't consult the others, so noop fakes via `null`-ish type
      // checks aren't needed (the impl never calls them on this path).
      final alertsDs = FirestoreSosAlertsRemoteDataSource(firestore);
      // Minimal SosRepositoryImpl wired only enough for flushExpired.
      // The other deps are not exercised in this test path.
      final repo = SosRepositoryImpl(
        location: _MockLocation(),
        battery: _MockBattery(),
        sms: _MockSms(),
        alertsDs: alertsDs,
        outbox: _MockOutbox(),
        latestBreadcrumbs: _MockLatest(),
      );
      flush = FlushExpiredAlerts(repo);
    });

    test('flips an active alert older than 6h to timed_out', () async {
      final id = await seedAlert(
        uid: me,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      );
      final result = await flush(me);
      expect(result, isA<Success<int>>());
      expect((result as Success<int>).value, 1);
      final after = await firestore.collection('sos_alerts').doc(id).get();
      expect(after.data()!['status'], 'timed_out');
    });

    test('leaves a recent active alert untouched', () async {
      final id = await seedAlert(
        uid: me,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final result = await flush(me);
      expect((result as Success<int>).value, 0);
      final after = await firestore.collection('sos_alerts').doc(id).get();
      expect(after.data()!['status'], 'active');
    });

    test('leaves a non-active old alert untouched', () async {
      final id = await seedAlert(
        uid: me,
        status: 'cancelled',
        createdAt: DateTime.now().subtract(const Duration(hours: 24)),
      );
      final result = await flush(me);
      expect((result as Success<int>).value, 0);
      final after = await firestore.collection('sos_alerts').doc(id).get();
      expect(after.data()!['status'], 'cancelled');
    });

    test('leaves another user\'s old active alert untouched', () async {
      final id = await seedAlert(
        uid: otherUid,
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      );
      final result = await flush(me);
      expect((result as Success<int>).value, 0);
      final after = await firestore.collection('sos_alerts').doc(id).get();
      expect(after.data()!['status'], 'active');
    });
  });
}

