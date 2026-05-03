import '../../../../core/errors/result.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<AppUser>> signInWithGoogle();

  Future<Result<AppUser>> signInAnonymously();

  Future<Result<void>> sendEmailVerification();

  Future<Result<void>> resetPassword(String email);

  Future<Result<void>> signOut();

  Future<Result<AppUser?>> reloadCurrentUser();
}
