import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/connectivity_service.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/mountains/domain/entities/mountain.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/constants.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/download_estimate.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/download_progress.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/offline_region.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/cancel_download.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/delete_region.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/estimate_download.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/has_completed_region.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/reset_entire_cache.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/resume_download.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/start_download.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/total_size_bytes.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/watch_regions.dart';
import 'package:basic_crud_flutter/features/offline_maps/presentation/cubit/offline_maps_cubit.dart';
import 'package:basic_crud_flutter/features/offline_maps/presentation/cubit/offline_maps_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockWatch extends Mock implements WatchRegions {}

class _MockEstimate extends Mock implements EstimateDownload {}

class _MockStart extends Mock implements StartDownload {}

class _MockCancel extends Mock implements CancelDownload {}

class _MockHas extends Mock implements HasCompletedRegion {}

class _MockTotal extends Mock implements TotalSizeBytes {}

class _MockResume extends Mock implements ResumeDownload {}

class _MockDelete extends Mock implements DeleteRegion {}

class _MockReset extends Mock implements ResetEntireCache {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _FakeBounds extends Fake implements LatLngBounds {}

OfflineMapsCubit _buildCubit({
  required AppPrefs prefs,
  required _MockWatch watch,
  required _MockEstimate est,
  required _MockStart start,
  required _MockCancel cancel,
  required _MockHas has,
  required _MockTotal total,
  required _MockConnectivity conn,
  ResumeDownload? resume,
  DeleteRegion? delete,
  ResetEntireCache? reset,
}) {
  return OfflineMapsCubit(
    watchRegions: watch,
    estimateDownload: est,
    startDownload: start,
    cancelDownload: cancel,
    hasCompletedRegion: has,
    totalSizeBytes: total,
    resumeDownload: resume ?? _MockResume(),
    deleteRegion: delete ?? _MockDelete(),
    resetEntireCache: reset ?? _MockReset(),
    connectivity: conn,
    prefs: prefs,
  );
}

final _bbox = LatLngBounds(
  const LatLng(27.60, 88.05),
  const LatLng(27.78, 88.25),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeBounds());
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPrefs prefs;
  late _MockWatch watch;
  late _MockEstimate est;
  late _MockStart start;
  late _MockCancel cancel;
  late _MockHas has;
  late _MockTotal total;
  late _MockConnectivity conn;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'quota_mb': 250});
    prefs = await AppPrefs.create();
    watch = _MockWatch();
    est = _MockEstimate();
    start = _MockStart();
    cancel = _MockCancel();
    has = _MockHas();
    total = _MockTotal();
    conn = _MockConnectivity();
    // Default stubs — individual tests may override.
    when(() => watch()).thenAnswer((_) => const Stream<List<OfflineRegion>>.empty());
    when(() => conn.onConnectivityChanged())
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => conn.isOnline()).thenAnswer((_) async => true);
    when(() => has(kDemoRegionId))
        .thenAnswer((_) async => const Success<bool>(false));
  });

  group('onMapVisible', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'shows demo prompt when unseen, online, no demo region',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => has(kDemoRegionId))
            .thenAnswer((_) async => const Success<bool>(false));
        when(() => conn.isOnline()).thenAnswer((_) async => true);
      },
      act: (cubit) => cubit.onMapVisible(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapShowDemoPrompt>());
      },
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'stays at MapReady when demo already seen',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () async {
        SharedPreferences.setMockInitialValues(
            {'quota_mb': 250, 'demo_prompt_seen': true});
        prefs = await AppPrefs.create();
      },
      act: (cubit) => cubit.onMapVisible(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapReady>());
      },
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'stays at MapReady when offline',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => has(kDemoRegionId))
            .thenAnswer((_) async => const Success<bool>(false));
        when(() => conn.isOnline()).thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.onMapVisible(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) => expect(cubit.state, isA<MapReady>()),
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'stays at MapReady when demo region already complete',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => has(kDemoRegionId))
            .thenAnswer((_) async => const Success<bool>(true));
      },
      act: (cubit) => cubit.onMapVisible(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) => expect(cubit.state, isA<MapReady>()),
    );
  });

  group('skipDemoRegion', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'marks demo prompt seen and returns to MapReady',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      act: (cubit) => cubit.skipDemoRegion(),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapReady>());
        expect(prefs.hasSeenDemoPrompt(), isTrue);
      },
    );
  });

  group('startDownloadOfViewport', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'emits MapQuotaExceeded when estimate exceeds quota',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => est(
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) async => Success<DownloadEstimate>(
              const DownloadEstimate(
                tileCount: 999999,
                estimatedBytes: 300 * 1024 * 1024,
              ),
            ));
        when(() => total()).thenAnswer((_) async => const Success<int>(0));
      },
      act: (cubit) => cubit.startDownloadOfViewport(_bbox, 12),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapQuotaExceeded>());
      },
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'under quota: emits Downloading then MapReady on stream completion',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => est(
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) async => const Success<DownloadEstimate>(
              DownloadEstimate(tileCount: 10, estimatedBytes: 300000),
            ));
        when(() => total()).thenAnswer((_) async => const Success<int>(0));
        when(() => start(
              regionId: any(named: 'regionId'),
              name: any(named: 'name'),
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) => Stream.fromIterable([
              const DownloadProgress(
                regionId: 'r',
                tilesDone: 5,
                tilesTotal: 10,
                bytesDone: 150000,
                isComplete: false,
              ),
              const DownloadProgress(
                regionId: 'r',
                tilesDone: 10,
                tilesTotal: 10,
                bytesDone: 300000,
                isComplete: true,
              ),
            ]));
      },
      act: (cubit) => cubit.startDownloadOfViewport(_bbox, 12),
      wait: const Duration(milliseconds: 20),
      verify: (cubit) {
        expect(cubit.state, isA<MapReady>());
      },
    );
  });

  group('cancelActiveDownload', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'no-op when no active download',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      act: (cubit) => cubit.cancelActiveDownload(),
      expect: () => <OfflineMapsState>[],
      verify: (_) {
        verifyNever(() => cancel(any()));
      },
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'invokes the cancel use case for the active region id',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => est(
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) async => const Success<DownloadEstimate>(
              DownloadEstimate(tileCount: 10, estimatedBytes: 300000),
            ));
        when(() => total()).thenAnswer((_) async => const Success<int>(0));
        // Long-running download so we can cancel mid-stream.
        when(() => start(
              regionId: any(named: 'regionId'),
              name: any(named: 'name'),
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) => Stream<DownloadProgress>.periodic(
              const Duration(milliseconds: 50),
              (i) => DownloadProgress(
                regionId: 'r',
                tilesDone: i,
                tilesTotal: 10,
                bytesDone: i * 30000,
                isComplete: false,
              ),
            ).take(20));
        when(() => cancel(any()))
            .thenAnswer((_) async => const Success<void>(null));
      },
      act: (cubit) async {
        await cubit.startDownloadOfViewport(_bbox, 12);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await cubit.cancelActiveDownload();
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => cancel(any())).called(1);
      },
    );
  });

  group('startDownloadOfViewport guard', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'short-circuits when a download is already active',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => est(
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) async => const Success<DownloadEstimate>(
              DownloadEstimate(tileCount: 10, estimatedBytes: 300000),
            ));
        when(() => total()).thenAnswer((_) async => const Success<int>(0));
        // Long-running download — no terminal event so _activeDownloadId
        // stays set and the second call must short-circuit.
        when(() => start(
              regionId: any(named: 'regionId'),
              name: any(named: 'name'),
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) =>
                StreamController<DownloadProgress>().stream);
      },
      act: (cubit) async {
        await cubit.startDownloadOfViewport(_bbox, 12);
        // Second call should be a no-op (active id already set).
        await cubit.startDownloadOfViewport(_bbox, 12);
      },
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => start(
              regionId: any(named: 'regionId'),
              name: any(named: 'name'),
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).called(1);
      },
    );

    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'estimate failure emits MapError',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      setUp: () {
        when(() => est(
              bbox: any(named: 'bbox'),
              minZoom: any(named: 'minZoom'),
              maxZoom: any(named: 'maxZoom'),
            )).thenAnswer((_) async => const Failure<DownloadEstimate>(
              UnknownError('estimate broke'),
            ));
      },
      act: (cubit) => cubit.startDownloadOfViewport(_bbox, 12),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapError>());
      },
    );
  });

  group('connectivity', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'flipping offline updates state.isOnline without changing class',
      build: () {
        final controller = StreamController<bool>();
        when(() => conn.onConnectivityChanged())
            .thenAnswer((_) => controller.stream);
        when(() => conn.isOnline()).thenAnswer((_) async => true);
        when(() => watch())
            .thenAnswer((_) => const Stream<List<OfflineRegion>>.empty());
        scheduleMicrotask(() async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          controller.add(false);
          await controller.close();
        });
        return OfflineMapsCubit(
          watchRegions: watch,
          estimateDownload: est,
          startDownload: start,
          cancelDownload: cancel,
          hasCompletedRegion: has,
          totalSizeBytes: total,
          resumeDownload: _MockResume(),
          deleteRegion: _MockDelete(),
          resetEntireCache: _MockReset(),
          connectivity: conn,
          prefs: prefs,
        );
      },
      wait: const Duration(milliseconds: 30),
      verify: (cubit) {
        expect(cubit.state.isOnline, isFalse);
      },
    );
  });

  group('resumeDownload', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'invokes the resume use case when no active download',
      build: () {
        final resume = _MockResume();
        when(() => resume(any()))
            .thenAnswer((_) => const Stream<DownloadProgress>.empty());
        return _buildCubit(
          prefs: prefs,
          watch: watch,
          est: est,
          start: start,
          cancel: cancel,
          has: has,
          total: total,
          conn: conn,
          resume: resume,
        );
      },
      act: (cubit) async {
        await cubit.resumeDownload('r1');
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        // No state transition because the empty stream completes immediately
        // and the cubit returns to a neutral state.
        expect(cubit.state, isNot(isA<MapDownloading>()));
      },
    );
  });

  group('deleteRegion', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'invokes the delete use case',
      build: () {
        final delete = _MockDelete();
        when(() => delete(any()))
            .thenAnswer((_) async => const Success<void>(null));
        return _buildCubit(
          prefs: prefs,
          watch: watch,
          est: est,
          start: start,
          cancel: cancel,
          has: has,
          total: total,
          conn: conn,
          delete: delete,
        );
      },
      act: (cubit) => cubit.deleteRegion('r1'),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        // No error path → state unchanged.
        expect(cubit.state, isNot(isA<MapError>()));
      },
    );
  });

  group('startDownloadOfMountain', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'rejects mountain with no coordinates via MapError',
      build: () => _buildCubit(
        prefs: prefs,
        watch: watch,
        est: est,
        start: start,
        cancel: cancel,
        has: has,
        total: total,
        conn: conn,
      ),
      act: (cubit) => cubit.startDownloadOfMountain(
        const Mountain(
          id: 'x',
          name: 'X',
          imageUrl: '',
          description: '',
        ),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state, isA<MapError>());
        expect((cubit.state as MapError).message, contains('no coordinates'));
      },
    );

  });

  group('centerOnMountain (no controller attached)', () {
    test('does not throw when MapController is not yet attached',
        () async {
      SharedPreferences.setMockInitialValues({'quota_mb': 250});
      final p = await AppPrefs.create();
      final c = _MockConnectivity();
      final w = _MockWatch();
      when(() => w())
          .thenAnswer((_) => const Stream<List<OfflineRegion>>.empty());
      when(() => c.onConnectivityChanged())
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => c.isOnline()).thenAnswer((_) async => true);

      final cubit = OfflineMapsCubit(
        watchRegions: w,
        estimateDownload: est,
        startDownload: start,
        cancelDownload: cancel,
        hasCompletedRegion: has,
        totalSizeBytes: total,
        resumeDownload: _MockResume(),
        deleteRegion: _MockDelete(),
        resetEntireCache: _MockReset(),
        connectivity: c,
        prefs: p,
      );

      cubit.centerOnMountain(const Mountain(
        id: 'x',
        name: 'X',
        imageUrl: '',
        description: '',
        lat: 30,
        lng: 75,
      ));
      // The move is queued; absence of an exception is the assertion.
      await cubit.close();
    });

    test('skips silently when mountain has no coordinates', () async {
      SharedPreferences.setMockInitialValues({'quota_mb': 250});
      final p = await AppPrefs.create();
      final c = _MockConnectivity();
      final w = _MockWatch();
      when(() => w())
          .thenAnswer((_) => const Stream<List<OfflineRegion>>.empty());
      when(() => c.onConnectivityChanged())
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => c.isOnline()).thenAnswer((_) async => true);

      final cubit = OfflineMapsCubit(
        watchRegions: w,
        estimateDownload: est,
        startDownload: start,
        cancelDownload: cancel,
        hasCompletedRegion: has,
        totalSizeBytes: total,
        resumeDownload: _MockResume(),
        deleteRegion: _MockDelete(),
        resetEntireCache: _MockReset(),
        connectivity: c,
        prefs: p,
      );
      cubit.centerOnMountain(const Mountain(
        id: 'x',
        name: 'X',
        imageUrl: '',
        description: '',
      ));
      await cubit.close();
    });
  });

  group('regions stream', () {
    blocTest<OfflineMapsCubit, OfflineMapsState>(
      'updates regions list when watchRegions emits',
      build: () {
        final controller = StreamController<List<OfflineRegion>>();
        when(() => watch()).thenAnswer((_) => controller.stream);
        when(() => conn.onConnectivityChanged())
            .thenAnswer((_) => const Stream.empty());
        when(() => conn.isOnline()).thenAnswer((_) async => true);
        final cubit = OfflineMapsCubit(
          watchRegions: watch,
          estimateDownload: est,
          startDownload: start,
          cancelDownload: cancel,
          hasCompletedRegion: has,
          totalSizeBytes: total,
          resumeDownload: _MockResume(),
          deleteRegion: _MockDelete(),
          resetEntireCache: _MockReset(),
          connectivity: conn,
          prefs: prefs,
        );
        // Drive one emission then close.
        scheduleMicrotask(() async {
          controller.add([
            OfflineRegion(
              id: 'r1',
              name: 'Test',
              bbox: _bbox,
              minZoom: 10,
              maxZoom: 14,
              tileCount: 0,
              sizeBytes: 0,
              downloadedAt: DateTime.fromMillisecondsSinceEpoch(0),
              status: OfflineRegionStatus.complete,
            )
          ]);
          await controller.close();
        });
        return cubit;
      },
      wait: const Duration(milliseconds: 10),
      verify: (cubit) {
        expect(cubit.state.regions.length, 1);
        expect(cubit.state.regions.first.id, 'r1');
      },
    );
  });
}
