import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment_model.dart';

abstract class CommentsRemoteDataSource {
  Stream<List<CommentModel>> watchComments(String pId);

  Future<void> addComment({
    required String pId,
    required String text,
    required String commentedBy,
    required String commentedByName,
  });

  Future<void> deleteComment({
    required String pId,
    required String commentId,
  });
}

class FirestoreCommentsRemoteDataSource implements CommentsRemoteDataSource {
  final FirebaseFirestore _db;
  FirestoreCommentsRemoteDataSource(this._db);

  CollectionReference<Map<String, dynamic>> _col(String pId) =>
      _db.collection('posts').doc(pId).collection('comments');

  @override
  Stream<List<CommentModel>> watchComments(String pId) {
    // Ascending so the newest comment renders adjacent to the input bar
    // at the bottom of the page.
    return _col(pId)
        .orderBy('commentedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
  }

  @override
  Future<void> addComment({
    required String pId,
    required String text,
    required String commentedBy,
    required String commentedByName,
  }) async {
    await _col(pId).add({
      'text': text,
      'commentedBy': commentedBy,
      'commentedByName': commentedByName,
      'commentedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteComment({
    required String pId,
    required String commentId,
  }) async {
    await _col(pId).doc(commentId).delete();
  }
}
