import '../../../../core/errors/result.dart';
import '../entities/checklist_item.dart';
import '../repositories/checklist_repository.dart';

class WatchChecklist {
  final ChecklistRepository _repo;
  const WatchChecklist(this._repo);
  Stream<List<ChecklistItem>> call(String uid) => _repo.watchChecklist(uid);
}

class AddChecklistItem {
  final ChecklistRepository _repo;
  const AddChecklistItem(this._repo);
  Future<Result<void>> call({required String uid, required String text}) =>
      _repo.addItem(uid: uid, text: text);
}

class ToggleChecklistItem {
  final ChecklistRepository _repo;
  const ToggleChecklistItem(this._repo);
  Future<Result<void>> call({
    required String uid,
    required String itemId,
    required bool isDone,
  }) =>
      _repo.toggleItem(uid: uid, itemId: itemId, isDone: isDone);
}

class DeleteChecklistItem {
  final ChecklistRepository _repo;
  const DeleteChecklistItem(this._repo);
  Future<Result<void>> call({required String uid, required String itemId}) =>
      _repo.deleteItem(uid: uid, itemId: itemId);
}
