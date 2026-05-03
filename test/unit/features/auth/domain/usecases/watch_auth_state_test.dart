import 'dart:async';

import 'package:basic_crud_flutter/features/auth/domain/entities/app_user.dart';
import 'package:basic_crud_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:basic_crud_flutter/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;
  late WatchAuthState usecase;

  setUp(() {
    repo = _MockAuthRepository();
    usecase = WatchAuthState(repo);
  });

  test('forwards the repository stream verbatim', () async {
    final controller = StreamController<AppUser?>();
    when(() => repo.watchAuthState())
        .thenAnswer((_) => controller.stream);

    const user = AppUser(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'A',
      photoUrl: null,
      isAnonymous: false,
      isEmailVerified: true,
      providerId: 'password',
    );

    final emissions = <AppUser?>[];
    final sub = usecase().listen(emissions.add);

    controller.add(null);
    controller.add(user);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, [null, user]);
    await sub.cancel();
    await controller.close();
  });
}
