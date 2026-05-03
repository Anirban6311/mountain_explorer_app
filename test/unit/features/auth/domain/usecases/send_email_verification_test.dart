import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SendEmailVerification usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SendEmailVerification(repo);
  });

  test('delegates to repo.sendEmailVerification', () async {
    when(() => repo.sendEmailVerification())
        .thenAnswer((_) async => const Success<void>(null));
    final result = await usecase();
    expect(result, isA<Success<void>>());
    verify(() => repo.sendEmailVerification()).called(1);
  });

  test('propagates failure', () async {
    const err = AuthError('requires-recent-login');
    when(() => repo.sendEmailVerification())
        .thenAnswer((_) async => const Failure<void>(err));
    final result = await usecase();
    expect((result as Failure<void>).error, same(err));
  });
}
