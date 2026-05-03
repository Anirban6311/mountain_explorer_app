import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../weather/domain/usecases/get_weather_for_city.dart';
import '../../domain/usecases/get_mountains.dart';
import '../../domain/usecases/toggle_like_mountain.dart';
import '../../domain/usecases/watch_liked_mountain_ids.dart';
import 'mountains_state.dart';

class MountainsCubit extends Cubit<MountainsState> {
  final GetMountains _getMountains;
  final ToggleLikeMountain _toggleLikeMountain;
  final WatchLikedMountainIds _watchLikedMountainIds;
  final GetWeatherForCity _getWeatherForCity;

  StreamSubscription<Set<String>>? _likedSub;

  MountainsCubit({
    required GetMountains getMountains,
    required ToggleLikeMountain toggleLikeMountain,
    required WatchLikedMountainIds watchLikedMountainIds,
    required GetWeatherForCity getWeatherForCity,
  })  : _getMountains = getMountains,
        _toggleLikeMountain = toggleLikeMountain,
        _watchLikedMountainIds = watchLikedMountainIds,
        _getWeatherForCity = getWeatherForCity,
        super(const MountainsInitial());

  Future<void> load({required String uid}) async {
    if (isClosed) return;
    emit(const MountainsLoading());
    final result = await _getMountains();
    if (isClosed) return;
    switch (result) {
      case Failure(:final error):
        emit(MountainsError(error.message));
        return;
      case Success(:final value):
        emit(MountainsLoaded(mountains: value));
        if (uid.isNotEmpty) _subscribeToLiked(uid);
        unawaited(_prefetchWeather(value.map((m) => m.name)));
    }
  }

  void _subscribeToLiked(String uid) {
    _likedSub?.cancel();
    _likedSub = _watchLikedMountainIds(uid).listen((ids) {
      if (isClosed) return;
      final s = state;
      if (s is MountainsLoaded) emit(s.copyWith(likedIds: ids));
    });
  }

  Future<void> _prefetchWeather(Iterable<String> cities) async {
    const timeout = Duration(seconds: 5);
    final s0 = state;
    if (s0 is! MountainsLoaded) return;
    final pending = cities.where((c) => !s0.weatherByCity.containsKey(c));

    // Kick off all fetches in parallel, each with its own timeout so a
    // single slow/hung city can't wedge the rest.
    final futures = pending.map((city) async {
      try {
        final result = await _getWeatherForCity(city).timeout(timeout);
        if (isClosed) return;
        if (result is Success && state is MountainsLoaded) {
          final current = state as MountainsLoaded;
          emit(current.copyWith(
            weatherByCity: {
              ...current.weatherByCity,
              city: (result as Success).value,
            },
          ));
        }
      } catch (_) {
        // Silently skip — card just renders without the temp chip.
      }
    });

    await Future.wait(futures);
  }

  Future<void> toggleLike({
    required String uid,
    required String mountainId,
  }) async {
    await _toggleLikeMountain(uid: uid, mountainId: mountainId);
  }

  @override
  Future<void> close() async {
    await _likedSub?.cancel();
    return super.close();
  }
}
