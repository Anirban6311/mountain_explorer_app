import '../../domain/entities/breadcrumb.dart';

/// Static helpers translating between [Breadcrumb] and the
/// `trek_breadcrumbs` sqflite row shape (and the JSON shape consumed by
/// the SOS Firestore payload).
class BreadcrumbModel {
  const BreadcrumbModel._();

  /// Maps to the row format produced by `INSERT INTO trek_breadcrumbs`.
  /// `id` is auto-incremented by sqflite and is not included.
  static Map<String, Object?> toRow(Breadcrumb b) {
    final map = <String, Object?>{
      'ts': b.ts.millisecondsSinceEpoch,
      'lat': b.lat,
      'lng': b.lng,
    };
    if (b.accuracy != null) map['accuracy'] = b.accuracy;
    if (b.altitude != null) map['altitude'] = b.altitude;
    if (b.battery != null) map['battery'] = b.battery;
    return map;
  }

  static Breadcrumb fromRow(Map<String, Object?> row) {
    return Breadcrumb(
      ts: DateTime.fromMillisecondsSinceEpoch(row['ts']! as int),
      lat: (row['lat']! as num).toDouble(),
      lng: (row['lng']! as num).toDouble(),
      accuracy: (row['accuracy'] as num?)?.toDouble(),
      altitude: (row['altitude'] as num?)?.toDouble(),
      battery: row['battery'] as int?,
    );
  }

  /// JSON shape for the SOS alert payload's `trekBreadcrumbs` field.
  /// Optional fields are omitted when null so the Firestore document is
  /// minimal.
  static Map<String, Object?> toJson(Breadcrumb b) {
    final map = <String, Object?>{
      'ts': b.ts.millisecondsSinceEpoch,
      'lat': b.lat,
      'lng': b.lng,
    };
    if (b.accuracy != null) map['accuracy'] = b.accuracy;
    if (b.altitude != null) map['altitude'] = b.altitude;
    if (b.battery != null) map['battery'] = b.battery;
    return map;
  }
}
