import 'package:get_it/get_it.dart';

import '../../features/auth/di/auth_module.dart';
import '../../features/checklist/di/checklist_module.dart';
import '../../features/community/di/community_module.dart';
import '../../features/mountains/di/mountains_module.dart';
import '../../features/offline_maps/di/offline_maps_module.dart';
import '../../features/settings/di/settings_module.dart';
import '../../features/sos/di/sos_module.dart';
import '../../features/trek/di/trek_module.dart';
import '../../features/weather/di/weather_module.dart';
import '../env/env.dart';
import '../services/battery_service.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/offline_tile_store.dart';
import '../storage/app_prefs.dart';
import '../storage/local_db.dart';
import '../utils/logger.dart';

final GetIt getIt = GetIt.instance;

/// Configure foundation-layer singletons.
///
/// Must be called once after `dotenv.load()` and before `runApp`. Repositories
/// and cubits for each feature are registered here in later iterations.
Future<void> configureDependencies() async {
  if (getIt.isRegistered<Logger>()) return;

  getIt.registerSingleton<Logger>(const Logger());
  getIt.registerSingleton<Env>(DotenvEnv());

  final prefs = await AppPrefs.create();
  getIt.registerSingleton<AppPrefs>(prefs);

  final localDb = SqfliteLocalDb();
  await localDb.open();
  getIt.registerSingleton<LocalDb>(localDb);

  getIt.registerLazySingleton<LocationService>(
    () => GeolocatorLocationService(),
  );
  getIt.registerLazySingleton<BatteryService>(
    () => BatteryPlusBatteryService(),
  );
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityPlusConnectivityService(),
  );
  getIt.registerLazySingleton<OfflineTileStore>(
    () => FmtcOfflineTileStore(),
  );

  registerAuthModule(getIt);
  registerWeatherModule(getIt);
  registerMountainsModule(getIt);
  registerCommunityModule(getIt);
  registerChecklistModule(getIt);
  registerOfflineMapsModule(getIt);
  registerSettingsModule(getIt);
  // Trek must register before SOS: SosRepository wires
  // `LatestTrekBreadcrumbs` from get_it, and the SOS module resolves
  // the repo eagerly when wiring use cases.
  registerTrekModule(getIt);
  registerSosModule(getIt);
}
