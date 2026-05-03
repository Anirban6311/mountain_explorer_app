import 'package:equatable/equatable.dart';

import '../../domain/entities/checklist_item.dart';

sealed class ChecklistState extends Equatable {
  const ChecklistState();
  @override
  List<Object?> get props => const [];
}

class ChecklistInitial extends ChecklistState {
  const ChecklistInitial();
}

class ChecklistLoading extends ChecklistState {
  const ChecklistLoading();
}

class ChecklistLoaded extends ChecklistState {
  final List<ChecklistItem> items;
  final String? errorMessage;
  const ChecklistLoaded(this.items, {this.errorMessage});
  @override
  List<Object?> get props => [items, errorMessage];
}

class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);
  @override
  List<Object?> get props => [message];
}
