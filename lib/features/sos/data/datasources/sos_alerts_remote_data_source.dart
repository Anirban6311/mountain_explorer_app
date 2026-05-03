import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sos_alert.dart';
import '../models/sos_alert_model.dart';

abstract class SosAlertsRemoteDataSource {
  /// Creates a new `sos_alerts/{auto-id}` document; returns the new id.
  Future<String> create(SosAlert alert);

  /// Re-creates a document from a previously-serialized outbox payload.
  /// Returns the new id.
  Future<String> createFromJson(Map<String, Object?> payload);

  /// Marks an alert cancelled.
  Future<void> cancel(String alertId);

  /// Returns the ids of `status == 'active'` alerts owned by [uid] that
  /// were created on or before [cutoff]. Used by the cold-start 6h
  /// timeout flush (Iter 5b EC-3).
  Future<List<String>> findExpiredActiveIds(String uid, DateTime cutoff);

  /// Updates [alertId] to `status: 'timed_out'`. Pairs with
  /// [findExpiredActiveIds].
  Future<void> markTimedOut(String alertId);
}

class FirestoreSosAlertsRemoteDataSource implements SosAlertsRemoteDataSource {
  FirestoreSosAlertsRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, Object?>> get _col =>
      _db.collection('sos_alerts');

  @override
  Future<String> create(SosAlert alert) async {
    final doc = await _col.add(SosAlertModel.toMap(alert));
    return doc.id;
  }

  @override
  Future<String> createFromJson(Map<String, Object?> payload) async {
    // Replace the epoch-ms timestamps with `serverTimestamp()` so Firestore
    // stores a real Timestamp on retry-from-outbox. Iter 1's outbox schema
    // stores the ms snapshot; we discard it on replay.
    final map = Map<String, Object?>.from(payload)
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['lastSeenAt'] = FieldValue.serverTimestamp();
    final doc = await _col.add(map);
    return doc.id;
  }

  @override
  Future<void> cancel(String alertId) {
    return _col.doc(alertId).update({
      'status': 'cancelled',
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<String>> findExpiredActiveIds(
    String uid,
    DateTime cutoff,
  ) async {
    final snap = await _col
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  @override
  Future<void> markTimedOut(String alertId) {
    return _col.doc(alertId).update({
      'status': 'timed_out',
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }
}
