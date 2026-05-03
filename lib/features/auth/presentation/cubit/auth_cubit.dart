import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_state.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final WatchAuthState _watch;
  final SignOut _signOut;
  StreamSubscription<AppUser?>? _sub;

  AuthCubit({
    required WatchAuthState watchAuthState,
    required SignOut signOutUseCase,
  })  : _watch = watchAuthState,
        _signOut = signOutUseCase,
        super(const AuthInitial());

  void bootstrap() {
    if (_sub != null || isClosed) return;
    emit(const AuthLoading());
    _sub = _watch().listen(_onUser);
  }

  void _onUser(AppUser? user) {
    if (isClosed) return;
    if (user == null) {
      emit(const Unauthenticated());
      return;
    }
    final requiresVerification = !user.isAnonymous &&
        user.providerId == 'password' &&
        !user.isEmailVerified;
    emit(requiresVerification
        ? NeedsVerification(user)
        : Authenticated(user));
  }

  Future<void> signOut() async {
    final result = await _signOut();
    switch (result) {
      case Success<void>():
        break;
      case Failure<void>(:final error):
        emit(AuthFailure(error.message, error: error));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
