import 'dart:convert';

import 'package:basic_crud_flutter/features/sos/data/models/sos_alert_model.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/sos_alert.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SosAlertModel.toMap', () {
    const alert = SosAlert(
      uid: 'u1',
      lat: 27.7,
      lng: 88.15,
      accuracy: 10,
      altitude: 1500,
      batteryLevel: 73,
      userName: 'Anirban',
      userEmail: 'anirban@example.com',
      contactsNotified: [
        NotifiedContact(name: 'A', phone: '+919876543210', isPrimary: true),
        NotifiedContact(name: 'B', phone: '+12025550100', isPrimary: false),
      ],
    );

    test('exposes every required key with the right shape', () {
      final map = SosAlertModel.toMap(alert);
      expect(map['uid'], 'u1');
      expect(map['status'], 'active');
      expect(map['lat'], 27.7);
      expect(map['lng'], 88.15);
      expect(map['accuracy'], 10);
      expect(map['altitude'], 1500);
      expect(map['batteryLevel'], 73);
      expect(map['userName'], 'Anirban');
      expect(map['userEmail'], 'anirban@example.com');
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['lastSeenAt'], isA<FieldValue>());
      final contacts = map['contactsNotified'] as List;
      expect(contacts, hasLength(2));
      expect((contacts.first as Map)['name'], 'A');
      expect((contacts.first as Map)['phone'], '+919876543210');
      expect((contacts.first as Map)['isPrimary'], isTrue);
    });

    test('omits null optional fields', () {
      const a = SosAlert(
        uid: 'u1',
        lat: 0,
        lng: 0,
        userName: '',
        userEmail: '',
        contactsNotified: [],
      );
      final map = SosAlertModel.toMap(a);
      expect(map.containsKey('accuracy'), isFalse);
      expect(map.containsKey('altitude'), isFalse);
      expect(map.containsKey('batteryLevel'), isFalse);
      expect(map.containsKey('trekBreadcrumbs'), isFalse);
    });

    test('serialises trekBreadcrumbs when non-empty', () {
      final a = SosAlert(
        uid: 'u1',
        lat: 0,
        lng: 0,
        userName: '',
        userEmail: '',
        contactsNotified: const [],
        trekBreadcrumbs: [
          Breadcrumb(
            ts: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
            lat: 27.7,
            lng: 88.15,
            accuracy: 12,
            altitude: 1500,
            battery: 80,
          ),
        ],
      );
      final map = SosAlertModel.toMap(a);
      final crumbs = map['trekBreadcrumbs'] as List;
      expect(crumbs, hasLength(1));
      expect((crumbs.first as Map)['ts'], 1700000000000);
      expect((crumbs.first as Map)['lat'], 27.7);
      expect((crumbs.first as Map)['battery'], 80);
    });
  });

  group('SosAlertModel.toJson (for outbox)', () {
    test('replaces server-timestamp sentinel with epoch ms', () {
      const a = SosAlert(
        uid: 'u1',
        lat: 1,
        lng: 2,
        userName: 'n',
        userEmail: 'e',
        contactsNotified: [],
      );
      final map = SosAlertModel.toJson(a);
      expect(map['createdAt'], isA<int>());
      expect(map['lastSeenAt'], isA<int>());
      expect(map['status'], 'active');
      expect(map.containsKey('trekBreadcrumbs'), isFalse);
    });

    test('includes trekBreadcrumbs as JSON-safe maps when non-empty', () {
      final a = SosAlert(
        uid: 'u1',
        lat: 0,
        lng: 0,
        userName: '',
        userEmail: '',
        contactsNotified: const [],
        trekBreadcrumbs: [
          Breadcrumb(
            ts: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
            lat: 27.7,
            lng: 88.15,
          ),
        ],
      );
      final map = SosAlertModel.toJson(a);
      final crumbs = map['trekBreadcrumbs'] as List;
      expect(crumbs, hasLength(1));
      expect((crumbs.first as Map)['lat'], 27.7);
    });

    test('breadcrumbs survive jsonEncode/jsonDecode round-trip', () {
      // The outbox stores the toJson() map encoded as a TEXT column,
      // then decodes it back into createFromJson on retry. Ensures only
      // primitive types are emitted so the round-trip is lossless.
      final a = SosAlert(
        uid: 'u1',
        lat: 0,
        lng: 0,
        userName: '',
        userEmail: '',
        contactsNotified: const [],
        trekBreadcrumbs: [
          Breadcrumb(
            ts: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
            lat: 27.7,
            lng: 88.15,
            accuracy: 12,
            altitude: 1500,
            battery: 80,
          ),
        ],
      );
      final encoded = jsonEncode(SosAlertModel.toJson(a));
      final decoded = jsonDecode(encoded) as Map<String, Object?>;
      final crumbs = decoded['trekBreadcrumbs'] as List;
      expect(crumbs, hasLength(1));
      expect((crumbs.first as Map)['lat'], 27.7);
      expect((crumbs.first as Map)['ts'], 1700000000000);
      expect((crumbs.first as Map)['battery'], 80);
    });
  });
}
