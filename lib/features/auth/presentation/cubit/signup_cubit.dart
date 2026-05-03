import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/usecases/sign_up.dart';
import '../utils/auth_validators.dart';
import 'login_state.dart';
import 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final SignUp _signUp;

  SignupCubit({required SignUp signUp})
      : _signUp = signUp,
        super(const SignupState());

  void nameChanged(String value) =>
      emit(state.copyWith(name: value, clearError: true));

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, clearError: true));

  void passwordChanged(String value) =>
      emit(state.copyWith(password: value, clearError: true));

  Future<void> submit() async {
    final nameError = AuthValidators.validateDisplayName(state.name);
    if (nameError != null) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: nameError,
      ));
      return;
    }
    final emailError = AuthValidators.validateEmail(state.email);
    if (emailError != null) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: emailError,
      ));
      return;
    }
    final passwordError = AuthValidators.validatePassword(state.password);
    if (passwordError != null) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: passwordError,
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _signUp(
      email: state.email.trim(),
      password: state.password,
      displayName: state.name.trim(),
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
}
