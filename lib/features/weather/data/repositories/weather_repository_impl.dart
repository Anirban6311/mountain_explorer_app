import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource _ds;
  const WeatherRepositoryImpl(this._ds);

  @override
  Future<Result<Weather>> getWeatherForCity(String city) async {
    try {
      final model = await _ds.getWeatherForCity(city);
      return Success<Weather>(model);
    } on WeatherNetworkException catch (e) {
      return Failure<Weather>(NetworkError(e.message, cause: e));
    } on WeatherNotFoundException catch (e) {
      return Failure<Weather>(NotFoundError(e.message, cause: e));
    } catch (e) {
      return Failure<Weather>(
        UnknownError('Weather fetch failed.', cause: e),
      );
    }
  }
}
