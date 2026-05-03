import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/emergency_contact.dart';
import '../models/emergency_contact_model.dart';

abstract class EmergencyContactsRemoteDataSource {
  Stream<List<EmergencyContact>> watch(String uid);
  Future<EmergencyContact> add(String uid, EmergencyContact draft);
  Future<void> update(String uid, EmergencyContact contact);
  Future<void> delete(String uid, String contactId);

  /// Atomic primary flip via [WriteBatch]. If [previousPrimaryId] is null,
  /// the batch contains only the set-true op for [newPrimaryId].
  Future<void> setPrimary(
    String uid, {
    required String newPrimaryId,
    String? previousPrimaryId,
  });

  Future<int> count(String uid);
  Future<EmergencyContact?> findPrimary(String uid);
}

class FirestoreEmergencyContactsRemoteDataSource
    implements EmergencyContactsRemoteDataSource {
  FirestoreEmergencyContactsRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, Object?>> _col(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('emergencyContacts');

  @override
  Stream<List<EmergencyContact>> watch(String uid) {
    return _col(uid).orderBy('isPrimary', descending: true).snapshots().map(
          (snap) => snap.docs.map(EmergencyContactModel.fromFirestore).toList(),
        );
  }

  @override
  Future<EmergencyContact> add(String uid, EmergencyContact draft) async {
    final doc = await _col(uid).add(EmergencyContactModel.toMap(draft));
    return draft.copyWith(id: doc.id);
  }

  @override
  Future<void> update(String uid, EmergencyContact contact) async {
    final map = EmergencyContactModel.toMap(contact)
      ..remove('createdAt'); // Don't overwrite original timestamp.
    await _col(uid).doc(contact.id).update(map);
  }

  @override
  Future<void> delete(String uid, String contactId) =>
      _col(uid).doc(contactId).delete();

  @override
  Future<void> setPrimary(
    String uid, {
    required String newPrimaryId,
    String? previousPrimaryId,
  }) async {
    final batch = _db.batch();
    if (previousPrimaryId != null && previousPrimaryId != newPrimaryId) {
      batch.update(_col(uid).doc(previousPrimaryId), {'isPrimary': false});
    }
    batch.update(_col(uid).doc(newPrimaryId), {'isPrimary': true});
    await batch.commit();
  }

  @override
  Future<int> count(String uid) async {
    final snap = await _col(uid).get();
    return snap.docs.length;
  }

  @override
  Future<EmergencyContact?> findPrimary(String uid) async {
    final snap = await _col(uid)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return EmergencyContactModel.fromFirestore(snap.docs.first);
  }
}
