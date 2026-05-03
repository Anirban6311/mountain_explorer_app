import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../../core/env/env.dart';
import '../data/datasources/weather_remote_data_source.dart';
import '../data/repositories/weather_repository_impl.dart';
import '../domain/repositories/weather_repository.dart';
import '../domain/usecases/get_weather_for_city.dart';

void registerWeatherModule(GetIt getIt) {
  if (getIt.isRegistered<WeatherRepository>()) return;

  getIt.registerLazySingleton<http.Client>(http.Client.new);
  getIt.registerLazySingleton<WeatherRemoteDataSource>(
    () => OpenWeatherMapRemoteDataSource(
      client: getIt<http.Client>(),
      apiKey: getIt<Env>().openWeatherApiKey,
    ),
  );
  getIt.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(getIt<WeatherRemoteDataSource>()),
  );
  getIt.registerLazySingleton(
    () => GetWeatherForCity(getIt<WeatherRepository>()),
  );
}
