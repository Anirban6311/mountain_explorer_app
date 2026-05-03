import '../../../../core/errors/result.dart';
import '../entities/weather.dart';

abstract class WeatherRepository {
  Future<Result<Weather>> getWeatherForCity(String city);
}
