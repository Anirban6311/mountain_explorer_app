import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart';

enum OfflineRegionStatus { downloading, complete, partial, failed }

class OfflineRegion extends Equatable {
  final String id;
  final String name;
  final LatLngBounds bbox;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int sizeBytes;
  final DateTime downloadedAt;
  final OfflineRegionStatus status;

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.bbox,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.sizeBytes,
    required this.downloadedAt,
    required this.status,
  });

  OfflineRegion copyWith({
    String? id,
    String? name,
    LatLngBounds? bbox,
    int? minZoom,
    int? maxZoom,
    int? tileCount,
    int? sizeBytes,
    DateTime? downloadedAt,
    OfflineRegionStatus? status,
  }) {
    return OfflineRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      bbox: bbox ?? this.bbox,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      tileCount: tileCount ?? this.tileCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        bbox.southWest.latitude,
        bbox.southWest.longitude,
        bbox.northEast.latitude,
        bbox.northEast.longitude,
        minZoom,
        maxZoom,
        tileCount,
        sizeBytes,
        downloadedAt,
        status,
      ];
}
