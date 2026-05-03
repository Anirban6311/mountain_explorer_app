import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/mountains/data/datasources/liked_mountains_remote_data_source.dart';
import 'package:basic_crud_flutter/features/mountains/data/datasources/mountains_remote_data_source.dart';
import 'package:basic_crud_flutter/features/mountains/data/models/mountain_model.dart';
import 'package:basic_crud_flutter/features/mountains/data/repositories/mountains_repository_impl.dart';
import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMountains extends Mock implements MountainsRemoteDataSource {}

class _MockLiked extends Mock implements LikedMountainsRemoteDataSource {}

void main() {
  late _MockMountains mountainsDs;
  late _MockLiked likedDs;
  late MountainsRepositoryImpl repo;

  setUp(() {
    mountainsDs = _MockMountains();
    likedDs = _MockLiked();
    repo = MountainsRepositoryImpl(
      mountainsDs: mountainsDs,
      likedDs: likedDs,
    );
  });

  group('getMountains', () {
    test('returns Success with the mapped list', () async {
      final list = [
        const MountainModel(
          id: 'shimla',
          name: 'Shimla',
          imageUrl: 'url',
          description: 'desc',
        ),
      ];
      when(() => mountainsDs.getMountains()).thenAnswer((_) async => list);
      final result = await repo.getMountains();
      expect((result as Success<List<Mountain>>).value, list);
    });

    test('maps unknown errors to UnknownError', () async {
      when(() => mountainsDs.getMountains()).thenThrow(StateError('bad'));
      final result = await repo.getMountains();
      expect((result as Failure<List<Mountain>>).error, isA<UnknownError>());
    });
  });

  group('toggleLike', () {
    test('delegates and returns Success', () async {
      when(() => likedDs.toggleLike(
            uid: any(named: 'uid'),
            mountainId: any(named: 'mountainId'),
          )).thenAnswer((_) async {});
      final result = await repo.toggleLike(uid: 'u1', mountainId: 'shimla');
      expect(result, isA<Success<void>>());
      verify(() => likedDs.toggleLike(uid: 'u1', mountainId: 'shimla'))
          .called(1);
    });

    test('maps errors to PermissionError on permission_denied', () async {
      when(() => likedDs.toggleLike(
            uid: any(named: 'uid'),
            mountainId: any(named: 'mountainId'),
          )).thenThrow(Exception('permission-denied'));
      final result = await repo.toggleLike(uid: 'u1', mountainId: 'shimla');
      expect(result, isA<Failure<void>>());
    });
  });

  group('watchLikedMountainIds', () {
    test('forwards the stream from the data source', () async {
      when(() => likedDs.watchLikedMountainIds(any()))
          .thenAnswer((_) => Stream.value({'shimla'}));
      expect(await repo.watchLikedMountainIds('u1').first, {'shimla'});
    });
  });
}
