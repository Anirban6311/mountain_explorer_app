import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:basic_crud_flutter/models/weatherModel.dart';

class WeatherService{
  static const BASE_URL="http://api.openweathermap.org/data/2.5/weather";
  final String apiKey;
  WeatherService(
      this.apiKey){
  Future<Weather> getWeather(String cityName) async{
    final response= await http.get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

    if(response.statusCode==200){
      return Weather.fromJson(jsonDecode(response.body));

    }
    else{
      throw Exception("Failed to load weather data");
    }
  }
  }

}