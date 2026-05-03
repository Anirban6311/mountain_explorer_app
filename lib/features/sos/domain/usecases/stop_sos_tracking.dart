import '../../../../core/errors/result.dart';
import '../repositories/sos_tracking_repository.dart';

class StopSosTracking {
  final SosTrackingRepository _repo;
  const StopSosTracking(this._repo);

  Future<Result<void>> call() => _repo.stop();
}
