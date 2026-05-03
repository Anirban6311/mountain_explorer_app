import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/mountains/domain/repositories/mountains_repository.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/get_mountains.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MountainsRepository {}

void main() {
  late _MockRepo repo;
  late GetMountains usecase;

  setUp(() {
    repo = _MockRepo();
    usecase = GetMountains(repo);
  });

  test('delegates and returns Success', () async {
    const list = [
      Mountain(
        id: 'shimla',
        name: 'Shimla',
        imageUrl: 'http://x/s.jpg',
        description: 'desc',
      ),
    ];
    when(() => repo.getMountains())
        .thenAnswer((_) async => const Success<List<Mountain>>(list));
    final result = await usecase();
    expect((result as Success<List<Mountain>>).value, list);
  });

  test('propagates failure', () async {
    when(() => repo.getMountains()).thenAnswer(
      (_) async => const Failure<List<Mountain>>(NetworkError('offline')),
    );
    final result = await usecase();
    expect(result, isA<Failure<List<Mountain>>>());
  });
}
