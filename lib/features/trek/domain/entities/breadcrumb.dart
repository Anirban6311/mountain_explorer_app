import 'package:equatable/equatable.dart';

/// A single GPS sample recorded during a trek session. The fields map
/// directly to the Iter 1 sqflite schema (`trek_breadcrumbs`).
class Breadcrumb extends Equatable {
  final DateTime ts;
  final double lat;
  final double lng;
  final double? accuracy;
  final double? altitude;
  final int? battery;

  const Breadcrumb({
    required this.ts,
    required this.lat,
    required this.lng,
    this.accuracy,
    this.altitude,
    this.battery,
  });

  @override
  List<Object?> get props => [ts, lat, lng, accuracy, altitude, battery];
}
