import 'package:basic_crud_flutter/features/sos/data/datasources/sos_breadcrumbs_remote_data_source.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreSosBreadcrumbsRemoteDataSource', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreSosBreadcrumbsRemoteDataSource ds;
    const alertId = 'alert-1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      ds = FirestoreSosBreadcrumbsRemoteDataSource(firestore);
    });

    test('append writes to sos_alerts/{alertId}/breadcrumbs/{tsMs}', () async {
      final ts = DateTime.fromMillisecondsSinceEpoch(1745568123456, isUtc: true);
      await ds.append(
        alertId,
        Breadcrumb(
          ts: ts,
          lat: 27.7,
          lng: 88.15,
          accuracy: 12,
          altitude: 1500,
          battery: 80,
        ),
      );
      final docs = await firestore
          .collection('sos_alerts')
          .doc(alertId)
          .collection('breadcrumbs')
          .get();
      expect(docs.docs, hasLength(1));
      final doc = docs.docs.first;
      expect(doc.id, '1745568123456');
      final data = doc.data();
      expect(data['ts'], 1745568123456);
      expect(data['lat'], 27.7);
      expect(data['lng'], 88.15);
      expect(data['accuracy'], 12);
      expect(data['altitude'], 1500);
      expect(data['battery'], 80);
    });

    test('append omits null optional fields', () async {
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      await ds.append(
        alertId,
        Breadcrumb(ts: ts, lat: 0, lng: 0),
      );
      final doc = await firestore
          .collection('sos_alerts')
          .doc(alertId)
          .collection('breadcrumbs')
          .doc('1700000000000')
          .get();
      final data = doc.data()!;
      expect(data.containsKey('accuracy'), isFalse);
      expect(data.containsKey('altitude'), isFalse);
      expect(data.containsKey('battery'), isFalse);
      expect(data.keys, containsAll(['ts', 'lat', 'lng']));
    });

    test('append twice with the same ts keeps a single doc', () async {
      // Production firestore.rules pin the breadcrumb subcollection to
      // `update, delete: if false` — a second client-side `set()` to the
      // same tsMs doc id would be REJECTED by rules. fake_cloud_firestore
      // doesn't enforce rules, so this test only verifies that the
      // datasource doesn't accidentally create a duplicate doc id (e.g.
      // by switching to auto-id). The rule rejection is a benign no-op
      // for at-least-once retry: same-ms collisions on a 30s cadence are
      // effectively zero in production.
      final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      await ds.append(alertId, Breadcrumb(ts: ts, lat: 1, lng: 1));
      await ds.append(alertId, Breadcrumb(ts: ts, lat: 2, lng: 2));
      final docs = await firestore
          .collection('sos_alerts')
          .doc(alertId)
          .collection('breadcrumbs')
          .get();
      expect(docs.docs, hasLength(1));
    });
  });
}
