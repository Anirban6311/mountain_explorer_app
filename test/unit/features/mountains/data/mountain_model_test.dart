import 'package:basic_crud_flutter/features/mountains/data/models/mountain_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MountainModel.fromJson', () {
    test('reads lat and lng when present as numbers', () {
      final m = MountainModel.fromJson({
        'name': 'Shimla',
        'imageUrl': 'http://example/img',
        'description': 'd',
        'lat': 31.1048,
        'lng': 77.1734,
      });
      expect(m.lat, 31.1048);
      expect(m.lng, 77.1734);
    });

    test('coerces int coordinates to double', () {
      final m = MountainModel.fromJson({
        'name': 'X',
        'imageUrl': '',
        'description': '',
        'lat': 30,
        'lng': 75,
      });
      expect(m.lat, 30.0);
      expect(m.lng, 75.0);
    });

    test('returns null lat/lng when fields are missing', () {
      final m = MountainModel.fromJson({
        'name': 'Old Mountain',
        'imageUrl': '',
        'description': '',
      });
      expect(m.lat, isNull);
      expect(m.lng, isNull);
    });

    test('returns null lat/lng when fields are explicit null', () {
      final m = MountainModel.fromJson({
        'name': 'Old Mountain',
        'imageUrl': '',
        'description': '',
        'lat': null,
        'lng': null,
      });
      expect(m.lat, isNull);
      expect(m.lng, isNull);
    });

    test('slug is computed from name when id is absent', () {
      final m = MountainModel.fromJson({'name': 'Mount Abu'});
      expect(m.id, 'mount-abu');
    });

    test('id from positional arg overrides the slug', () {
      final m = MountainModel.fromJson({'name': 'Shimla'}, id: 'sh1');
      expect(m.id, 'sh1');
    });
  });
}
