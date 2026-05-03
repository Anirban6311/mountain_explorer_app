import '../repositories/sos_outbox_repository.dart';

class ProcessSosOutbox {
  final SosOutboxRepository _repo;
  const ProcessSosOutbox(this._repo);

  Future<void> call() => _repo.processDue();
}
