import '../repositories/trek_repository.dart';

class WatchBreadcrumbCount {
  final TrekRepository _repo;
  const WatchBreadcrumbCount(this._repo);

  Stream<int> call() => _repo.watchBreadcrumbCount();
}
