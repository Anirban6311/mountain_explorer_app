import '../../../../core/errors/result.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class GetWeatherForCity {
  final WeatherRepository _repo;
  const GetWeatherForCity(this._repo);

  Future<Result<Weather>> call(String city) => _repo.getWeatherForCity(city);
}
