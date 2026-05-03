import 'package:get_it/get_it.dart';

import '../../../core/services/battery_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/storage/local_db.dart';
import '../data/datasources/trek_breadcrumbs_local_data_source.dart';
import '../data/repositories/trek_repository_impl.dart';
import '../domain/repositories/trek_repository.dart';
import '../domain/usecases/latest_trek_breadcrumbs.dart';
import '../domain/usecases/start_trek.dart';
import '../domain/usecases/stop_trek.dart';
import '../domain/usecases/watch_active_session.dart';
import '../domain/usecases/watch_breadcrumb_count.dart';
import '../presentation/cubit/trek_cubit.dart';

void registerTrekModule(GetIt getIt) {
  if (getIt.isRegistered<TrekRepository>()) return;

  getIt.registerLazySingleton<TrekBreadcrumbsLocalDataSource>(
    () => SqfliteTrekBreadcrumbsLocalDataSource(getIt<LocalDb>()),
  );
  getIt.registerLazySingleton<TrekRepository>(
    () => TrekRepositoryImpl(
      location: getIt<LocationService>(),
      battery: getIt<BatteryService>(),
      ds: getIt<TrekBreadcrumbsLocalDataSource>(),
      prefs: getIt<AppPrefs>(),
    ),
  );

  final repo = getIt<TrekRepository>();
  getIt.registerLazySingleton(() => StartTrek(repo));
  getIt.registerLazySingleton(() => StopTrek(repo));
  getIt.registerLazySingleton(() => WatchActiveTrekSession(repo));
  getIt.registerLazySingleton(() => WatchBreadcrumbCount(repo));
  getIt.registerLazySingleton(() => LatestTrekBreadcrumbs(repo));

  // Singleton: trek state must outlive map-tab rebuilds and survive
  // cold-start resumption. `dispose:` mirrors the SosCubit pattern.
  getIt.registerLazySingleton<TrekCubit>(
    () => TrekCubit(
      startTrek: getIt<StartTrek>(),
      stopTrek: getIt<StopTrek>(),
      watchSession: getIt<WatchActiveTrekSession>(),
      watchCount: getIt<WatchBreadcrumbCount>(),
      location: getIt<LocationService>(),
      prefs: getIt<AppPrefs>(),
    ),
    dispose: (c) => c.close(),
  );
}
