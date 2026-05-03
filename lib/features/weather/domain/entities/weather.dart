import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String city;
  final double temperatureC;
  final String condition;

  const Weather({
    required this.city,
    required this.temperatureC,
    required this.condition,
  });

  @override
  List<Object?> get props => [city, temperatureC, condition];
}
