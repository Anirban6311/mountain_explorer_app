import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../trek/domain/entities/breadcrumb.dart';
import '../../domain/entities/sos_alert.dart';

class SosAlertModel {
  const SosAlertModel._();

  /// SOS-payload shape for a trek breadcrumb. Kept local to the SOS
  /// feature so SOS doesn't reach into another feature's data layer
  /// (`trek/data/models/breadcrumb_model.dart`). The trek-side persistence
  /// and the SOS-payload schema happen to match today; if they ever
  /// diverge, this helper is the seam.
  static Map<String, Object?> _breadcrumbToJson(Breadcrumb b) {
    final m = <String, Object?>{
      'ts': b.ts.millisecondsSinceEpoch,
      'lat': b.lat,
      'lng': b.lng,
    };
    if (b.accuracy != null) m['accuracy'] = b.accuracy;
    if (b.altitude != null) m['altitude'] = b.altitude;
    if (b.battery != null) m['battery'] = b.battery;
    return m;
  }

  /// Map for live Firestore writes — uses `FieldValue.serverTimestamp()`
  /// for `createdAt` and `lastSeenAt`.
  static Map<String, Object?> toMap(SosAlert a) {
    final map = <String, Object?>{
      'uid': a.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': a.status,
      'lat': a.lat,
      'lng': a.lng,
      'userName': a.userName,
      'userEmail': a.userEmail,
      'contactsNotified': a.contactsNotified
          .map((c) => {
                'name': c.name,
                'phone': c.phone,
                'isPrimary': c.isPrimary,
              })
          .toList(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (a.accuracy != null) map['accuracy'] = a.accuracy;
    if (a.altitude != null) map['altitude'] = a.altitude;
    if (a.batteryLevel != null) map['batteryLevel'] = a.batteryLevel;
    if (a.trekBreadcrumbs.isNotEmpty) {
      map['trekBreadcrumbs'] =
          a.trekBreadcrumbs.map(_breadcrumbToJson).toList();
    }
    return map;
  }

  /// JSON-safe map for the outbox payload column. `FieldValue` cannot be
  /// JSON-encoded, so timestamps are captured as epoch ms here and the
  /// retry processor swaps them back to `Timestamp` on enqueue → Firestore.
  static Map<String, Object?> toJson(SosAlert a) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return <String, Object?>{
      'uid': a.uid,
      'createdAt': now,
      'status': a.status,
      'lat': a.lat,
      'lng': a.lng,
      if (a.accuracy != null) 'accuracy': a.accuracy,
      if (a.altitude != null) 'altitude': a.altitude,
      if (a.batteryLevel != null) 'batteryLevel': a.batteryLevel,
      'userName': a.userName,
      'userEmail': a.userEmail,
      'contactsNotified': a.contactsNotified
          .map((c) => {
                'name': c.name,
                'phone': c.phone,
                'isPrimary': c.isPrimary,
              })
          .toList(),
      if (a.trekBreadcrumbs.isNotEmpty)
        'trekBreadcrumbs':
            a.trekBreadcrumbs.map(_breadcrumbToJson).toList(),
      'lastSeenAt': now,
    };
  }
}
