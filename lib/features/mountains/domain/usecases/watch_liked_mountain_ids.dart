import '../repositories/mountains_repository.dart';

class WatchLikedMountainIds {
  final MountainsRepository _repo;
  const WatchLikedMountainIds(this._repo);

  Stream<Set<String>> call(String uid) => _repo.watchLikedMountainIds(uid);
}
