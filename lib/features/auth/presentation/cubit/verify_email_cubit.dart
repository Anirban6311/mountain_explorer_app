import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/usecases/reload_current_user.dart';
import '../../domain/usecases/send_email_verification.dart';
import 'verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  final SendEmailVerification _sendEmailVerification;
  final ReloadCurrentUser _reloadCurrentUser;

  VerifyEmailCubit({
    required SendEmailVerification sendEmailVerification,
    required ReloadCurrentUser reloadCurrentUser,
  })  : _sendEmailVerification = sendEmailVerification,
        _reloadCurrentUser = reloadCurrentUser,
        super(const VerifyEmailState());

  Future<void> resendVerification() async {
    emit(state.copyWith(status: VerifyStatus.sending, clearError: true));
    final result = await _sendEmailVerification();
    switch (result) {
      case Success():
        emit(state.copyWith(status: VerifyStatus.resent, clearError: true));
      case Failure(:final error):
        emit(state.copyWith(
          status: VerifyStatus.error,
          errorMessage: error.message,
        ));
    }
  }

  Future<void> checkVerified() async {
    emit(state.copyWith(status: VerifyStatus.checking, clearError: true));
    final result = await _reloadCurrentUser();
    switch (result) {
      case Success(:final value):
        if (value != null && value.isEmailVerified) {
          emit(state.copyWith(status: VerifyStatus.verified, clearError: true));
        } else {
          emit(state.copyWith(
            status: VerifyStatus.notVerifiedYet,
            clearError: true,
          ));
        }
      case Failure(:final error):
        emit(state.copyWith(
          status: VerifyStatus.error,
          errorMessage: error.message,
        ));
    }
  }
}
