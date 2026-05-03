import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/weather/domain/entities/weather.dart';
import 'package:basic_crud_flutter/features/weather/domain/repositories/weather_repository.dart';
import 'package:basic_crud_flutter/features/weather/domain/usecases/get_weather_for_city.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements WeatherRepository {}

void main() {
  late _MockRepo repo;
  late GetWeatherForCity usecase;

  setUp(() {
    repo = _MockRepo();
    usecase = GetWeatherForCity(repo);
  });

  test('delegates and returns Success', () async {
    const w = Weather(city: 'Shimla', temperatureC: 12.5, condition: 'Clear');
    when(() => repo.getWeatherForCity(any()))
        .thenAnswer((_) async => const Success<Weather>(w));

    final result = await usecase('Shimla');

    expect((result as Success<Weather>).value, w);
    verify(() => repo.getWeatherForCity('Shimla')).called(1);
  });

  test('propagates NetworkError', () async {
    when(() => repo.getWeatherForCity(any()))
        .thenAnswer((_) async => const Failure<Weather>(NetworkError('offline')));
    final result = await usecase('Shimla');
    expect(result, isA<Failure<Weather>>());
  });
}
