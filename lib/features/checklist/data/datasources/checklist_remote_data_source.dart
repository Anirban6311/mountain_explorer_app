import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/checklist_item_model.dart';

abstract class ChecklistRemoteDataSource {
  Stream<List<ChecklistItemModel>> watchChecklist(String uid);
  Future<void> addItem({required String uid, required String text});
  Future<void> toggleItem({
    required String uid,
    required String itemId,
    required bool isDone,
  });
  Future<void> deleteItem({required String uid, required String itemId});
}

class FirestoreChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  final FirebaseFirestore _db;
  FirestoreChecklistRemoteDataSource(this._db);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('checklist');

  @override
  Stream<List<ChecklistItemModel>> watchChecklist(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChecklistItemModel.fromFirestore).toList());
  }

  @override
  Future<void> addItem({required String uid, required String text}) async {
    await _col(uid).add({
      'text': text,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> toggleItem({
    required String uid,
    required String itemId,
    required bool isDone,
  }) async {
    await _col(uid).doc(itemId).update({'isDone': isDone});
  }

  @override
  Future<void> deleteItem({
    required String uid,
    required String itemId,
  }) async {
    await _col(uid).doc(itemId).delete();
  }
}
