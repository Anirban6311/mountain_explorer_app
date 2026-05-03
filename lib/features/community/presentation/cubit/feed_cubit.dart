import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/community_usecases.dart';

sealed class FeedState extends Equatable {
  const FeedState();
  @override
  List<Object?> get props => const [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<Post> posts;
  const FeedLoaded(this.posts);
  @override
  List<Object?> get props => [posts];
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}

class FeedCubit extends Cubit<FeedState> {
  final WatchFeed _watchFeed;
  final ToggleLikePost _toggleLikePost;
  StreamSubscription<List<Post>>? _sub;

  FeedCubit({
    required WatchFeed watchFeed,
    required ToggleLikePost toggleLikePost,
  })  : _watchFeed = watchFeed,
        _toggleLikePost = toggleLikePost,
        super(const FeedInitial());

  void subscribe() {
    if (_sub != null || isClosed) return;
    emit(const FeedLoading());
    _sub = _watchFeed().listen(
      (posts) {
        if (!isClosed) emit(FeedLoaded(posts));
      },
      onError: (Object e) {
        if (!isClosed) emit(FeedError(e.toString()));
      },
    );
  }

  Future<Result<void>> toggleLike({
    required String postId,
    required String uid,
  }) =>
      _toggleLikePost(pId: postId, uid: uid);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
