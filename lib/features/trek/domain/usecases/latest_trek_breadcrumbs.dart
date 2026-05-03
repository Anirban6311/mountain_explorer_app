import '../entities/breadcrumb.dart';
import '../repositories/trek_repository.dart';

/// Returns the most recent trek breadcrumbs from sqflite. Used by the
/// SOS dispatch path to attach the latest trail to the alert payload.
class LatestTrekBreadcrumbs {
  final TrekRepository _repo;
  const LatestTrekBreadcrumbs(this._repo);

  Future<List<Breadcrumb>> call({int limit = 50}) =>
      _repo.latest(limit: limit);
}
