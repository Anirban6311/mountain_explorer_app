import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

/// Thrown when the Google sign-in flow was cancelled by the user.
class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
  @override
  String toString() => 'GoogleSignInCancelledException';
}

abstract class AuthRemoteDataSource {
  Stream<UserModel?> watchAuthState();

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel> signInWithGoogle();

  Future<UserModel> signInAnonymously();

  Future<void> sendEmailVerification();

  Future<void> resetPassword(String email);

  Future<void> signOut();

  Future<UserModel?> reloadCurrentUser();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  FirebaseAuthRemoteDataSource({
    required FirebaseAuth auth,
    required GoogleSignIn google,
  })  : _auth = auth,
        _google = google;

  @override
  Stream<UserModel?> watchAuthState() => _auth
      .authStateChanges()
      .map((u) => u == null ? null : UserModel.fromFirebaseUser(u));

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebaseUser(cred.user!);
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    // Best-effort profile + verification email. A failure here (rate limit,
    // transient network) must not orphan the newly created account — the
    // user can resend verification from VerifyEmailPage.
    try {
      await user.updateDisplayName(displayName);
    } catch (_) {}
    try {
      await user.sendEmailVerification();
    } catch (_) {}
    try {
      await user.reload();
    } catch (_) {}
    return UserModel.fromFirebaseUser(_auth.currentUser ?? user);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) {
      throw const GoogleSignInCancelledException();
    }
    final auth = await account.authentication;
    if (auth.idToken == null) {
      // Happens when `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` isn't set (Android)
      // or when the Firebase project has no registered OAuth client /
      // SHA-1 fingerprint. Firebase will reject a null idToken with a
      // cryptic `invalid-credential`; surface the real cause instead.
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Google sign-in is not configured. Add the OAuth 2.0 '
            'Web client ID to GOOGLE_SIGN_IN_SERVER_CLIENT_ID in .env and '
            'register the debug SHA-1 in Firebase Console.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return UserModel.fromFirebaseUser(cred.user!);
  }

  @override
  Future<UserModel> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return UserModel.fromFirebaseUser(cred.user!);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await user.sendEmailVerification();
  }

  @override
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserModel?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    final refreshed = _auth.currentUser;
    return refreshed == null ? null : UserModel.fromFirebaseUser(refreshed);
  }
}
