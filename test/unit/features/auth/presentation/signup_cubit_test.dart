import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/login_state.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/signup_cubit.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/signup_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'Ada',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: false,
  providerId: 'password',
);

SignupCubit _buildCubit(_MockAuthRepository repo) =>
    SignupCubit(signUp: SignUp(repo));

void main() {
  late _MockAuthRepository repo;
  setUp(() => repo = _MockAuthRepository());

  test('initial state has empty fields', () {
    final c = _buildCubit(repo);
    expect(c.state.status, FormStatus.initial);
    expect(c.state.name, '');
    c.close();
  });

  blocTest<SignupCubit, SignupState>(
    'submit() with valid input emits submitting → success',
    build: () {
      when(() => repo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => const Success(_user));
      return _buildCubit(repo);
    },
    seed: () => const SignupState(
      name: 'Ada',
      email: 'a@b.com',
      password: 'pw12345a',
    ),
    act: (c) => c.submit(),
    expect: () => [
      isA<SignupState>()
          .having((s) => s.status, 'status', FormStatus.submitting),
      isA<SignupState>().having((s) => s.status, 'status', FormStatus.success),
    ],
  );

  blocTest<SignupCubit, SignupState>(
    'submit() with weak password emits failure (no repo call)',
    build: () => _buildCubit(repo),
    seed: () => const SignupState(
      name: 'Ada',
      email: 'a@b.com',
      password: 'short',
    ),
    act: (c) => c.submit(),
    expect: () => [
      isA<SignupState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', contains('Password')),
    ],
    verify: (_) => verifyNever(() => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )),
  );

  blocTest<SignupCubit, SignupState>(
    'submit() with empty name emits failure',
    build: () => _buildCubit(repo),
    seed: () => const SignupState(
      name: '',
      email: 'a@b.com',
      password: 'pw12345a',
    ),
    act: (c) => c.submit(),
    expect: () => [
      isA<SignupState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', contains('name')),
    ],
  );

  blocTest<SignupCubit, SignupState>(
    'submit() maps AuthError to failure',
    build: () {
      when(() => repo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer(
        (_) async => const Failure(AuthError('email-already-in-use')),
      );
      return _buildCubit(repo);
    },
    seed: () => const SignupState(
      name: 'Ada',
      email: 'a@b.com',
      password: 'pw12345a',
    ),
    act: (c) => c.submit(),
    expect: () => [
      isA<SignupState>()
          .having((s) => s.status, 'status', FormStatus.submitting),
      isA<SignupState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'email-already-in-use'),
    ],
  );
}
