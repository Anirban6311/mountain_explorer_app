import '../../../../core/errors/result.dart';
import '../repositories/sos_repository.dart';

class CancelSos {
  final SosRepository _repo;
  const CancelSos(this._repo);

  Future<Result<void>> call(String alertId) => _repo.cancel(alertId);
}
