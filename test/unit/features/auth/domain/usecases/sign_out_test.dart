import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SignOut usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SignOut(repo);
  });

  test('delegates to repo.signOut on success', () async {
    when(() => repo.signOut())
        .thenAnswer((_) async => const Success<void>(null));
    final result = await usecase();
    expect(result, isA<Success<void>>());
    verify(() => repo.signOut()).called(1);
  });

  test('propagates failure', () async {
    const err = UnknownError('boom');
    when(() => repo.signOut())
        .thenAnswer((_) async => const Failure<void>(err));
    final result = await usecase();
    expect((result as Failure<void>).error, same(err));
  });
}
