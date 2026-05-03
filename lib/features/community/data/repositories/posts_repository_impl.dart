import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/repositories/post_image_storage_repository.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_remote_data_source.dart';

class PostsRepositoryImpl implements PostsRepository {
  final PostsRemoteDataSource _posts;
  final PostImageStorageRepository _storage;

  const PostsRepositoryImpl({
    required PostsRemoteDataSource posts,
    required PostImageStorageRepository storage,
  })  : _posts = posts,
        _storage = storage;

  @override
  Stream<List<Post>> watchFeed() => _posts.watchFeed();

  @override
  Future<Result<Post>> getPost(String pId) async {
    try {
      final post = await _posts.getPost(pId);
      if (post == null) {
        return const Failure<Post>(NotFoundError('Post not found.'));
      }
      return Success<Post>(post);
    } on FirebaseException catch (e) {
      return Failure<Post>(_mapFirebase(e));
    } catch (e) {
      return Failure<Post>(UnknownError('Failed to load post.', cause: e));
    }
  }

  @override
  Future<Result<Post>> createPost({
    required PostDraft draft,
    required String uid,
    required String uEmail,
    required String uName,
  }) async {
    final validationError = draft.validate();
    if (validationError != null) {
      return Failure<Post>(ValidationError(validationError));
    }
    final uploadResult = await _storage.uploadPostImage(
      uid: uid,
      imagePath: draft.imagePath!,
    );
    switch (uploadResult) {
      case Failure(:final error):
        return Failure<Post>(error);
      case Success(:final value):
        return _createPostDoc(
          draft: draft,
          uid: uid,
          uEmail: uEmail,
          uName: uName,
          imageUrl: value,
        );
    }
  }

  Future<Result<Post>> _createPostDoc({
    required PostDraft draft,
    required String uid,
    required String uEmail,
    required String uName,
    required String imageUrl,
  }) async {
    try {
      final post = await _posts.createPost(
        pTitle: draft.title.trim(),
        pDescription: draft.description.trim(),
        pImage: imageUrl,
        uid: uid,
        uEmail: uEmail,
        uName: uName,
      );
      return Success<Post>(post);
    } on FirebaseException catch (e) {
      // Firestore write failed — the image is now orphaned in Storage.
      // Best-effort cleanup; never surface a secondary error to the user.
      unawaited(_storage.deleteByUrl(imageUrl));
      return Failure<Post>(_mapFirebase(e));
    } catch (e) {
      unawaited(_storage.deleteByUrl(imageUrl));
      return Failure<Post>(UnknownError('Failed to publish post.', cause: e));
    }
  }

  @override
  Future<Result<void>> updatePost({
    required String pId,
    required String uid,
    required String title,
    required String description,
  }) =>
      _runVoid(() => _posts.updatePost(
            pId: pId,
            title: title.trim(),
            description: description.trim(),
          ));

  @override
  Future<Result<void>> deletePost({
    required String pId,
    required String uid,
  }) =>
      _runVoid(() => _posts.deletePost(pId));

  @override
  Future<Result<void>> toggleLikePost({
    required String pId,
    required String uid,
  }) =>
      _runVoid(() => _posts.toggleLikePost(pId: pId, uid: uid));

  Future<Result<void>> _runVoid(Future<void> Function() op) async {
    try {
      await op();
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_mapFirebase(e));
    } catch (e) {
      return Failure<void>(UnknownError('Operation failed.', cause: e));
    }
  }

  AppError _mapFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return PermissionError('Not allowed.', cause: e);
      case 'not-found':
        return NotFoundError('Post not found.', cause: e);
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkError('Network unavailable.', cause: e);
      default:
        return UnknownError(e.message ?? e.code, cause: e);
    }
  }
}
