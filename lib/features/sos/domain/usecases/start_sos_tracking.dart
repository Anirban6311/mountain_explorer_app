import '../../../../core/errors/result.dart';
import '../repositories/sos_tracking_repository.dart';

class StartSosTracking {
  final SosTrackingRepository _repo;
  const StartSosTracking(this._repo);

  Future<Result<void>> call(String alertId) => _repo.start(alertId);
}
