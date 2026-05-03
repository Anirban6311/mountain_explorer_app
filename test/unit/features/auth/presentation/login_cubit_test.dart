import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/login_cubit.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/login_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'A',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: true,
  providerId: 'password',
);

LoginCubit _buildCubit(_MockAuthRepository repo) => LoginCubit(
      signInWithEmail: SignInWithEmail(repo),
      signInWithGoogle: SignInWithGoogle(repo),
      signInAnonymously: SignInAnonymously(repo),
    );

void main() {
  late _MockAuthRepository repo;
  setUp(() => repo = _MockAuthRepository());

  test('initial state has empty email/password and initial status', () {
    final c = _buildCubit(repo);
    expect(c.state.email, '');
    expect(c.state.password, '');
    expect(c.state.status, FormStatus.initial);
    c.close();
  });

  blocTest<LoginCubit, LoginState>(
    'emailChanged/passwordChanged update state',
    build: () => _buildCubit(repo),
    act: (c) {
      c.emailChanged('a@b.com');
      c.passwordChanged('pw12345a');
    },
    expect: () => [
      isA<LoginState>().having((s) => s.email, 'email', 'a@b.com'),
      isA<LoginState>()
          .having((s) => s.email, 'email', 'a@b.com')
          .having((s) => s.password, 'password', 'pw12345a'),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'submit() with valid input emits submitting → success',
    build: () {
      when(() => repo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Success(_user));
      return _buildCubit(repo);
    },
    seed: () =>
        const LoginState(email: 'a@b.com', password: 'pw12345a'),
    act: (c) => c.submit(),
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.success),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'submit() with empty password emits failure (no repo call)',
    build: () => _buildCubit(repo),
    seed: () => const LoginState(email: 'a@b.com', password: ''),
    act: (c) => c.submit(),
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', contains('password')),
    ],
    verify: (_) => verifyNever(() => repo.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )),
  );

  blocTest<LoginCubit, LoginState>(
    'submit() with invalid email emits failure with validation message',
    build: () => _buildCubit(repo),
    seed: () => const LoginState(email: 'bad', password: 'pw12345a'),
    act: (c) => c.submit(),
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', contains('email')),
    ],
    verify: (_) {
      verifyNever(() => repo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    },
  );

  blocTest<LoginCubit, LoginState>(
    'submit() maps AuthError to failure status',
    build: () {
      when(() => repo.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const Failure(AuthError('wrong creds')),
      );
      return _buildCubit(repo);
    },
    seed: () =>
        const LoginState(email: 'a@b.com', password: 'pw12345a'),
    act: (c) => c.submit(),
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<LoginState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'wrong creds'),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'continueAsGuest() calls SignInAnonymously and emits success',
    build: () {
      when(() => repo.signInAnonymously())
          .thenAnswer((_) async => const Success(_user));
      return _buildCubit(repo);
    },
    act: (c) => c.continueAsGuest(),
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.success),
    ],
    verify: (_) => verify(() => repo.signInAnonymously()).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'signInWithGoogle() emits failure (non-cancellation path)',
    build: () {
      when(() => repo.signInWithGoogle()).thenAnswer(
        (_) async => const Failure(NetworkError('offline')),
      );
      return _buildCubit(repo);
    },
    act: (c) => c.signInWithGoogle(),
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<LoginState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'offline'),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'Google cancellation leaves status=initial (no error shown)',
    build: () {
      when(() => repo.signInWithGoogle()).thenAnswer(
        (_) async => const Failure(CancelledError()),
      );
      return _buildCubit(repo);
    },
    act: (c) => c.signInWithGoogle(),
    expect: () => [
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.submitting),
      isA<LoginState>().having((s) => s.status, 'status', FormStatus.initial),
    ],
  );
}
