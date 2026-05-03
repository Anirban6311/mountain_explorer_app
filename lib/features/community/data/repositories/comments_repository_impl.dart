import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_remote_data_source.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  final CommentsRemoteDataSource _ds;
  const CommentsRepositoryImpl(this._ds);

  @override
  Stream<List<Comment>> watchComments(String pId) => _ds.watchComments(pId);

  @override
  Future<Result<void>> addComment({
    required String pId,
    required String text,
    required String commentedBy,
    required String commentedByName,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Failure<void>(ValidationError('Comment cannot be empty.'));
    }
    if (trimmed.length > 500) {
      return const Failure<void>(
        ValidationError('Comment must be 500 characters or fewer.'),
      );
    }
    try {
      await _ds.addComment(
        pId: pId,
        text: trimmed,
        commentedBy: commentedBy,
        commentedByName: commentedByName,
      );
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_map(e));
    } catch (e) {
      return Failure<void>(UnknownError('Failed to post comment.', cause: e));
    }
  }

  @override
  Future<Result<void>> deleteComment({
    required String pId,
    required String commentId,
    required String uid,
  }) async {
    try {
      await _ds.deleteComment(pId: pId, commentId: commentId);
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      return Failure<void>(_map(e));
    } catch (e) {
      return Failure<void>(UnknownError('Failed to delete comment.', cause: e));
    }
  }

  AppError _map(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return PermissionError('Not allowed.', cause: e);
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkError('Network unavailable.', cause: e);
      default:
        return UnknownError(e.message ?? e.code, cause: e);
    }
  }
}
