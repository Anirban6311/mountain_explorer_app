import 'package:equatable/equatable.dart';

enum VerifyStatus {
  idle,
  sending,
  resent,
  checking,
  verified,
  notVerifiedYet,
  error,
}

class VerifyEmailState extends Equatable {
  final VerifyStatus status;
  final String? errorMessage;

  const VerifyEmailState({
    this.status = VerifyStatus.idle,
    this.errorMessage,
  });

  VerifyEmailState copyWith({
    VerifyStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VerifyEmailState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
