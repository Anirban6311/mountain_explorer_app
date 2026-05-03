import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/mountains/domain/repositories/mountains_repository.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/get_mountains.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/toggle_like_mountain.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/watch_liked_mountain_ids.dart';
import 'package:basic_crud_flutter/features/mountains/presentation/cubit/mountains_cubit.dart';
import 'package:basic_crud_flutter/features/mountains/presentation/cubit/mountains_state.dart';
import 'package:basic_crud_flutter/features/weather/domain/entities/weather.dart'
    show Weather;
import 'package:basic_crud_flutter/features/weather/domain/repositories/weather_repository.dart';
import 'package:basic_crud_flutter/features/weather/domain/usecases/get_weather_for_city.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMountainsRepo extends Mock implements MountainsRepository {}

class _MockWeatherRepo extends Mock implements WeatherRepository {}

const _shimla = Mountain(
  id: 'shimla',
  name: 'Shimla',
  imageUrl: 'u',
  description: 'd',
);

MountainsCubit _build({
  required _MockMountainsRepo mRepo,
  required _MockWeatherRepo wRepo,
}) {
  return MountainsCubit(
    getMountains: GetMountains(mRepo),
    toggleLikeMountain: ToggleLikeMountain(mRepo),
    watchLikedMountainIds: WatchLikedMountainIds(mRepo),
    getWeatherForCity: GetWeatherForCity(wRepo),
  );
}

void main() {
  late _MockMountainsRepo mRepo;
  late _MockWeatherRepo wRepo;

  setUp(() {
    mRepo = _MockMountainsRepo();
    wRepo = _MockWeatherRepo();
    when(() => mRepo.watchLikedMountainIds(any()))
        .thenAnswer((_) => const Stream<Set<String>>.empty());
    // Default: weather fetch silently fails so the cubit doesn't emit extra
    // weather-cache states. Tests that care about weather override this.
    when(() => wRepo.getWeatherForCity(any())).thenAnswer(
      (_) async => const Failure<Weather>(NetworkError('skipped')),
    );
  });

  blocTest<MountainsCubit, MountainsState>(
    'load() emits Loading then Loaded(mountains) on success',
    build: () => _build(mRepo: mRepo, wRepo: wRepo),
    setUp: () {
      when(() => mRepo.getMountains())
          .thenAnswer((_) async => const Success<List<Mountain>>([_shimla]));
    },
    act: (c) => c.load(uid: 'u1'),
    expect: () => [
      isA<MountainsLoading>(),
      isA<MountainsLoaded>()
          .having((s) => s.mountains.length, 'len', 1)
          .having((s) => s.mountains.single.id, 'id', 'shimla'),
    ],
  );

  blocTest<MountainsCubit, MountainsState>(
    'load() emits Error when repo returns Failure',
    build: () => _build(mRepo: mRepo, wRepo: wRepo),
    setUp: () {
      when(() => mRepo.getMountains()).thenAnswer(
        (_) async => const Failure<List<Mountain>>(NetworkError('offline')),
      );
    },
    act: (c) => c.load(uid: 'u1'),
    expect: () => [
      isA<MountainsLoading>(),
      isA<MountainsError>()
          .having((s) => s.message, 'message', contains('offline')),
    ],
  );

  blocTest<MountainsCubit, MountainsState>(
    'liked stream updates Loaded.likedIds',
    build: () {
      final controller = StreamController<Set<String>>.broadcast();
      when(() => mRepo.getMountains())
          .thenAnswer((_) async => const Success<List<Mountain>>([_shimla]));
      when(() => mRepo.watchLikedMountainIds(any()))
          .thenAnswer((_) => controller.stream);
      addTearDown(controller.close);
      Future.delayed(const Duration(milliseconds: 20), () {
        controller.add({'shimla'});
      });
      return _build(mRepo: mRepo, wRepo: wRepo);
    },
    act: (c) async {
      await c.load(uid: 'u1');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
    skip: 1,
    expect: () => [
      isA<MountainsLoaded>()
          .having((s) => s.likedIds, 'likedIds', <String>{}),
      isA<MountainsLoaded>()
          .having((s) => s.likedIds, 'likedIds', {'shimla'}),
    ],
  );

  blocTest<MountainsCubit, MountainsState>(
    'toggleLike calls repo with uid + mountainId',
    build: () => _build(mRepo: mRepo, wRepo: wRepo),
    setUp: () {
      when(() => mRepo.getMountains())
          .thenAnswer((_) async => const Success<List<Mountain>>([_shimla]));
      when(() => mRepo.toggleLike(
            uid: any(named: 'uid'),
            mountainId: any(named: 'mountainId'),
          )).thenAnswer((_) async => const Success<void>(null));
    },
    act: (c) async {
      await c.load(uid: 'u1');
      await c.toggleLike(uid: 'u1', mountainId: 'shimla');
    },
    verify: (_) {
      verify(() => mRepo.toggleLike(uid: 'u1', mountainId: 'shimla'))
          .called(1);
    },
  );
}
