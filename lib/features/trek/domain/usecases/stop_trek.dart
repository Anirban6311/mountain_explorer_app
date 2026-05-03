import '../../../../core/errors/result.dart';
import '../repositories/trek_repository.dart';

class StopTrek {
  final TrekRepository _repo;
  const StopTrek(this._repo);

  Future<Result<void>> call() => _repo.stop();
}
