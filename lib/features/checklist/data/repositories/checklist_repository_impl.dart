import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/repositories/checklist_repository.dart';
import '../datasources/checklist_remote_data_source.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistRemoteDataSource _ds;
  const ChecklistRepositoryImpl(this._ds);

  @override
  Stream<List<ChecklistItem>> watchChecklist(String uid) =>
      _ds.watchChecklist(uid);

  @override
  Future<Result<void>> addItem({
    required String uid,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Failure<void>(ValidationError('Please enter something.'));
    }
    if (trimmed.length > ChecklistItem.maxTextLength) {
      return Failure<void>(
        ValidationError(
          'Keep it under ${ChecklistItem.maxTextLength} characters.',
        ),
      );
    }
    return _runVoid(() => _ds.addItem(uid: uid, text: trimmed));
  }

  @override
  Future<Result<void>> toggleItem({
    required String uid,
    required String itemId,
    required bool isDone,
  }) =>
      _runVoid(() => _ds.toggleItem(
            uid: uid,
            itemId: itemId,
            isDone: isDone,
          ));

  @override
  Future<Result<void>> deleteItem({
    required String uid,
    required String itemId,
  }) =>
      _runVoid(() => _ds.deleteItem(uid: uid, itemId: itemId));

  Future<Result<void>> _runVoid(Future<void> Function() op) async {
    try {
      await op();
      return const Success<void>(null);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return Failure<void>(PermissionError('Not allowed.', cause: e));
      }
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return Failure<void>(NetworkError('Network unavailable.', cause: e));
      }
      return Failure<void>(UnknownError(e.message ?? e.code, cause: e));
    } catch (e) {
      return Failure<void>(UnknownError('Operation failed.', cause: e));
    }
  }
}
