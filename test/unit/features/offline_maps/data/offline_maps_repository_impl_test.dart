import 'dart:async';

import 'package:basic_crud_flutter/core/env/env.dart';
import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/offline_tile_store.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/offline_maps/data/datasources/offline_regions_local_data_source.dart';
import 'package:basic_crud_flutter/features/offline_maps/data/repositories/offline_maps_repository_impl.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/offline_region.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDs extends Mock implements OfflineRegionsLocalDataSource {}

class _MockTileStore extends Mock implements OfflineTileStore {}

class _FakeEnv implements Env {
  @override
  String get openWeatherApiKey => 'ow';
  @override
  String? get googleSignInServerClientId => null;
  @override
  String get maptilerApiKey => 'mt';
  @override
  String get osmTileUrlTemplate =>
      'https://example/{z}/{x}/{y}.png?key={apiKey}';
  @override
  String get osmTileAttribution => '© test';
}

class _FakeOfflineRegion extends Fake implements OfflineRegion {}

class _FakeBounds extends Fake implements LatLngBounds {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOfflineRegion());
    registerFallbackValue(_FakeBounds());
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDs ds;
  late _MockTileStore store;
  late AppPrefs prefs;
  late OfflineMapsRepositoryImpl repo;
  final bbox = LatLngBounds(
    const LatLng(27.60, 88.05),
    const LatLng(27.78, 88.25),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({'quota_mb': 250});
    prefs = await AppPrefs.create();
    ds = _MockDs();
    store = _MockTileStore();
    repo = OfflineMapsRepositoryImpl(
      ds: ds,
      tileStore: store,
      prefs: prefs,
      env: _FakeEnv(),
    );
    when(() => ds.insert(any())).thenAnswer((_) async {});
    when(() => ds.update(any())).thenAnswer((_) async {});
    when(() => ds.delete(any())).thenAnswer((_) async {});
    when(() => ds.getById(any())).thenAnswer((_) async => null);
  });

  group('estimate', () {
    test('multiplies tile count by 30KB', () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 100);
      final result = await repo.estimate(bbox: bbox, minZoom: 10, maxZoom: 14);
      expect(result, isA<Success>());
      final est = (result as Success).value;
      expect(est.tileCount, 100);
      expect(est.estimatedBytes, 100 * 30 * 1024);
    });
  });

  group('download', () {
    test('rejects when over quota', () async {
      // 49 000 tiles × 30 KB ≈ 1.4 GB — over the 250 MB quota but under
      // the kMaxTilesPerDownload (50 000) ceiling so we hit the quota
      // check, not the tile-bomb guard.
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 49000);
      when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);

      final events = await repo
          .download(
            regionId: 'r1',
            name: 'Test',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();
      expect(events, hasLength(1));
      expect(events.first.hasError, isTrue);
      expect(events.first.errorMessage, contains('quota'));
      verifyNever(() => ds.insert(any()));
    });

    test('under quota inserts row then streams progress then completes',
        () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 10);
      when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);
      when(() => store.sizeBytes(any())).thenAnswer((_) async => 51200);
      when(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
          )).thenAnswer((_) => Stream.fromIterable([
            const TileDownloadEvent(
              tilesDone: 5,
              tilesTotal: 10,
              bytesDone: 25600,
              isComplete: false,
            ),
            const TileDownloadEvent(
              tilesDone: 10,
              tilesTotal: 10,
              bytesDone: 51200,
              isComplete: true,
            ),
          ]));

      final events = await repo
          .download(
            regionId: 'r1',
            name: 'Test',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();

      // First call should insert the row with status=downloading.
      verify(() => ds.insert(any())).called(1);
      // Final completion call should update status=complete.
      verify(() => ds.update(any(
            that: predicate<OfflineRegion>(
              (r) => r.status == OfflineRegionStatus.complete,
            ),
          ))).called(1);
      expect(events.map((e) => e.tilesDone), [5, 10]);
      expect(events.last.isComplete, isTrue);
    });

    test('rejects tile-bomb (count > kMaxTilesPerDownload)', () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 200000);
      when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);
      final events = await repo
          .download(
            regionId: 'r1',
            name: 'Test',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();
      expect(events, hasLength(1));
      expect(events.first.errorMessage, contains('too large'));
      verifyNever(() => ds.insert(any()));
    });

    test('redacts apiKey query string from upstream error messages',
        () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenThrow(Exception(
        'GET https://api.maptiler.com/maps/x/y.png?apiKey=secret_key_123 failed',
      ));
      final events = await repo
          .download(
            regionId: 'r1',
            name: 'Test',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();
      expect(events.first.errorMessage, isNot(contains('secret_key_123')));
      expect(events.first.errorMessage, contains('redacted'));
    });

    test('dedupes by deleting an existing non-complete row first', () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 5);
      when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);
      when(() => ds.getById('r1')).thenAnswer((_) async => OfflineRegion(
            id: 'r1',
            name: 'Old',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
            tileCount: 0,
            sizeBytes: 0,
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
            status: OfflineRegionStatus.failed,
          ));
      when(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
          )).thenAnswer((_) => const Stream<TileDownloadEvent>.empty());

      await repo
          .download(
            regionId: 'r1',
            name: 'New',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();
      verify(() => ds.delete('r1')).called(1);
      verify(() => ds.insert(any())).called(1);
    });

    test('plugin error marks row failed and surfaces errorMessage',
        () async {
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 10);
      when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);
      when(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
          )).thenAnswer((_) => Stream.fromIterable([
            const TileDownloadEvent(
              tilesDone: 0,
              tilesTotal: 0,
              bytesDone: 0,
              isComplete: true,
              errorMessage: 'boom',
            ),
          ]));

      final events = await repo
          .download(
            regionId: 'r1',
            name: 'Test',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
          )
          .toList();
      expect(events.any((e) => e.hasError), isTrue);
      verify(() => ds.update(any(
            that: predicate<OfflineRegion>(
              (r) => r.status == OfflineRegionStatus.failed,
            ),
          ))).called(1);
    });
  });

  group('cancelDownload', () {
    test('calls store.cancel and marks row partial', () async {
      when(() => store.cancel(any())).thenAnswer((_) async {});
      when(() => store.sizeBytes(any())).thenAnswer((_) async => 1024);
      when(() => ds.getById('r1')).thenAnswer((_) async => OfflineRegion(
            id: 'r1',
            name: 'T',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
            tileCount: 0,
            sizeBytes: 0,
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
            status: OfflineRegionStatus.downloading,
          ));
      final result = await repo.cancelDownload('r1');
      expect(result, isA<Success>());
      verify(() => store.cancel('r1')).called(1);
      verify(() => ds.update(any(
            that: predicate<OfflineRegion>(
              (r) => r.status == OfflineRegionStatus.partial,
            ),
          ))).called(1);
    });
  });

  group('hasCompletedRegion', () {
    test('returns true only when row exists with complete status', () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => OfflineRegion(
            id: 'r1',
            name: 'T',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
            tileCount: 0,
            sizeBytes: 0,
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
            status: OfflineRegionStatus.complete,
          ));
      final ok = await repo.hasCompletedRegion('r1');
      expect((ok as Success).value, isTrue);
    });

    test('returns false when missing', () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => null);
      final got = await repo.hasCompletedRegion('r1');
      expect((got as Success).value, isFalse);
    });

    test('returns false when status is partial', () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => OfflineRegion(
            id: 'r1',
            name: 'T',
            bbox: bbox,
            minZoom: 10,
            maxZoom: 14,
            tileCount: 0,
            sizeBytes: 0,
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
            status: OfflineRegionStatus.partial,
          ));
      final got = await repo.hasCompletedRegion('r1');
      expect((got as Success).value, isFalse);
    });
  });

  group('deleteRegion', () {
    test('removes the sqflite row and does NOT touch the tile store',
        () async {
      // Iter 3 decision #24: delete is row-only because FMTC v9 has a
      // single shared store; the delete dialog warns the user.
      final got = await repo.deleteRegion('r1');
      expect(got, isA<Success<void>>());
      verify(() => ds.delete('r1')).called(1);
      verifyNever(() => store.deleteStore(any()));
    });

    test('maps DAO failure to UnknownError', () async {
      when(() => ds.delete(any())).thenThrow(Exception('disk full'));
      final got = await repo.deleteRegion('r1');
      expect(got, isA<Failure<void>>());
      expect((got as Failure<void>).error, isA<UnknownError>());
    });
  });
}
