import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _ds;
  const AuthRepositoryImpl(this._ds);

  @override
  Stream<AppUser?> watchAuthState() => _ds.watchAuthState();

  @override
  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _run(() => _ds.signInWithEmail(email: email, password: password));

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _run(() => _ds.signUp(
            email: email,
            password: password,
            displayName: displayName,
          ));

  @override
  Future<Result<AppUser>> signInWithGoogle() =>
      _run(() => _ds.signInWithGoogle());

  @override
  Future<Result<AppUser>> signInAnonymously() =>
      _run(() => _ds.signInAnonymously());

  @override
  Future<Result<void>> sendEmailVerification() =>
      _runVoid(() => _ds.sendEmailVerification());

  @override
  Future<Result<void>> resetPassword(String email) =>
      _runVoid(() => _ds.resetPassword(email));

  @override
  Future<Result<void>> signOut() => _runVoid(() => _ds.signOut());

  @override
  Future<Result<AppUser?>> reloadCurrentUser() async {
    try {
      final user = await _ds.reloadCurrentUser();
      return Success<AppUser?>(user);
    } catch (e, st) {
      return Failure<AppUser?>(_mapException(e, st));
    }
  }

  Future<Result<T>> _run<T extends Object>(Future<T> Function() op) async {
    try {
      return Success<T>(await op());
    } catch (e, st) {
      return Failure<T>(_mapException(e, st));
    }
  }

  Future<Result<void>> _runVoid(Future<void> Function() op) async {
    try {
      await op();
      return const Success<void>(null);
    } catch (e, st) {
      return Failure<void>(_mapException(e, st));
    }
  }

  AppError _mapException(Object e, StackTrace st) {
    final logger = getIt.isRegistered<Logger>() ? getIt<Logger>() : null;
    if (e is GoogleSignInCancelledException) {
      return const CancelledError('Sign-in cancelled');
    }
    if (e is FirebaseAuthException) {
      logger?.error(
        'FirebaseAuthException code=${e.code} message=${e.message}',
        error: e,
        stackTrace: st,
      );
      if (e.code == 'network-request-failed') {
        return NetworkError(
          'Please check your internet connection.',
          cause: e,
        );
      }
      return AuthError(_messageForCode(e.code), cause: e);
    }
    logger?.error(
      'Non-Firebase auth exception: ${e.runtimeType}: $e',
      error: e,
      stackTrace: st,
    );
    return UnknownError('Something went wrong. Please try again.', cause: e);
  }

  /// User-facing message per Firebase Auth error code. Avoids leaking
  /// account-existence signals (e.g. distinguishing `user-not-found` from
  /// `wrong-password`) that enable enumeration attacks.
  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return "Couldn't create account. Try signing in instead.";
      case 'weak-password':
        return 'Password must be at least 8 characters with a letter and a number.';
      case 'operation-not-allowed':
      case 'admin-restricted-operation':
        return 'This sign-in method is not enabled in Firebase '
            'Console. Ask an admin to enable it.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not set up for this project. '
            'Enable Identity Platform in Firebase Console.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'account-exists-with-different-credential':
        return 'An account exists with this email using a different sign-in method.';
      case 'no-current-user':
        return 'You need to be signed in first.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
