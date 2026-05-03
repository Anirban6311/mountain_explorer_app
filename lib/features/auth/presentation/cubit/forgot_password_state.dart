import 'package:equatable/equatable.dart';

import 'login_state.dart';

class ForgotPasswordState extends Equatable {
  final String email;
  final FormStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.email = '',
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    String? email,
    FormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [email, status, errorMessage];
}
