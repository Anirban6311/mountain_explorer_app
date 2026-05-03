import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:basic_crud_flutter/features/auth/presentation/cubit/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _verifiedUser = AppUser(
  uid: 'u1',
  email: 'a@b.com',
  displayName: 'Ada',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: true,
  providerId: 'password',
);

const _unverifiedUser = AppUser(
  uid: 'u2',
  email: 'unv@b.com',
  displayName: 'Unv',
  photoUrl: null,
  isAnonymous: false,
  isEmailVerified: false,
  providerId: 'password',
);

const _anonUser = AppUser(
  uid: 'anon',
  email: null,
  displayName: null,
  photoUrl: null,
  isAnonymous: true,
  isEmailVerified: false,
  providerId: 'anonymous',
);

void main() {
  late _MockAuthRepository repo;
  late WatchAuthState watch;
  late SignOut signOut;
  late StreamController<AppUser?> controller;

  setUp(() {
    repo = _MockAuthRepository();
    watch = WatchAuthState(repo);
    signOut = SignOut(repo);
    controller = StreamController<AppUser?>.broadcast();
    when(() => repo.watchAuthState()).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  blocTest<AuthCubit, AuthState>(
    'emits Authenticated for verified user',
    build: () => AuthCubit(watchAuthState: watch, signOutUseCase: signOut),
    act: (c) async {
      c.bootstrap();
      controller.add(_verifiedUser);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const AuthLoading(),
      const Authenticated(_verifiedUser),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'emits NeedsVerification for unverified email/password user',
    build: () => AuthCubit(watchAuthState: watch, signOutUseCase: signOut),
    act: (c) async {
      c.bootstrap();
      controller.add(_unverifiedUser);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const AuthLoading(),
      const NeedsVerification(_unverifiedUser),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'emits Authenticated for anonymous user (no verification required)',
    build: () => AuthCubit(watchAuthState: watch, signOutUseCase: signOut),
    act: (c) async {
      c.bootstrap();
      controller.add(_anonUser);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const AuthLoading(),
      const Authenticated(_anonUser),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'emits Unauthenticated when stream emits null',
    build: () => AuthCubit(watchAuthState: watch, signOutUseCase: signOut),
    act: (c) async {
      c.bootstrap();
      controller.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const AuthLoading(),
      const Unauthenticated(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'signOut() + stream emitting null drives Unauthenticated',
    build: () {
      when(() => repo.signOut())
          .thenAnswer((_) async => const Success<void>(null));
      return AuthCubit(watchAuthState: watch, signOutUseCase: signOut);
    },
    act: (c) async {
      c.bootstrap();
      controller.add(_verifiedUser);
      await Future<void>.delayed(Duration.zero);
      await c.signOut();
      controller.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      const AuthLoading(),
      const Authenticated(_verifiedUser),
      const Unauthenticated(),
    ],
    verify: (_) => verify(() => repo.signOut()).called(1),
  );

  blocTest<AuthCubit, AuthState>(
    'signOut() emits AuthFailure when repo returns Failure',
    build: () {
      when(() => repo.signOut()).thenAnswer(
        (_) async => const Failure<void>(UnknownError('fail')),
      );
      return AuthCubit(watchAuthState: watch, signOutUseCase: signOut);
    },
    act: (c) async {
      c.bootstrap();
      controller.add(_verifiedUser);
      await Future<void>.delayed(Duration.zero);
      await c.signOut();
    },
    expect: () => [
      const AuthLoading(),
      const Authenticated(_verifiedUser),
      isA<AuthFailure>(),
    ],
  );
}
