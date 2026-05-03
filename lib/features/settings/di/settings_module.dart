import 'package:get_it/get_it.dart';

import '../../../core/storage/app_prefs.dart';
import '../../offline_maps/domain/usecases/total_size_bytes.dart';
import '../../offline_maps/domain/usecases/watch_regions.dart';
import '../presentation/cubit/settings_cubit.dart';

void registerSettingsModule(GetIt getIt) {
  if (getIt.isRegistered<SettingsCubit>()) return;
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      prefs: getIt<AppPrefs>(),
      totalSizeBytes: getIt<TotalSizeBytes>(),
      watchRegions: getIt<WatchRegions>(),
    ),
  );
}
