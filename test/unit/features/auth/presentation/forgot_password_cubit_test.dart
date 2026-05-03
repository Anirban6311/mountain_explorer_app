import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/reset_password.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/forgot_password_state.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/login_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

ForgotPasswordCubit _buildCubit(_MockAuthRepository repo) =>
    ForgotPasswordCubit(resetPassword: ResetPassword(repo));

void main() {
  late _MockAuthRepository repo;
  setUp(() => repo = _MockAuthRepository());

  blocTest<ForgotPasswordCubit, ForgotPasswordState>(
    'submit() with empty email emits failure (no repo call)',
    build: () => _buildCubit(repo),
    act: (c) => c.submit(),
    expect: () => [
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', contains('email')),
    ],
    verify: (_) => verifyNever(() => repo.resetPassword(any())),
  );

  blocTest<ForgotPasswordCubit, ForgotPasswordState>(
    'submit() with invalid email emits failure',
    build: () => _buildCubit(repo),
    seed: () => const ForgotPasswordState(email: 'nope'),
    act: (c) => c.submit(),
    expect: () => [
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.failure),
    ],
    verify: (_) => verifyNever(() => repo.resetPassword(any())),
  );

  blocTest<ForgotPasswordCubit, ForgotPasswordState>(
    'submit() with valid email emits submitting → success',
    build: () {
      when(() => repo.resetPassword(any()))
          .thenAnswer((_) async => const Success<void>(null));
      return _buildCubit(repo);
    },
    seed: () => const ForgotPasswordState(email: 'a@b.com'),
    act: (c) => c.submit(),
    expect: () => [
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.submitting),
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.success),
    ],
    verify: (_) => verify(() => repo.resetPassword('a@b.com')).called(1),
  );

  blocTest<ForgotPasswordCubit, ForgotPasswordState>(
    'submit() maps NetworkError to failure',
    build: () {
      when(() => repo.resetPassword(any())).thenAnswer(
        (_) async => const Failure<void>(NetworkError('offline')),
      );
      return _buildCubit(repo);
    },
    seed: () => const ForgotPasswordState(email: 'a@b.com'),
    act: (c) => c.submit(),
    expect: () => [
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.submitting),
      isA<ForgotPasswordState>()
          .having((s) => s.status, 'status', FormStatus.failure)
          .having((s) => s.errorMessage, 'errorMessage', 'offline'),
    ],
  );
}
