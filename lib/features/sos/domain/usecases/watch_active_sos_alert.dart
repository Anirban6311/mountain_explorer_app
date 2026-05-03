import '../repositories/sos_tracking_repository.dart';

class WatchActiveSosAlert {
  final SosTrackingRepository _repo;
  const WatchActiveSosAlert(this._repo);

  Stream<String?> call() => _repo.watchActiveAlertId();
}
