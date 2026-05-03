import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/mountain.dart';
import '../../domain/repositories/mountains_repository.dart';
import '../datasources/liked_mountains_remote_data_source.dart';
import '../datasources/mountains_remote_data_source.dart';

class MountainsRepositoryImpl implements MountainsRepository {
  final MountainsRemoteDataSource _mountainsDs;
  final LikedMountainsRemoteDataSource _likedDs;

  const MountainsRepositoryImpl({
    required MountainsRemoteDataSource mountainsDs,
    required LikedMountainsRemoteDataSource likedDs,
  })  : _mountainsDs = mountainsDs,
        _likedDs = likedDs;

  @override
  Future<Result<List<Mountain>>> getMountains() async {
    try {
      final list = await _mountainsDs.getMountains();
      return Success<List<Mountain>>(list);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return Failure<List<Mountain>>(
          NetworkError('Network unavailable.', cause: e),
        );
      }
      return Failure<List<Mountain>>(
        UnknownError('Failed to load mountains.', cause: e),
      );
    } catch (e) {
      return Failure<List<Mountain>>(
        UnknownError('Failed to load mountains.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> toggleLike({
    required String uid,
    required String mountainId,
  }) async {
    try {
      await _likedDs.toggleLike(uid: uid, mountainId: mountainId);
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Failure<void>(PermissionError('Not allowed.', cause: e));
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return Failure<void>(NetworkError('Network unavailable.', cause: e));
      }
      return Failure<void>(UnknownError('Failed to update like.', cause: e));
    } catch (e) {
      return Failure<void>(UnknownError('Failed to update like.', cause: e));
    }
  }

  @override
  Stream<Set<String>> watchLikedMountainIds(String uid) =>
      _likedDs.watchLikedMountainIds(uid);
}
