import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/usecases/community_usecases.dart';

enum CreatePostStatus { initial, submitting, success, failure }

class CreatePostState extends Equatable {
  final PostDraft draft;
  final CreatePostStatus status;
  final String? errorMessage;
  final Post? created;

  const CreatePostState({
    this.draft = const PostDraft(),
    this.status = CreatePostStatus.initial,
    this.errorMessage,
    this.created,
  });

  CreatePostState copyWith({
    PostDraft? draft,
    CreatePostStatus? status,
    String? errorMessage,
    Post? created,
    bool clearError = false,
  }) {
    return CreatePostState(
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      created: created ?? this.created,
    );
  }

  @override
  List<Object?> get props => [draft, status, errorMessage, created];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  final CreatePost _createPost;

  CreatePostCubit({required CreatePost createPost})
      : _createPost = createPost,
        super(const CreatePostState());

  void titleChanged(String v) =>
      emit(state.copyWith(draft: state.draft.copyWith(title: v), clearError: true));
  void descriptionChanged(String v) => emit(state.copyWith(
        draft: state.draft.copyWith(description: v),
        clearError: true,
      ));
  void imageChanged(String? path) => emit(state.copyWith(
        draft: state.draft.copyWith(imagePath: path),
        clearError: true,
      ));

  Future<void> submit({
    required String uid,
    required String uEmail,
    required String uName,
  }) async {
    final validation = state.draft.validate();
    if (validation != null) {
      emit(state.copyWith(
        status: CreatePostStatus.failure,
        errorMessage: validation,
      ));
      return;
    }
    emit(state.copyWith(status: CreatePostStatus.submitting, clearError: true));
    final result = await _createPost(
      draft: state.draft,
      uid: uid,
      uEmail: uEmail,
      uName: uName,
    );
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(
          status: CreatePostStatus.success,
          created: value,
          clearError: true,
        ));
      case Failure(:final error):
        emit(state.copyWith(
          status: CreatePostStatus.failure,
          errorMessage: error.message,
        ));
    }
  }
}
