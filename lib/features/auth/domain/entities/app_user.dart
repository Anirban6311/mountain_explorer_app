import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool isEmailVerified;
  final String providerId;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
    required this.isEmailVerified,
    required this.providerId,
  });

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoUrl,
        isAnonymous,
        isEmailVerified,
        providerId,
      ];
}
