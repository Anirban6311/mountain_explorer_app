import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/usecases/checklist_usecases.dart';
import 'checklist_state.dart';

class ChecklistCubit extends Cubit<ChecklistState> {
  final WatchChecklist _watch;
  final AddChecklistItem _addItem;
  final ToggleChecklistItem _toggleItem;
  final DeleteChecklistItem _deleteItem;

  StreamSubscription<List<ChecklistItem>>? _sub;
  String _uid = '';

  ChecklistCubit({
    required WatchChecklist watchChecklist,
    required AddChecklistItem addChecklistItem,
    required ToggleChecklistItem toggleChecklistItem,
    required DeleteChecklistItem deleteChecklistItem,
  })  : _watch = watchChecklist,
        _addItem = addChecklistItem,
        _toggleItem = toggleChecklistItem,
        _deleteItem = deleteChecklistItem,
        super(const ChecklistInitial());

  /// Subscribes to the current user's checklist stream. Re-call with a new
  /// uid (e.g. on sign-in) to re-subscribe.
  void subscribe(String uid) {
    if (isClosed) return;
    if (uid == _uid && _sub != null) return;
    _uid = uid;
    _sub?.cancel();
    if (uid.isEmpty) return;
    emit(const ChecklistLoading());
    _sub = _watch(uid).listen(
      (items) {
        if (!isClosed) emit(ChecklistLoaded(items));
      },
      onError: (Object e) {
        if (!isClosed) emit(ChecklistError(e.toString()));
      },
    );
  }

  Future<Result<void>> addItem(String text) =>
      _addItem(uid: _uid, text: text);

  Future<Result<void>> toggle(ChecklistItem item) =>
      _toggleItem(uid: _uid, itemId: item.id, isDone: !item.isDone);

  Future<Result<void>> delete(ChecklistItem item) =>
      _deleteItem(uid: _uid, itemId: item.id);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
