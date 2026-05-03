import 'package:basic_crud_flutter/features/trek/data/models/breadcrumb_model.dart';
import 'package:basic_crud_flutter/features/trek/domain/entities/breadcrumb.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbModel', () {
    test('toRow → fromRow round-trips with all fields', () {
      final b = Breadcrumb(
        ts: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        lat: 27.7,
        lng: 88.15,
        accuracy: 10,
        altitude: 1500,
        battery: 73,
      );
      final row = BreadcrumbModel.toRow(b);
      final back = BreadcrumbModel.fromRow(row);
      expect(back.ts, b.ts);
      expect(back.lat, 27.7);
      expect(back.lng, 88.15);
      expect(back.accuracy, 10);
      expect(back.altitude, 1500);
      expect(back.battery, 73);
    });

    test('fromRow tolerates missing optional fields', () {
      final back = BreadcrumbModel.fromRow({
        'ts': 1700000000000,
        'lat': 1.0,
        'lng': 2.0,
      });
      expect(back.accuracy, isNull);
      expect(back.altitude, isNull);
      expect(back.battery, isNull);
    });

    test('toJson omits null optional fields', () {
      final b = Breadcrumb(
        ts: DateTime.fromMillisecondsSinceEpoch(0),
        lat: 1,
        lng: 2,
      );
      final j = BreadcrumbModel.toJson(b);
      expect(j['ts'], 0);
      expect(j.containsKey('accuracy'), isFalse);
      expect(j.containsKey('altitude'), isFalse);
      expect(j.containsKey('battery'), isFalse);
    });

    test('toJson includes optional fields when set', () {
      final b = Breadcrumb(
        ts: DateTime.fromMillisecondsSinceEpoch(0),
        lat: 1,
        lng: 2,
        accuracy: 5,
        altitude: 100,
        battery: 50,
      );
      final j = BreadcrumbModel.toJson(b);
      expect(j['accuracy'], 5);
      expect(j['altitude'], 100);
      expect(j['battery'], 50);
    });
  });
}
