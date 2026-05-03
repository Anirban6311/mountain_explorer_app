import '../repositories/trek_repository.dart';

class WatchActiveTrekSession {
  final TrekRepository _repo;
  const WatchActiveTrekSession(this._repo);

  Stream<String?> call() => _repo.watchActiveSessionId();
}
