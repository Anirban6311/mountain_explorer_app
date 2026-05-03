import 'dart:async';

import 'package:basic_crud_flutter/core/env/env.dart';
import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/offline_tile_store.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/offline_maps/data/datasources/offline_regions_local_data_source.dart';
import 'package:basic_crud_flutter/features/offline_maps/data/repositories/offline_maps_repository_impl.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/constants.dart';
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

  OfflineRegion partial({String id = 'r1'}) => OfflineRegion(
        id: id,
        name: 'Saved region · 2026-04-25 12:00',
        bbox: bbox,
        minZoom: 10,
        maxZoom: 14,
        tileCount: 50,
        sizeBytes: 100000,
        downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
        status: OfflineRegionStatus.partial,
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
    when(() => ds.deleteAll()).thenAnswer((_) async {});
    when(() => ds.totalSizeBytes()).thenAnswer((_) async => 0);
  });

  group('resume', () {
    test('returns NotFound-style error when region missing', () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => null);
      final events = await repo.resume('r1').toList();
      expect(events, hasLength(1));
      expect(events.first.errorMessage, contains('not found'));
      verifyNever(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          ));
    });

    test('short-circuits when region already complete', () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => partial().copyWith(
            status: OfflineRegionStatus.complete,
            tileCount: 100,
            sizeBytes: 200000,
          ));
      final events = await repo.resume('r1').toList();
      expect(events, hasLength(1));
      expect(events.first.isComplete, isTrue);
      expect(events.first.tilesDone, 100);
      expect(events.first.errorMessage, isNull);
      verifyNever(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
            skipExistingTiles: any(named: 'skipExistingTiles'),
          ));
    });

    test('on partial: re-issues download with skipExistingTiles=true',
        () async {
      when(() => ds.getById('r1')).thenAnswer((_) async => partial());
      when(() => store.estimateTileCount(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
          )).thenAnswer((_) async => 50);
      when(() => store.sizeBytes(any())).thenAnswer((_) async => 100000);
      when(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
            skipExistingTiles: any(named: 'skipExistingTiles'),
          )).thenAnswer((_) => Stream.fromIterable([
            const TileDownloadEvent(
              tilesDone: 50,
              tilesTotal: 50,
              bytesDone: 100000,
              isComplete: true,
            ),
          ]));

      await repo.resume('r1').toList();
      // Verify that download was called with skipExistingTiles=true.
      final captured = verify(() => store.download(
            storeName: any(named: 'storeName'),
            bbox: any(named: 'bbox'),
            minZoom: any(named: 'minZoom'),
            maxZoom: any(named: 'maxZoom'),
            urlTemplate: any(named: 'urlTemplate'),
            userAgentPackageName: any(named: 'userAgentPackageName'),
            additionalOptions: any(named: 'additionalOptions'),
            parallelThreads: any(named: 'parallelThreads'),
            skipExistingTiles: captureAny(named: 'skipExistingTiles'),
          )).captured;
      expect(captured.single, isTrue);
    });
  });

  group('resetEntireCache', () {
    test('drops the FMTC store and the regions table', () async {
      when(() => store.resetAll(any())).thenAnswer((_) async {});
      final result = await repo.resetEntireCache();
      expect(result, isA<Success<void>>());
      verify(() => store.resetAll(kBrowseStoreName)).called(1);
      verify(() => ds.deleteAll()).called(1);
    });

    test('maps tile-store error to UnknownError', () async {
      when(() => store.resetAll(any())).thenThrow(Exception('plugin gone'));
      final result = await repo.resetEntireCache();
      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<UnknownError>());
    });
  });
}
