import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SignInWithEmail usecase;

  const user = AppUser(
    uid: 'u1',
    email: 'a@b.com',
    displayName: 'A',
    photoUrl: null,
    isAnonymous: false,
    isEmailVerified: true,
    providerId: 'password',
  );

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SignInWithEmail(repo);
  });

  test('delegates to repo and returns Success', () async {
    when(() => repo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Success(user));

    final result = await usecase(email: 'a@b.com', password: 'pw12345a');

    expect(result, isA<Success<AppUser>>());
    expect((result as Success<AppUser>).value, user);
    verify(() => repo.signInWithEmail(email: 'a@b.com', password: 'pw12345a'))
        .called(1);
  });

  test('propagates Failure from repo unchanged', () async {
    const err = AuthError('wrong password');
    when(() => repo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Failure(err));

    final result = await usecase(email: 'a@b.com', password: 'x');

    expect(result, isA<Failure<AppUser>>());
    expect((result as Failure<AppUser>).error, same(err));
  });
}
