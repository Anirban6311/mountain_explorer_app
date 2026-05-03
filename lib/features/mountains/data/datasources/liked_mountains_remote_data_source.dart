import 'package:cloud_firestore/cloud_firestore.dart';

abstract class LikedMountainsRemoteDataSource {
  Stream<Set<String>> watchLikedMountainIds(String uid);

  Future<void> toggleLike({
    required String uid,
    required String mountainId,
  });
}

class FirestoreLikedMountainsRemoteDataSource
    implements LikedMountainsRemoteDataSource {
  final FirebaseFirestore _db;
  FirestoreLikedMountainsRemoteDataSource(this._db);

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid).collection('private').doc('likedMountains');

  @override
  Stream<Set<String>> watchLikedMountainIds(String uid) {
    return _doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String>{};
      final ids = (data['mountainIds'] as List?) ?? const [];
      return ids.cast<String>().toSet();
    });
  }

  @override
  Future<void> toggleLike({
    required String uid,
    required String mountainId,
  }) async {
    final ref = _doc(uid);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final ids = ((snap.data()?['mountainIds'] as List?) ?? const [])
          .cast<String>();
      if (ids.contains(mountainId)) {
        txn.set(
          ref,
          {'mountainIds': FieldValue.arrayRemove([mountainId])},
          SetOptions(merge: true),
        );
      } else {
        txn.set(
          ref,
          {'mountainIds': FieldValue.arrayUnion([mountainId])},
          SetOptions(merge: true),
        );
      }
    });
  }
}
