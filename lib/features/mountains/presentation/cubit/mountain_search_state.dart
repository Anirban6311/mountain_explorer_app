import 'package:equatable/equatable.dart';

import '../../domain/entities/mountain.dart';

class MountainSearchState extends Equatable {
  final List<Mountain> source;
  final String query;
  final List<Mountain> results;

  const MountainSearchState({
    this.source = const [],
    this.query = '',
    this.results = const [],
  });

  @override
  List<Object?> get props => [source, query, results];
}
