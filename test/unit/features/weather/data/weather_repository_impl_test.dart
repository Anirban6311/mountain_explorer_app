import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/weather/data/datasources/weather_remote_data_source.dart';
import 'package:basic_crud_flutter/features/weather/data/models/weather_model.dart';
import 'package:basic_crud_flutter/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:basic_crud_flutter/features/weather/domain/entities/weather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements WeatherRemoteDataSource {}

void main() {
  late _MockDs ds;
  late WeatherRepositoryImpl repo;

  setUp(() {
    ds = _MockDs();
    repo = WeatherRepositoryImpl(ds);
  });

  test('returns Success with the mapped entity', () async {
    const model = WeatherModel(city: 'Shimla', temperatureC: 12.3, condition: 'Clear');
    when(() => ds.getWeatherForCity(any())).thenAnswer((_) async => model);

    final result = await repo.getWeatherForCity('Shimla');

    expect((result as Success<Weather>).value, model);
  });

  test('maps WeatherNetworkException to NetworkError', () async {
    when(() => ds.getWeatherForCity(any()))
        .thenThrow(const WeatherNetworkException('offline'));
    final result = await repo.getWeatherForCity('Shimla');
    expect((result as Failure<Weather>).error, isA<NetworkError>());
  });

  test('maps WeatherNotFoundException to NotFoundError', () async {
    when(() => ds.getWeatherForCity(any()))
        .thenThrow(const WeatherNotFoundException('nope'));
    final result = await repo.getWeatherForCity('Shimla');
    expect((result as Failure<Weather>).error, isA<NotFoundError>());
  });

  test('maps unknown exceptions to UnknownError', () async {
    when(() => ds.getWeatherForCity(any())).thenThrow(StateError('boom'));
    final result = await repo.getWeatherForCity('Shimla');
    expect((result as Failure<Weather>).error, isA<UnknownError>());
  });
}
