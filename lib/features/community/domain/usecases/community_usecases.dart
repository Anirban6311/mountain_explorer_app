import '../../../../core/errors/result.dart';
import '../entities/comment.dart';
import '../entities/post.dart';
import '../entities/post_draft.dart';
import '../repositories/comments_repository.dart';
import '../repositories/posts_repository.dart';

class WatchFeed {
  final PostsRepository _repo;
  const WatchFeed(this._repo);
  Stream<List<Post>> call() => _repo.watchFeed();
}

class GetPost {
  final PostsRepository _repo;
  const GetPost(this._repo);
  Future<Result<Post>> call(String pId) => _repo.getPost(pId);
}

class CreatePost {
  final PostsRepository _repo;
  const CreatePost(this._repo);

  Future<Result<Post>> call({
    required PostDraft draft,
    required String uid,
    required String uEmail,
    required String uName,
  }) =>
      _repo.createPost(
        draft: draft,
        uid: uid,
        uEmail: uEmail,
        uName: uName,
      );
}

class UpdatePost {
  final PostsRepository _repo;
  const UpdatePost(this._repo);

  Future<Result<void>> call({
    required String pId,
    required String uid,
    required String title,
    required String description,
  }) =>
      _repo.updatePost(
        pId: pId,
        uid: uid,
        title: title,
        description: description,
      );
}

class DeletePost {
  final PostsRepository _repo;
  const DeletePost(this._repo);
  Future<Result<void>> call({required String pId, required String uid}) =>
      _repo.deletePost(pId: pId, uid: uid);
}

class ToggleLikePost {
  final PostsRepository _repo;
  const ToggleLikePost(this._repo);
  Future<Result<void>> call({required String pId, required String uid}) =>
      _repo.toggleLikePost(pId: pId, uid: uid);
}

class WatchComments {
  final CommentsRepository _repo;
  const WatchComments(this._repo);
  Stream<List<Comment>> call(String pId) => _repo.watchComments(pId);
}

class AddComment {
  final CommentsRepository _repo;
  const AddComment(this._repo);

  Future<Result<void>> call({
    required String pId,
    required String text,
    required String commentedBy,
    required String commentedByName,
  }) =>
      _repo.addComment(
        pId: pId,
        text: text,
        commentedBy: commentedBy,
        commentedByName: commentedByName,
      );
}

class DeleteComment {
  final CommentsRepository _repo;
  const DeleteComment(this._repo);
  Future<Result<void>> call({
    required String pId,
    required String commentId,
    required String uid,
  }) =>
      _repo.deleteComment(pId: pId, commentId: commentId, uid: uid);
}
