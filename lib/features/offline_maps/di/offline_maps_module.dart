import 'package:get_it/get_it.dart';

import '../../../core/env/env.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_tile_store.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/storage/local_db.dart';
import '../data/datasources/offline_regions_local_data_source.dart';
import '../data/repositories/offline_maps_repository_impl.dart';
import '../domain/repositories/offline_maps_repository.dart';
import '../domain/usecases/cancel_download.dart';
import '../domain/usecases/delete_region.dart';
import '../domain/usecases/estimate_download.dart';
import '../domain/usecases/has_completed_region.dart';
import '../domain/usecases/reset_entire_cache.dart';
import '../domain/usecases/resume_download.dart';
import '../domain/usecases/start_download.dart';
import '../domain/usecases/total_size_bytes.dart';
import '../domain/usecases/watch_regions.dart';
import '../presentation/cubit/offline_maps_cubit.dart';

void registerOfflineMapsModule(GetIt getIt) {
  if (getIt.isRegistered<OfflineMapsRepository>()) return;

  getIt.registerLazySingleton<OfflineRegionsLocalDataSource>(
    () => SqfliteOfflineRegionsLocalDataSource(getIt<LocalDb>()),
  );
  getIt.registerLazySingleton<OfflineMapsRepository>(
    () => OfflineMapsRepositoryImpl(
      ds: getIt<OfflineRegionsLocalDataSource>(),
      tileStore: getIt<OfflineTileStore>(),
      prefs: getIt<AppPrefs>(),
      env: getIt<Env>(),
    ),
  );

  final repo = getIt<OfflineMapsRepository>();
  getIt.registerLazySingleton(() => WatchRegions(repo));
  getIt.registerLazySingleton(() => EstimateDownload(repo));
  getIt.registerLazySingleton(() => StartDownload(repo));
  getIt.registerLazySingleton(() => CancelDownload(repo));
  getIt.registerLazySingleton(() => HasCompletedRegion(repo));
  getIt.registerLazySingleton(() => TotalSizeBytes(repo));
  getIt.registerLazySingleton(() => ResumeDownload(repo));
  getIt.registerLazySingleton(() => ResetEntireCache(repo));
  getIt.registerLazySingleton(() => DeleteRegion(repo));

  getIt.registerFactory<OfflineMapsCubit>(
    () => OfflineMapsCubit(
      watchRegions: getIt<WatchRegions>(),
      estimateDownload: getIt<EstimateDownload>(),
      startDownload: getIt<StartDownload>(),
      cancelDownload: getIt<CancelDownload>(),
      hasCompletedRegion: getIt<HasCompletedRegion>(),
      totalSizeBytes: getIt<TotalSizeBytes>(),
      resumeDownload: getIt<ResumeDownload>(),
      deleteRegion: getIt<DeleteRegion>(),
      resetEntireCache: getIt<ResetEntireCache>(),
      connectivity: getIt<ConnectivityService>(),
      prefs: getIt<AppPrefs>(),
    ),
  );
}
