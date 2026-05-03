import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/sos/data/datasources/emergency_contacts_remote_data_source.dart';
import 'package:basic_crud_flutter/features/sos/data/repositories/emergency_contacts_repository_impl.dart';
import 'package:basic_crud_flutter/features/sos/domain/entities/emergency_contact.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyContactsRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreEmergencyContactsRemoteDataSource ds;
    late EmergencyContactsRepositoryImpl repo;
    const uid = 'user1';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      ds = FirestoreEmergencyContactsRemoteDataSource(firestore);
      repo = EmergencyContactsRepositoryImpl(ds: ds);
    });

    test('first add auto-becomes primary', () async {
      final result = await repo.add(
        uid: uid,
        draft: const EmergencyContact(
          id: '',
          name: 'Alice',
          phone: '+919876543210',
        ),
      );
      expect(result, isA<Success<EmergencyContact>>());
      final stored =
          await firestore.collection('users').doc(uid).collection('emergencyContacts').get();
      expect(stored.docs, hasLength(1));
      expect(stored.docs.first.data()['isPrimary'], isTrue);
    });

    test('subsequent adds default to non-primary', () async {
      await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'A', phone: '12345678'),
      );
      await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'B', phone: '23456789'),
      );
      final stored = await firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .get();
      final primaries = stored.docs.where(
        (d) => d.data()['isPrimary'] == true,
      );
      expect(primaries, hasLength(1));
    });

    test('setPrimary atomically flips both rows', () async {
      final r1 = await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'A', phone: '12345678'),
      );
      final r2 = await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'B', phone: '23456789'),
      );
      final aId = (r1 as Success<EmergencyContact>).value.id;
      final bId = (r2 as Success<EmergencyContact>).value.id;
      await repo.setPrimary(uid: uid, contactId: bId);
      final aDoc = await firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .doc(aId)
          .get();
      final bDoc = await firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .doc(bId)
          .get();
      expect(aDoc.data()!['isPrimary'], isFalse);
      expect(bDoc.data()!['isPrimary'], isTrue);
    });

    test('delete removes the row', () async {
      final r = await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'A', phone: '12345678'),
      );
      final id = (r as Success<EmergencyContact>).value.id;
      await repo.delete(uid: uid, contactId: id);
      final stored = await firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .get();
      expect(stored.docs, isEmpty);
    });

    test('update writes the new fields', () async {
      final r = await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'A', phone: '12345678'),
      );
      final c = (r as Success<EmergencyContact>).value;
      await repo.update(
        uid: uid,
        contact: c.copyWith(name: 'Updated', phone: '+919999999999'),
      );
      final got = await firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .doc(c.id)
          .get();
      expect(got.data()!['name'], 'Updated');
      expect(got.data()!['phone'], '+919999999999');
    });

    test('watch emits the current snapshot then updates', () async {
      await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'A', phone: '12345678'),
      );
      final emissions = <int>[];
      final sub = repo.watch(uid).listen((list) => emissions.add(list.length));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await repo.add(
        uid: uid,
        draft: const EmergencyContact(id: '', name: 'B', phone: '23456789'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await sub.cancel();
      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last, 2);
    });
  });
}
