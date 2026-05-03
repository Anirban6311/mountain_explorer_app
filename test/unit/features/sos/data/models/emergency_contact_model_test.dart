import 'package:basic_crud_flutter/features/sos/data/models/emergency_contact_model.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/emergency_contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyContactModel', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);

    test('toMap excludes null relationship and uses serverTimestamp', () {
      const c = EmergencyContact(
        id: 'c1',
        name: 'Alice',
        phone: '+919876543210',
        isPrimary: true,
      );
      final map = EmergencyContactModel.toMap(c);
      expect(map['name'], 'Alice');
      expect(map['phone'], '+919876543210');
      expect(map['isPrimary'], isTrue);
      expect(map.containsKey('relationship'), isFalse);
      // Server timestamp sentinel — checked by type, not value.
      expect(map['createdAt'], isA<FieldValue>());
    });

    test('toMap includes relationship when present', () {
      const c = EmergencyContact(
        id: 'c1',
        name: 'Bob',
        phone: '9876543210',
        relationship: 'spouse',
      );
      final map = EmergencyContactModel.toMap(c);
      expect(map['relationship'], 'spouse');
    });

    test('fromFirestore reads doc id, fields, and Timestamp createdAt',
        () async {
      final fake = FakeFirebaseFirestore();
      final doc = fake.collection('c').doc('c1');
      await doc.set({
        'name': 'Alice',
        'phone': '+919876543210',
        'relationship': 'sister',
        'isPrimary': true,
        'createdAt': Timestamp.fromDate(ts),
      });
      final snap = await doc.get();
      final c = EmergencyContactModel.fromFirestore(snap);
      expect(c.id, 'c1');
      expect(c.name, 'Alice');
      expect(c.phone, '+919876543210');
      expect(c.relationship, 'sister');
      expect(c.isPrimary, isTrue);
      // Firestore Timestamp.toDate() returns local time. Compare epoch
      // ms to avoid local/UTC drift.
      expect(c.createdAt!.millisecondsSinceEpoch, ts.millisecondsSinceEpoch);
    });

    test('fromFirestore tolerates missing optional fields', () async {
      final fake = FakeFirebaseFirestore();
      final doc = fake.collection('c').doc('c2');
      await doc.set({
        'name': 'Min',
        'phone': '12345678',
      });
      final snap = await doc.get();
      final c = EmergencyContactModel.fromFirestore(snap);
      expect(c.relationship, isNull);
      expect(c.isPrimary, isFalse);
      expect(c.createdAt, isNull);
    });
  });
}
