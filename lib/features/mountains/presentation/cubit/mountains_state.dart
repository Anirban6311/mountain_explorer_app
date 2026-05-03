import 'package:equatable/equatable.dart';

import '../../domain/entities/mountain.dart';
import '../../../weather/domain/entities/weather.dart';

sealed class MountainsState extends Equatable {
  const MountainsState();
  @override
  List<Object?> get props => const [];
}

class MountainsInitial extends MountainsState {
  const MountainsInitial();
}

class MountainsLoading extends MountainsState {
  const MountainsLoading();
}

class MountainsLoaded extends MountainsState {
  final List<Mountain> mountains;
  final Set<String> likedIds;
  final Map<String, Weather> weatherByCity;

  const MountainsLoaded({
    required this.mountains,
    this.likedIds = const {},
    this.weatherByCity = const {},
  });

  MountainsLoaded copyWith({
    List<Mountain>? mountains,
    Set<String>? likedIds,
    Map<String, Weather>? weatherByCity,
  }) {
    return MountainsLoaded(
      mountains: mountains ?? this.mountains,
      likedIds: likedIds ?? this.likedIds,
      weatherByCity: weatherByCity ?? this.weatherByCity,
    );
  }

  @override
  List<Object?> get props => [mountains, likedIds, weatherByCity];
}

class MountainsError extends MountainsState {
  final String message;
  const MountainsError(this.message);
  @override
  List<Object?> get props => [message];
}
