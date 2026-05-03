import '../../../../core/errors/result.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';

abstract class PostsRepository {
  Stream<List<Post>> watchFeed();

  Future<Result<Post>> getPost(String pId);

  Future<Result<Post>> createPost({
    required PostDraft draft,
    required String uid,
    required String uEmail,
    required String uName,
  });

  Future<Result<void>> updatePost({
    required String pId,
    required String uid,
    required String title,
    required String description,
  });

  Future<Result<void>> deletePost({
    required String pId,
    required String uid,
  });

  Future<Result<void>> toggleLikePost({
    required String pId,
    required String uid,
  });
}
