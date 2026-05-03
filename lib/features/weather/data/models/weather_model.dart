import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.city,
    required super.temperatureC,
    required super.condition,
  });

  factory WeatherModel.fromOpenWeatherMapJson(Map<String, dynamic> json) {
    final weatherList = (json['weather'] as List?) ?? const [];
    final condition = weatherList.isNotEmpty
        ? (weatherList.first as Map<String, dynamic>)['main'] as String? ??
            'Unknown'
        : 'Unknown';
    final temp = (json['main'] as Map<String, dynamic>)['temp'];
    return WeatherModel(
      city: json['name'] as String,
      temperatureC: (temp as num).toDouble(),
      condition: condition,
    );
  }
}
