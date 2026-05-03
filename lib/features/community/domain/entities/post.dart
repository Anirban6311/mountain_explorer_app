import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String pId;
  final String pTitle;
  final String pDescription;
  final String pImage;
  final DateTime pTime;
  final String uid;
  final String uEmail;
  final String uName;
  final List<String> likes;

  const Post({
    required this.pId,
    required this.pTitle,
    required this.pDescription,
    required this.pImage,
    required this.pTime,
    required this.uid,
    required this.uEmail,
    required this.uName,
    required this.likes,
  });

  bool likedBy(String uid) => likes.contains(uid);
  bool isOwnedBy(String uid) => this.uid == uid;

  @override
  List<Object?> get props =>
      [pId, pTitle, pDescription, pImage, pTime, uid, uEmail, uName, likes];
}
