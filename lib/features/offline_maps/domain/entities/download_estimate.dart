import 'package:equatable/equatable.dart';

class DownloadEstimate extends Equatable {
  final int tileCount;
  final int estimatedBytes;

  const DownloadEstimate({
    required this.tileCount,
    required this.estimatedBytes,
  });

  @override
  List<Object?> get props => [tileCount, estimatedBytes];
}
