import 'package:equatable/equatable.dart';

class Mountain extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final String? region;
  final double? lat;
  final double? lng;

  const Mountain({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    this.region,
    this.lat,
    this.lng,
  });

  /// True iff both coordinates are present, enabling map-based actions.
  bool get hasCoordinates => lat != null && lng != null;

  @override
  List<Object?> get props =>
      [id, name, imageUrl, description, region, lat, lng];
}
