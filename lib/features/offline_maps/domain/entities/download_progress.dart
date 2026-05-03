import 'package:equatable/equatable.dart';

class DownloadProgress extends Equatable {
  final String regionId;
  final int tilesDone;
  final int tilesTotal;
  final int bytesDone;
  final bool isComplete;
  final bool isCancelled;
  final String? errorMessage;

  const DownloadProgress({
    required this.regionId,
    required this.tilesDone,
    required this.tilesTotal,
    required this.bytesDone,
    required this.isComplete,
    this.isCancelled = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;

  @override
  List<Object?> get props => [
        regionId,
        tilesDone,
        tilesTotal,
        bytesDone,
        isComplete,
        isCancelled,
        errorMessage,
      ];
}
