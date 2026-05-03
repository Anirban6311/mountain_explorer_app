import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_draft.dart';
import '../../domain/usecases/community_usecases.dart';

enum EditPostStatus { initial, submitting, success, failure }

class EditPostState extends Equatable {
  final String title;
  final String description;
  final EditPostStatus status;
  final String? errorMessage;

  const EditPostState({
    this.title = '',
    this.description = '',
    this.status = EditPostStatus.initial,
    this.errorMessage,
  });

  EditPostState copyWith({
    String? title,
    String? description,
    EditPostStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditPostState(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [title, description, status, errorMessage];
}

class EditPostCubit extends Cubit<EditPostState> {
  final String pId;
  final UpdatePost _updatePost;

  EditPostCubit({required this.pId, required UpdatePost updatePost})
      : _updatePost = updatePost,
        super(const EditPostState());

  void seedFrom(Post post) {
    emit(EditPostState(title: post.pTitle, description: post.pDescription));
  }

  void titleChanged(String v) =>
      emit(state.copyWith(title: v, clearError: true));
  void descriptionChanged(String v) =>
      emit(state.copyWith(description: v, clearError: true));

  Future<void> submit(String uid) async {
    final draft = PostDraft(title: state.title, description: state.description);
    final validation = draft.validate(requireImage: false);
    if (validation != null) {
      emit(state.copyWith(
        status: EditPostStatus.failure,
        errorMessage: validation,
      ));
      return;
    }
    emit(state.copyWith(status: EditPostStatus.submitting, clearError: true));
    final result = await _updatePost(
      pId: pId,
      uid: uid,
      title: state.title,
      description: state.description,
    );
    switch (result) {
      case Success():
        emit(state.copyWith(status: EditPostStatus.success, clearError: true));
      case Failure(:final error):
        emit(state.copyWith(
          status: EditPostStatus.failure,
          errorMessage: error.message,
        ));
    }
  }
}
