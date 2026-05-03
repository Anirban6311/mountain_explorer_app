import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../utils/auth_validators.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInAnonymously _signInAnonymously;

  LoginCubit({
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignInAnonymously signInAnonymously,
  })  : _signInWithEmail = signInWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signInAnonymously = signInAnonymously,
        super(const LoginState());

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, clearError: true));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, clearError: true));

  Future<void> submit() async {
    final emailError = AuthValidators.validateEmail(state.email);
    if (emailError != null) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: emailError,
      ));
      return;
    }
    if (state.password.isEmpty) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'Please enter your password.',
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _signInWithEmail(
      email: state.email.trim(),
      password: state.password,
    );
    switch (result) {
      case Success():
        emit(state.copyWith(status: FormStatus.success, clearError: true));
      case Failure(:final error):
        emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: error.message,
        ));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _signInWithGoogle();
    switch (result) {
      case Success():
        emit(state.copyWith(status: FormStatus.success, clearError: true));
      case Failure(:final error):
        if (error is CancelledError) {
          emit(state.copyWith(status: FormStatus.initial, clearError: true));
          return;
        }
        emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: error.message,
        ));
    }
  }

  Future<void> continueAsGuest() async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _signInAnonymously();
    switch (result) {
      case Success():
        emit(state.copyWith(status: FormStatus.success, clearError: true));
      case Failure(:final error):
        emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: error.message,
        ));
    }
  }
}
