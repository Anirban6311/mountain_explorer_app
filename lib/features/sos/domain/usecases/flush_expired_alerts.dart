import '../../../../core/errors/result.dart';
import '../repositories/sos_repository.dart';

class FlushExpiredAlerts {
  final SosRepository _repo;
  const FlushExpiredAlerts(this._repo);

  Future<Result<int>> call(
    String uid, {
    Duration ttl = const Duration(hours: 6),
  }) =>
      _repo.flushExpired(uid, ttl: ttl);
}
