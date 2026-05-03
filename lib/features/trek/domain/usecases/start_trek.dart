import '../../../../core/errors/result.dart';
import '../repositories/trek_repository.dart';

class StartTrek {
  final TrekRepository _repo;
  const StartTrek(this._repo);

  Future<Result<String>> call() => _repo.start();
}
