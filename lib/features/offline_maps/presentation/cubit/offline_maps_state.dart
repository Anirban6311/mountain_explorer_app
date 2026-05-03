import 'package:equatable/equatable.dart';

import '../../domain/entities/download_progress.dart';
import '../../domain/entities/offline_region.dart';

sealed class OfflineMapsState extends Equatable {
  final bool isOnline;
  final List<OfflineRegion> regions;

  const OfflineMapsState({
    required this.isOnline,
    required this.regions,
  });

  @override
  List<Object?> get props => [isOnline, regions];
}

class MapInitial extends OfflineMapsState {
  const MapInitial({super.isOnline = true, super.regions = const []});
}

class MapReady extends OfflineMapsState {
  const MapReady({required super.isOnline, required super.regions});
}

class MapShowDemoPrompt extends OfflineMapsState {
  const MapShowDemoPrompt({required super.isOnline, required super.regions});
}

class MapDownloading extends OfflineMapsState {
  final DownloadProgress progress;
  const MapDownloading({
    required this.progress,
    required super.isOnline,
    required super.regions,
  });

  @override
  List<Object?> get props => [...super.props, progress];
}

class MapQuotaExceeded extends OfflineMapsState {
  final int neededBytes;
  final int quotaBytes;
  const MapQuotaExceeded({
    required this.neededBytes,
    required this.quotaBytes,
    required super.isOnline,
    required super.regions,
  });

  @override
  List<Object?> get props => [...super.props, neededBytes, quotaBytes];
}

class MapError extends OfflineMapsState {
  final String message;
  const MapError({
    required this.message,
    required super.isOnline,
    required super.regions,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
