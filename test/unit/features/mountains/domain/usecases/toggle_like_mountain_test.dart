import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/mountains/domain/repositories/mountains_repository.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/toggle_like_mountain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MountainsRepository {}

void main() {
  late _MockRepo repo;
  late ToggleLikeMountain usecase;

  setUp(() {
    repo = _MockRepo();
    usecase = ToggleLikeMountain(repo);
  });

  test('delegates with uid + mountainId', () async {
    when(() => repo.toggleLike(
          uid: any(named: 'uid'),
          mountainId: any(named: 'mountainId'),
        )).thenAnswer((_) async => const Success<void>(null));

    final result = await usecase(uid: 'u1', mountainId: 'shimla');

    expect(result, isA<Success<void>>());
    verify(() => repo.toggleLike(uid: 'u1', mountainId: 'shimla')).called(1);
  });

  test('propagates PermissionError', () async {
    when(() => repo.toggleLike(
          uid: any(named: 'uid'),
          mountainId: any(named: 'mountainId'),
        )).thenAnswer(
      (_) async => const Failure<void>(PermissionError('denied')),
    );
    final result = await usecase(uid: 'u1', mountainId: 'shimla');
    expect((result as Failure<void>).error, isA<PermissionError>());
  });
}
