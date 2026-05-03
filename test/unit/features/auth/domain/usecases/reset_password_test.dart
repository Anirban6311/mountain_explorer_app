import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/reset_password.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late ResetPassword usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = ResetPassword(repo);
  });

  test('delegates to repo.resetPassword with email', () async {
    when(() => repo.resetPassword(any()))
        .thenAnswer((_) async => const Success<void>(null));
    final result = await usecase('a@b.com');
    expect(result, isA<Success<void>>());
    verify(() => repo.resetPassword('a@b.com')).called(1);
  });

  test('propagates failure', () async {
    const err = NetworkError('offline');
    when(() => repo.resetPassword(any()))
        .thenAnswer((_) async => const Failure<void>(err));
    final result = await usecase('a@b.com');
    expect((result as Failure<void>).error, same(err));
  });
}
