import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/emergency_contact.dart';

/// Static helpers translating between [EmergencyContact] and Firestore
/// document maps. Never instantiated.
class EmergencyContactModel {
  const EmergencyContactModel._();

  static Map<String, Object?> toMap(EmergencyContact c) {
    final map = <String, Object?>{
      'name': c.name,
      'phone': c.phone,
      'isPrimary': c.isPrimary,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (c.relationship != null && c.relationship!.isNotEmpty) {
      map['relationship'] = c.relationship;
    }
    return map;
  }

  /// Same as [toMap] but uses [DateTime.now] for `createdAt` instead of
  /// the server-timestamp sentinel — used by the outbox payload encoder
  /// since `FieldValue.serverTimestamp()` cannot survive JSON round-trip.
  static Map<String, Object?> toJson(EmergencyContact c) {
    final map = <String, Object?>{
      'name': c.name,
      'phone': c.phone,
      'isPrimary': c.isPrimary,
      if (c.createdAt != null)
        'createdAt': c.createdAt!.millisecondsSinceEpoch,
    };
    if (c.relationship != null && c.relationship!.isNotEmpty) {
      map['relationship'] = c.relationship;
    }
    return map;
  }

  static EmergencyContact fromFirestore(
    DocumentSnapshot<Map<String, Object?>> snap,
  ) {
    final data = snap.data() ?? const <String, Object?>{};
    final ts = data['createdAt'];
    return EmergencyContact(
      id: snap.id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      relationship: data['relationship'] as String?,
      isPrimary: (data['isPrimary'] as bool?) ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
