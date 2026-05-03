import '../../../../core/errors/result.dart';
import '../entities/mountain.dart';

abstract class MountainsRepository {
  Future<Result<List<Mountain>>> getMountains();

  Future<Result<void>> toggleLike({
    required String uid,
    required String mountainId,
  });

  Stream<Set<String>> watchLikedMountainIds(String uid);
}
