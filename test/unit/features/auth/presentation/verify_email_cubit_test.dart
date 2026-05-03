import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/reload_current_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/verify_email_cubit.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/verify_email_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _verified = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'A',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: true,
  providerId: 'password',
);

const _unverified = AppUser(
  uid: 'u',
  email: 'a@b.com',
  displayName: 'A',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: false,
  providerId: 'password',
);

VerifyEmailCubit _buildCubit(_MockAuthRepository repo) => VerifyEmailCubit(
      sendEmailVerification: SendEmailVerification(repo),
      reloadCurrentUser: ReloadCurrentUser(repo),
    );

void main() {
  late _MockAuthRepository repo;
  setUp(() => repo = _MockAuthRepository());

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'resendVerification() emits sending → resent on success',
    build: () {
      when(() => repo.sendEmailVerification())
          .thenAnswer((_) async => const Success<void>(null));
      return _buildCubit(repo);
    },
    act: (c) => c.resendVerification(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.sending),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.resent),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'resendVerification() maps failure to error status',
    build: () {
      when(() => repo.sendEmailVerification()).thenAnswer(
        (_) async => const Failure<void>(AuthError('too-many-requests')),
      );
      return _buildCubit(repo);
    },
    act: (c) => c.resendVerification(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.sending),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'too-many-requests'),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'checkVerified() reloads user; emits verified when user is verified',
    build: () {
      when(() => repo.reloadCurrentUser())
          .thenAnswer((_) async => const Success<AppUser?>(_verified));
      return _buildCubit(repo);
    },
    act: (c) => c.checkVerified(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.checking),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.verified),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'checkVerified() when still unverified emits notVerifiedYet',
    build: () {
      when(() => repo.reloadCurrentUser())
          .thenAnswer((_) async => const Success<AppUser?>(_unverified));
      return _buildCubit(repo);
    },
    act: (c) => c.checkVerified(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.checking),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.notVerifiedYet),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'checkVerified() when user is null emits notVerifiedYet',
    build: () {
      when(() => repo.reloadCurrentUser())
          .thenAnswer((_) async => const Success<AppUser?>(null));
      return _buildCubit(repo);
    },
    act: (c) => c.checkVerified(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.checking),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.notVerifiedYet),
    ],
  );

  blocTest<VerifyEmailCubit, VerifyEmailState>(
    'checkVerified() maps Failure to error status',
    build: () {
      when(() => repo.reloadCurrentUser()).thenAnswer(
        (_) async => const Failure<AppUser?>(NetworkError('offline')),
      );
      return _buildCubit(repo);
    },
    act: (c) => c.checkVerified(),
    expect: () => [
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.checking),
      isA<VerifyEmailState>()
          .having((s) => s.status, 'status', VerifyStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', 'offline'),
    ],
  );
}
