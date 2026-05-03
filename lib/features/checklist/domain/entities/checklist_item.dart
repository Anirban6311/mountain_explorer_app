import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String text;
  final bool isDone;
  final DateTime createdAt;

  const ChecklistItem({
    required this.id,
    required this.text,
    required this.isDone,
    required this.createdAt,
  });

  static const int maxTextLength = 120;

  @override
  List<Object?> get props => [id, text, isDone, createdAt];
}
