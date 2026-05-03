import '../../../../core/errors/result.dart';
import '../repositories/mountains_repository.dart';

class ToggleLikeMountain {
  final MountainsRepository _repo;
  const ToggleLikeMountain(this._repo);

  Future<Result<void>> call({
    required String uid,
    required String mountainId,
  }) =>
      _repo.toggleLike(uid: uid, mountainId: mountainId);
}
