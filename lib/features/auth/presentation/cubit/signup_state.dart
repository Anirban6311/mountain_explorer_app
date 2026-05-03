import 'package:equatable/equatable.dart';

import 'login_state.dart';

class SignupState extends Equatable {
  final String name;
  final String email;
  final String password;
  final FormStatus status;
  final String? errorMessage;

  const SignupState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.status = FormStatus.initial,
    this.errorMessage,
  });

  SignupState copyWith({
    String? name,
    String? email,
    String? password,
    FormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignupState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [name, email, password, status, errorMessage];
}
