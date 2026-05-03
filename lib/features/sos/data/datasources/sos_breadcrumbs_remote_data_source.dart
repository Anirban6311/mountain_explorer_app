import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../trek/domain/entities/breadcrumb.dart';

abstract class SosBreadcrumbsRemoteDataSource {
  /// Appends a single breadcrumb to
  /// `sos_alerts/{alertId}/breadcrumbs/{tsMs}`. The document id is the
  /// breadcrumb's epoch ms so re-deliveries from the position stream
  /// are idempotent (an at-least-once retry overwrites the same doc).
  Future<void> append(String alertId, Breadcrumb crumb);
}

class FirestoreSosBreadcrumbsRemoteDataSource
    implements SosBreadcrumbsRemoteDataSource {
  FirestoreSosBreadcrumbsRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  @override
  Future<void> append(String alertId, Breadcrumb crumb) async {
    final tsMs = crumb.ts.millisecondsSinceEpoch;
    final data = <String, Object?>{
      'ts': tsMs,
      'lat': crumb.lat,
      'lng': crumb.lng,
    };
    if (crumb.accuracy != null) data['accuracy'] = crumb.accuracy;
    if (crumb.altitude != null) data['altitude'] = crumb.altitude;
    if (crumb.battery != null) data['battery'] = crumb.battery;
    await _db
        .collection('sos_alerts')
        .doc(alertId)
        .collection('breadcrumbs')
        .doc(tsMs.toString())
        .set(data);
  }
}
