import '../entities/download_progress.dart';
import '../repositories/offline_maps_repository.dart';

class ResumeDownload {
  final OfflineMapsRepository _repo;
  const ResumeDownload(this._repo);

  Stream<DownloadProgress> call(String regionId) => _repo.resume(regionId);
}
