import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/checklist_item.dart';

class ChecklistItemModel extends ChecklistItem {
  const ChecklistItemModel({
    required super.id,
    required super.text,
    required super.isDone,
    required super.createdAt,
  });

  factory ChecklistItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final ts = data['createdAt'];
    return ChecklistItemModel(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      isDone: (data['isDone'] as bool?) ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
