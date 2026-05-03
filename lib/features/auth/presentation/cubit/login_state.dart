import 'package:equatable/equatable.dart';

enum FormStatus { initial, submitting, success, failure }

class LoginState extends Equatable {
  final String email;
  final String password;
  final FormStatus status;
  final String? errorMessage;

  const LoginState({
    this.email = '',
    this.password = '',
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  LoginState copyWith({
    String? email,
    String? password,
    FormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [email, password, status, errorMessage];
}
