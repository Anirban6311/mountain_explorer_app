import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String cId;
  final String text;
  final String commentedBy;
  final String commentedByName;
  final DateTime commentedAt;

  const Comment({
    required this.cId,
    required this.text,
    required this.commentedBy,
    required this.commentedByName,
    required this.commentedAt,
  });

  bool isOwnedBy(String uid) => commentedBy == uid;

  @override
  List<Object?> get props =>
      [cId, text, commentedBy, commentedByName, commentedAt];
}
