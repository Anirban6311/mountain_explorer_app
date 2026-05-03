import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late SignInAnonymously usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = SignInAnonymously(repo);
  });

  test('delegates to repo.signInAnonymously', () async {
    const user = AppUser(
      uid: 'anon1',
      email: null,
      displayName: null,
      photoUrl: null,
      isAnonymous: true,
      isEmailVerified: false,
      providerId: 'anonymous',
    );
    when(() => repo.signInAnonymously())
        .thenAnswer((_) async => const Success(user));
    final result = await usecase();
    expect((result as Success<AppUser>).value.isAnonymous, isTrue);
    verify(() => repo.signInAnonymously()).called(1);
  });
}
