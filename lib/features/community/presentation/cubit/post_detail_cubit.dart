import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/community_usecases.dart';

class PostDetailState extends Equatable {
  final Post? post;
  final List<Comment> comments;
  final bool loading;
  final String? errorMessage;
  final bool submittingComment;

  const PostDetailState({
    this.post,
    this.comments = const [],
    this.loading = true,
    this.errorMessage,
    this.submittingComment = false,
  });

  PostDetailState copyWith({
    Post? post,
    List<Comment>? comments,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
    bool? submittingComment,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittingComment: submittingComment ?? this.submittingComment,
    );
  }

  @override
  List<Object?> get props =>
      [post, comments, loading, errorMessage, submittingComment];
}

class PostDetailCubit extends Cubit<PostDetailState> {
  final String postId;
  final GetPost _getPost;
  final WatchComments _watchComments;
  final AddComment _addComment;
  final DeleteComment _deleteComment;
  final DeletePost _deletePost;
  final ToggleLikePost _toggleLikePost;

  StreamSubscription<List<Comment>>? _commentsSub;

  PostDetailCubit({
    required this.postId,
    required GetPost getPost,
    required WatchComments watchComments,
    required AddComment addComment,
    required DeleteComment deleteComment,
    required DeletePost deletePost,
    required ToggleLikePost toggleLikePost,
  })  : _getPost = getPost,
        _watchComments = watchComments,
        _addComment = addComment,
        _deleteComment = deleteComment,
        _deletePost = deletePost,
        _toggleLikePost = toggleLikePost,
        super(const PostDetailState());

  Future<void> load() async {
    if (isClosed) return;
    final result = await _getPost(postId);
    if (isClosed) return;
    switch (result) {
      case Failure(:final error):
        emit(state.copyWith(loading: false, errorMessage: error.message));
      case Success(:final value):
        emit(state.copyWith(post: value, loading: false, clearError: true));
        _subscribeComments();
    }
  }

  void _subscribeComments() {
    _commentsSub?.cancel();
    _commentsSub = _watchComments(postId).listen(
      (list) {
        if (!isClosed) emit(state.copyWith(comments: list));
      },
      onError: (Object e) {
        if (!isClosed) {
          emit(state.copyWith(errorMessage: e.toString()));
        }
      },
    );
  }

  Future<void> toggleLike(String uid) async {
    await _toggleLikePost(pId: postId, uid: uid);
  }

  Future<Result<void>> submitComment({
    required String text,
    required String uid,
    required String name,
  }) async {
    emit(state.copyWith(submittingComment: true, clearError: true));
    final result = await _addComment(
      pId: postId,
      text: text,
      commentedBy: uid,
      commentedByName: name,
    );
    if (isClosed) return result;
    switch (result) {
      case Success():
        emit(state.copyWith(submittingComment: false, clearError: true));
      case Failure(:final error):
        emit(state.copyWith(
          submittingComment: false,
          errorMessage: error.message,
        ));
    }
    return result;
  }

  Future<Result<void>> deleteComment(String commentId, String uid) {
    return _deleteComment(pId: postId, commentId: commentId, uid: uid);
  }

  Future<Result<void>> deletePost(String uid) {
    return _deletePost(pId: postId, uid: uid);
  }

  @override
  Future<void> close() async {
    await _commentsSub?.cancel();
    return super.close();
  }
}
