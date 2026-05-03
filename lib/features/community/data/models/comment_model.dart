import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.cId,
    required super.text,
    required super.commentedBy,
    required super.commentedByName,
    required super.commentedAt,
  });

  factory CommentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final ts = data['commentedAt'];
    return CommentModel(
      cId: doc.id,
      text: (data['text'] as String?) ?? '',
      commentedBy: (data['commentedBy'] as String?) ?? '',
      commentedByName: (data['commentedByName'] as String?) ?? '',
      commentedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
