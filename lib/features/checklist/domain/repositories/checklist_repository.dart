import '../../../../core/errors/result.dart';
import '../entities/checklist_item.dart';

abstract class ChecklistRepository {
  Stream<List<ChecklistItem>> watchChecklist(String uid);

  Future<Result<void>> addItem({required String uid, required String text});

  Future<Result<void>> toggleItem({
    required String uid,
    required String itemId,
    required bool isDone,
  });

  Future<Result<void>> deleteItem({
    required String uid,
    required String itemId,
  });
}
