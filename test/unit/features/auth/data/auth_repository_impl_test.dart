import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:basic_crud_flutter/features/auth/data/models/user_model.dart';
import 'package:basic_crud_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AuthRemoteDataSource {}

UserModel _sampleUser() => const UserModel(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Ada',
      photoUrl: null,
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'password',
    );

void main() {
  late _MockDataSource ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  group('signInWithEmail', () {
    test('returns Success on data-source success', () async {
      final user = _sampleUser();
      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => user);

      final result =
          await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      expect(result, isA<Success<AppUser>>());
      expect((result as Success<AppUser>).value, user);
    });

    test('maps network-request-failed to NetworkError', () async {
      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result =
          await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<NetworkError>());
    });

    test('maps invalid-credential to AuthError', () async {
      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(
            code: 'invalid-credential',
            message: 'bad creds',
          ));

      final result =
          await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      expect((result as Failure).error, isA<AuthError>());
    });

    test('maps unknown exception to UnknownError with cause preserved',
        () async {
      final cause = StateError('weird');
      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(cause);

      final result =
          await repo.signInWithEmail(email: 'a@b.com', password: 'pw');

      final err = (result as Failure).error as UnknownError;
      expect(err.cause, same(cause));
    });

    test('does not leak account-existence between user-not-found '
        'and wrong-password', () async {
      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'user-not-found'));
      final notFound = await repo.signInWithEmail(email: 'a@b.com', password: 'x');

      when(() => ds.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));
      final wrongPw = await repo.signInWithEmail(email: 'a@b.com', password: 'x');

      expect(
        (notFound as Failure).error.message,
        (wrongPw as Failure).error.message,
      );
    });
  });

  group('signUp', () {
    test('maps email-already-in-use to AuthError', () async {
      when(() => ds.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenThrow(FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'taken',
          ));

      final result = await repo.signUp(
        email: 'a@b.com',
        password: 'pw',
        displayName: 'A',
      );

      expect((result as Failure).error, isA<AuthError>());
    });

    test('forwards happy path as Success', () async {
      final user = _sampleUser();
      when(() => ds.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => user);

      final result = await repo.signUp(
        email: 'a@b.com',
        password: 'pw12345a',
        displayName: 'Ada',
      );

      expect(result, isA<Success<AppUser>>());
      expect((result as Success<AppUser>).value, user);
    });
  });

  group('signInWithGoogle', () {
    test('returns Success on data-source success', () async {
      final user = _sampleUser();
      when(() => ds.signInWithGoogle()).thenAnswer((_) async => user);
      final result = await repo.signInWithGoogle();
      expect((result as Success<AppUser>).value, user);
    });

    test('maps cancellation to CancelledError', () async {
      when(() => ds.signInWithGoogle())
          .thenThrow(GoogleSignInCancelledException());

      final result = await repo.signInWithGoogle();

      expect((result as Failure).error, isA<CancelledError>());
    });

    test('maps network failure to NetworkError', () async {
      when(() => ds.signInWithGoogle())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      final result = await repo.signInWithGoogle();
      expect((result as Failure).error, isA<NetworkError>());
    });
  });

  group('reloadCurrentUser', () {
    test('returns Success with refreshed user', () async {
      final user = _sampleUser();
      when(() => ds.reloadCurrentUser()).thenAnswer((_) async => user);
      final result = await repo.reloadCurrentUser();
      expect((result as Success<AppUser?>).value, user);
    });

    test('returns Success(null) when there is no current user', () async {
      when(() => ds.reloadCurrentUser()).thenAnswer((_) async => null);
      final result = await repo.reloadCurrentUser();
      expect((result as Success<AppUser?>).value, isNull);
    });

    test('maps FirebaseAuthException to AuthError', () async {
      when(() => ds.reloadCurrentUser())
          .thenThrow(FirebaseAuthException(code: 'user-disabled'));
      final result = await repo.reloadCurrentUser();
      expect((result as Failure).error, isA<AuthError>());
    });
  });

  group('signInAnonymously', () {
    test('returns Success', () async {
      final user = _sampleUser();
      when(() => ds.signInAnonymously()).thenAnswer((_) async => user);
      final result = await repo.signInAnonymously();
      expect((result as Success<AppUser>).value, user);
    });
  });

  group('signOut / sendEmailVerification / resetPassword', () {
    test('signOut returns Success when data source succeeds', () async {
      when(() => ds.signOut()).thenAnswer((_) async {});
      final result = await repo.signOut();
      expect(result, isA<Success<void>>());
    });

    test('sendEmailVerification maps requires-recent-login to AuthError',
        () async {
      when(() => ds.sendEmailVerification())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
      final result = await repo.sendEmailVerification();
      expect((result as Failure).error, isA<AuthError>());
    });

    test('resetPassword returns Success on data source success', () async {
      when(() => ds.resetPassword(any())).thenAnswer((_) async {});
      final result = await repo.resetPassword('a@b.com');
      expect(result, isA<Success<void>>());
    });
  });

  group('watchAuthState', () {
    test('returns stream from data source', () async {
      final stream = Stream<UserModel?>.value(_sampleUser());
      when(() => ds.watchAuthState()).thenAnswer((_) => stream);
      expect(await repo.watchAuthState().first, _sampleUser());
    });
  });
}
