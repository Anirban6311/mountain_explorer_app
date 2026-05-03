import 'package:equatable/equatable.dart';

import '../../../../core/errors/app_error.dart';
import '../../domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class NeedsVerification extends AuthState {
  final AppUser user;
  const NeedsVerification(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthFailure extends AuthState {
  final String message;
  final AppError? error;
  const AuthFailure(this.message, {this.error});
  @override
  List<Object?> get props => [message, error];
}
