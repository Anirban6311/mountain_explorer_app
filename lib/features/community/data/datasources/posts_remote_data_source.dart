import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';

abstract class PostsRemoteDataSource {
  Stream<List<PostModel>> watchFeed();

  Future<PostModel?> getPost(String pId);

  /// Creates the Firestore doc with server timestamp. Returns the newly
  /// created post (post-fetch with resolved timestamp).
  Future<PostModel> createPost({
    required String pTitle,
    required String pDescription,
    required String pImage,
    required String uid,
    required String uEmail,
    required String uName,
  });

  /// Updates title/description only.
  Future<void> updatePost({
    required String pId,
    required String title,
    required String description,
  });

  /// Deletes the post document. Caller is responsible for Storage + comments
  /// cleanup.
  Future<void> deletePost(String pId);

  /// Atomic arrayUnion/arrayRemove on `likes`.
  Future<void> toggleLikePost({
    required String pId,
    required String uid,
  });
}

class FirestorePostsRemoteDataSource implements PostsRemoteDataSource {
  final FirebaseFirestore _db;
  FirestorePostsRemoteDataSource(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('posts');

  @override
  Stream<List<PostModel>> watchFeed() {
    return _col
        .orderBy('pTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());
  }

  @override
  Future<PostModel?> getPost(String pId) async {
    final doc = await _col.doc(pId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  @override
  Future<PostModel> createPost({
    required String pTitle,
    required String pDescription,
    required String pImage,
    required String uid,
    required String uEmail,
    required String uName,
  }) async {
    final docRef = _col.doc();
    await docRef.set({
      'pId': docRef.id,
      'pTitle': pTitle,
      'pDescription': pDescription,
      'pImage': pImage,
      'pTime': FieldValue.serverTimestamp(),
      'uid': uid,
      'uEmail': uEmail,
      'uName': uName,
      'likes': <String>[],
    });
    final snap = await docRef.get();
    return PostModel.fromFirestore(snap);
  }

  @override
  Future<void> updatePost({
    required String pId,
    required String title,
    required String description,
  }) async {
    await _col.doc(pId).update({
      'pTitle': title,
      'pDescription': description,
    });
  }

  @override
  Future<void> deletePost(String pId) async {
    await _col.doc(pId).delete();
  }

  @override
  Future<void> toggleLikePost({
    required String pId,
    required String uid,
  }) async {
    final ref = _col.doc(pId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final likes = ((snap.data()?['likes'] as List?) ?? const [])
          .cast<String>();
      if (likes.contains(uid)) {
        txn.update(ref, {
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        txn.update(ref, {
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    });
  }
}
