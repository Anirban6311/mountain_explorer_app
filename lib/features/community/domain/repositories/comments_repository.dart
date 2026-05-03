import '../../../../core/errors/result.dart';
import '../entities/comment.dart';

abstract class CommentsRepository {
  Stream<List<Comment>> watchComments(String pId);

  Future<Result<void>> addComment({
    required String pId,
    required String text,
    required String commentedBy,
    required String commentedByName,
  });

  Future<Result<void>> deleteComment({
    required String pId,
    required String commentId,
    required String uid,
  });
}
