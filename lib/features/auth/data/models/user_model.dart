import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.photoUrl,
    required super.isAnonymous,
    required super.isEmailVerified,
    required super.providerId,
  });

  factory UserModel.fromFirebaseUser(User user) {
    // Prefer 'password' whenever the account is linked to email/password —
    // downstream code keys the verification gate on this. Falling back to
    // .first would misclassify linked accounts whose first provider is
    // Google as not needing verification.
    final hasPassword =
        user.providerData.any((p) => p.providerId == 'password');
    final providerId = hasPassword
        ? 'password'
        : user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : (user.isAnonymous ? 'anonymous' : 'unknown');
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      isEmailVerified: user.emailVerified,
      providerId: providerId,
    );
  }
}
