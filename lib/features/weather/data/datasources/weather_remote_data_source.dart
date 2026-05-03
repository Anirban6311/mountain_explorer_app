import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherNetworkException implements Exception {
  final String message;
  const WeatherNetworkException(this.message);
  @override
  String toString() => 'WeatherNetworkException($message)';
}

class WeatherNotFoundException implements Exception {
  final String message;
  const WeatherNotFoundException(this.message);
  @override
  String toString() => 'WeatherNotFoundException($message)';
}

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getWeatherForCity(String city);
}

class OpenWeatherMapRemoteDataSource implements WeatherRemoteDataSource {
  final http.Client _client;
  final String _apiKey;
  final String _baseUrl;

  OpenWeatherMapRemoteDataSource({
    required http.Client client,
    required String apiKey,
    String baseUrl = 'https://api.openweathermap.org/data/2.5/weather',
  })  : _client = client,
        _apiKey = apiKey,
        _baseUrl = baseUrl;

  @override
  Future<WeatherModel> getWeatherForCity(String city) async {
    final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(city)}'
        '&units=metric&appid=$_apiKey');
    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        return WeatherModel.fromOpenWeatherMapJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      if (response.statusCode == 404) {
        throw WeatherNotFoundException('No weather for "$city".');
      }
      throw WeatherNetworkException(
        'Weather service returned ${response.statusCode}.',
      );
    } on SocketException catch (e) {
      throw WeatherNetworkException(e.message);
    }
  }
}
