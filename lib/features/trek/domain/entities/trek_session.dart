import 'package:equatable/equatable.dart';

class TrekSession extends Equatable {
  final String id;
  final DateTime startedAt;

  const TrekSession({required this.id, required this.startedAt});

  @override
  List<Object?> get props => [id, startedAt];
}
