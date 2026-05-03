import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SignUp usecase;

  const user = AppUser(
    uid: 'u1',
    email: 'a@b.com',
    displayName: 'Ada',
    photoUrl: null,
    isAnonymous: false,
    isEmailVerified: false,
    providerId: 'password',
  );

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SignUp(repo);
  });

  test('delegates to repo.signUp and returns Success', () async {
    when(() => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => const Success(user));

    final result = await usecase(
      email: 'a@b.com',
      password: 'pw12345a',
      displayName: 'Ada',
    );

    expect(result, isA<Success<AppUser>>());
    verify(() => repo.signUp(
          email: 'a@b.com',
          password: 'pw12345a',
          displayName: 'Ada',
        )).called(1);
  });

  test('propagates Failure', () async {
    const err = AuthError('email-already-in-use');
    when(() => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => const Failure(err));

    final result = await usecase(
      email: 'a@b.com',
      password: 'pw12345a',
      displayName: 'Ada',
    );

    expect(result, isA<Failure<AppUser>>());
    expect((result as Failure<AppUser>).error, same(err));
  });
}
