import 'package:basic_crud_flutter/features/weather/data/models/weather_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeatherModel.fromOpenWeatherMapJson parses the documented shape', () {
    final json = <String, dynamic>{
      'name': 'Shimla',
      'main': {'temp': 12.34},
      'weather': [
        {'main': 'Clouds', 'description': 'scattered clouds'},
      ],
    };

    final model = WeatherModel.fromOpenWeatherMapJson(json);

    expect(model.city, 'Shimla');
    expect(model.temperatureC, closeTo(12.34, 0.001));
    expect(model.condition, 'Clouds');
  });

  test('falls back to "Unknown" condition when weather array is empty', () {
    final json = <String, dynamic>{
      'name': 'X',
      'main': {'temp': 0},
      'weather': <dynamic>[],
    };
    final model = WeatherModel.fromOpenWeatherMapJson(json);
    expect(model.condition, 'Unknown');
  });

  test('accepts int temperatures', () {
    final json = <String, dynamic>{
      'name': 'Ooty',
      'main': {'temp': 20},
      'weather': [
        {'main': 'Clear'},
      ],
    };
    final model = WeatherModel.fromOpenWeatherMapJson(json);
    expect(model.temperatureC, 20.0);
  });
}
