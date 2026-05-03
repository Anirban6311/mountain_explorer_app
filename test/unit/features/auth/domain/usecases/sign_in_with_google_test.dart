import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SignInWithGoogle usecase;

  const user = AppUser(
    uid: 'g1',
    email: 'g@b.com',
    displayName: 'G',
    photoUrl: null,
    isAnonymous: false,
    isEmailVerified: true,
    providerId: 'google.com',
  );

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SignInWithGoogle(repo);
  });

  test('delegates to repo and returns Success', () async {
    when(() => repo.signInWithGoogle())
        .thenAnswer((_) async => const Success(user));
    final result = await usecase();
    expect(result, isA<Success<AppUser>>());
    verify(() => repo.signInWithGoogle()).called(1);
  });

  test('propagates cancellation as Failure', () async {
    const err = AuthError('Sign-in cancelled');
    when(() => repo.signInWithGoogle())
        .thenAnswer((_) async => const Failure(err));
    final result = await usecase();
    expect((result as Failure<AppUser>).error, same(err));
  });
}
