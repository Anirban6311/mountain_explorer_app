import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../weather/domain/usecases/get_weather_for_city.dart';
import '../data/datasources/liked_mountains_remote_data_source.dart';
import '../data/datasources/mountains_remote_data_source.dart';
import '../data/repositories/mountains_repository_impl.dart';
import '../domain/repositories/mountains_repository.dart';
import '../domain/usecases/get_mountains.dart';
import '../domain/usecases/search_mountains.dart';
import '../domain/usecases/toggle_like_mountain.dart';
import '../domain/usecases/watch_liked_mountain_ids.dart';
import '../presentation/cubit/mountain_search_cubit.dart';
import '../presentation/cubit/mountains_cubit.dart';

void registerMountainsModule(GetIt getIt) {
  if (getIt.isRegistered<MountainsRepository>()) return;

  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );

  getIt.registerLazySingleton<MountainsRemoteDataSource>(
    () => FirestoreMountainsRemoteDataSource(db: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<LikedMountainsRemoteDataSource>(
    () => FirestoreLikedMountainsRemoteDataSource(getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<MountainsRepository>(
    () => MountainsRepositoryImpl(
      mountainsDs: getIt<MountainsRemoteDataSource>(),
      likedDs: getIt<LikedMountainsRemoteDataSource>(),
    ),
  );

  final repo = getIt<MountainsRepository>();
  getIt.registerLazySingleton(() => GetMountains(repo));
  getIt.registerLazySingleton(() => ToggleLikeMountain(repo));
  getIt.registerLazySingleton(() => WatchLikedMountainIds(repo));
  getIt.registerLazySingleton(() => const SearchMountains());

  getIt.registerLazySingleton<MountainsCubit>(
    () => MountainsCubit(
      getMountains: getIt<GetMountains>(),
      toggleLikeMountain: getIt<ToggleLikeMountain>(),
      watchLikedMountainIds: getIt<WatchLikedMountainIds>(),
      getWeatherForCity: getIt<GetWeatherForCity>(),
    ),
    dispose: (c) => c.close(),
  );
  getIt.registerFactory<MountainSearchCubit>(
    () => MountainSearchCubit(searchMountains: getIt<SearchMountains>()),
  );
}
