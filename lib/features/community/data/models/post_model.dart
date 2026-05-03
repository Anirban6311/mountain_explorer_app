import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/post.dart';

class PostModel extends Post {
  const PostModel({
    required super.pId,
    required super.pTitle,
    required super.pDescription,
    required super.pImage,
    required super.pTime,
    required super.uid,
    required super.uEmail,
    required super.uName,
    required super.likes,
  });

  factory PostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final ts = data['pTime'];
    final when = ts is Timestamp ? ts.toDate() : DateTime.now();
    return PostModel(
      pId: doc.id,
      pTitle: (data['pTitle'] as String?) ?? '',
      pDescription: (data['pDescription'] as String?) ?? '',
      pImage: (data['pImage'] as String?) ?? '',
      pTime: when,
      uid: (data['uid'] as String?) ?? '',
      uEmail: (data['uEmail'] as String?) ?? '',
      uName: (data['uName'] as String?) ?? '',
      likes: ((data['likes'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
