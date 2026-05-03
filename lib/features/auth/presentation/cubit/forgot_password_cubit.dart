import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/usecases/reset_password.dart';
import '../utils/auth_validators.dart';
import 'forgot_password_state.dart';
import 'login_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ResetPassword _resetPassword;

  ForgotPasswordCubit({required ResetPassword resetPassword})
      : _resetPassword = resetPassword,
        super(const ForgotPasswordState());

  void emailChanged(String value) =>
      emit(state.copyWith(email: value, clearError: true));

  Future<void> submit() async {
    final emailError = AuthValidators.validateEmail(state.email);
    if (emailError != null) {
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: emailError,
      ));
      return;
    }

    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    final result = await _resetPassword(state.email.trim());
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
