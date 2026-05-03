import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/reload_current_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late ReloadCurrentUser usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = ReloadCurrentUser(repo);
  });

  test('delegates to repo.reloadCurrentUser on success', () async {
    const user = AppUser(
      uid: 'u',
      email: 'a@b.com',
      displayName: 'A',
      photoUrl: null,
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'password',
    );
    when(() => repo.reloadCurrentUser())
        .thenAnswer((_) async => const Success<AppUser?>(user));
    final result = await usecase();
    expect((result as Success<AppUser?>).value, user);
  });

  test('propagates failure', () async {
    when(() => repo.reloadCurrentUser()).thenAnswer(
      (_) async => const Failure<AppUser?>(NetworkError('offline')),
    );
    final result = await usecase();
    expect(result, isA<Failure<AppUser?>>());
  });
}
