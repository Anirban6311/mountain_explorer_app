import 'package:basic_crud_flutter/core/services/offline_tile_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TileDownloadEvent', () {
    test('identical field values are equal', () {
      const a = TileDownloadEvent(
        tilesDone: 10,
        tilesTotal: 100,
        bytesDone: 1024,
        isComplete: false,
      );
      const b = TileDownloadEvent(
        tilesDone: 10,
        tilesTotal: 100,
        bytesDone: 1024,
        isComplete: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different tilesDone is not equal', () {
      const a = TileDownloadEvent(
        tilesDone: 10,
        tilesTotal: 100,
        bytesDone: 0,
        isComplete: false,
      );
      const b = TileDownloadEvent(
        tilesDone: 11,
        tilesTotal: 100,
        bytesDone: 0,
        isComplete: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('error event is distinct from success', () {
      const a = TileDownloadEvent(
        tilesDone: 0,
        tilesTotal: 0,
        bytesDone: 0,
        isComplete: true,
      );
      const b = TileDownloadEvent(
        tilesDone: 0,
        tilesTotal: 0,
        bytesDone: 0,
        isComplete: true,
        errorMessage: 'boom',
      );
      expect(a, isNot(equals(b)));
    });
  });
}
