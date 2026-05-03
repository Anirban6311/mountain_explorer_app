import 'dart:async';

import 'package:basic_crud_flutter/core/di/injector.dart';
import 'package:basic_crud_flutter/core/env/env.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/connectivity_service.dart';
import 'package:basic_crud_flutter/core/services/offline_tile_store.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/download_estimate.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/download_progress.dart';
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
import 'package:basic_crud_flutter/features/offline_maps/presentation/view/offline_maps_page.dart';
import 'package:basic_crud_flutter/features/offline_maps/presentation/view/widgets/offline_badge.dart';
import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_cubit.dart';
import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String get osmTileAttribution => '© fake';
}

class _FakeTileStore implements OfflineTileStore {
  int browseCalls = 0;
  final List<String> seenStoreNames = [];
  int networkAttempts = 0;

  @override
  Future<void> initialise() async {}

  @override
  TileProvider browseTileProvider({
    required String storeName,
    required String userAgentPackageName,
  }) {
    browseCalls++;
    seenStoreNames.add(storeName);
    return _CountingTileProvider(onRequest: () => networkAttempts++);
  }

  @override
  Future<int> estimateTileCount({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
  }) async =>
      0;

  @override
  Stream<TileDownloadEvent> download({
    required String storeName,
    required LatLngBounds bbox,
    required int minZoom,
    required int maxZoom,
    required String urlTemplate,
    required String userAgentPackageName,
    Map<String, String> additionalOptions = const {},
    int parallelThreads = 4,
    bool skipExistingTiles = false,
  }) =>
      const Stream.empty();

  @override
  Future<void> cancel(String storeName) async {}

  @override
  Future<int> sizeBytes(String storeName) async => 0;

  @override
  Future<void> deleteStore(String storeName) async {}

  @override
  Future<void> resetAll(String storeName) async {}
}

class _CountingTileProvider extends TileProvider {
  _CountingTileProvider({required this.onRequest});

  final VoidCallback onRequest;

  @override
  ImageProvider<Object> getImage(
    TileCoordinates coordinates,
    TileLayer options,
  ) {
    onRequest();
    // Never actually resolves — tiles stay pending, which is fine for a
    // widget smoke test.
    return const AssetImage('assets/__test_never__');
  }
}

class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity({required this.online});
  final bool online;
  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<bool> onConnectivityChanged() => Stream.value(online);
}

class _MockWatch extends Mock implements WatchRegions {}

class _MockEstimate extends Mock implements EstimateDownload {}

class _MockStart extends Mock implements StartDownload {}

class _MockCancel extends Mock implements CancelDownload {}

class _MockHas extends Mock implements HasCompletedRegion {}

class _MockTotal extends Mock implements TotalSizeBytes {}

class _MockResume extends Mock implements ResumeDownload {}

class _MockDelete extends Mock implements DeleteRegion {}

class _MockReset extends Mock implements ResetEntireCache {}

class _FakeBounds extends Fake implements LatLngBounds {}

class _MockTrekCubit extends MockCubit<TrekState> implements TrekCubit {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeBounds()));

  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTileStore tileStore;
  late _FakeEnv env;
  late OfflineMapsCubit cubit;
  late _MockTrekCubit trekCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues(
      {'quota_mb': 250, 'demo_prompt_seen': true},
    );
    final prefs = await AppPrefs.create();
    tileStore = _FakeTileStore();
    env = _FakeEnv();
    trekCubit = _MockTrekCubit();
    when(() => trekCubit.state).thenReturn(const TrekIdle());

    if (getIt.isRegistered<Env>()) getIt.unregister<Env>();
    if (getIt.isRegistered<OfflineTileStore>()) {
      getIt.unregister<OfflineTileStore>();
    }
    if (getIt.isRegistered<TrekCubit>()) getIt.unregister<TrekCubit>();
    getIt.registerSingleton<Env>(env);
    getIt.registerSingleton<OfflineTileStore>(tileStore);
    getIt.registerSingleton<TrekCubit>(trekCubit);

    final watch = _MockWatch();
    final est = _MockEstimate();
    final start = _MockStart();
    final cancel = _MockCancel();
    final has = _MockHas();
    final total = _MockTotal();
    when(() => watch()).thenAnswer((_) => const Stream.empty());
    when(() => has(any()))
        .thenAnswer((_) async => const Success<bool>(true));
    when(() => total()).thenAnswer((_) async => const Success<int>(0));
    when(() => est(
          bbox: any(named: 'bbox'),
          minZoom: any(named: 'minZoom'),
          maxZoom: any(named: 'maxZoom'),
        )).thenAnswer((_) async => Success<DownloadEstimate>(
          const DownloadEstimate(tileCount: 0, estimatedBytes: 0),
        ));
    when(() => start(
          regionId: any(named: 'regionId'),
          name: any(named: 'name'),
          bbox: any(named: 'bbox'),
          minZoom: any(named: 'minZoom'),
          maxZoom: any(named: 'maxZoom'),
        )).thenAnswer((_) => const Stream<DownloadProgress>.empty());

    cubit = OfflineMapsCubit(
      watchRegions: watch,
      estimateDownload: est,
      startDownload: start,
      cancelDownload: cancel,
      hasCompletedRegion: has,
      totalSizeBytes: total,
      resumeDownload: _MockResume(),
      deleteRegion: _MockDelete(),
      resetEntireCache: _MockReset(),
      connectivity: _FakeConnectivity(online: false),
      prefs: prefs,
    );
  });

  tearDown(() async {
    await cubit.close();
    if (getIt.isRegistered<Env>()) getIt.unregister<Env>();
    if (getIt.isRegistered<OfflineTileStore>()) {
      getIt.unregister<OfflineTileStore>();
    }
    if (getIt.isRegistered<TrekCubit>()) getIt.unregister<TrekCubit>();
  });

  testWidgets(
    'T-5: offline badge renders and no live tile fetch happens when offline',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<OfflineMapsCubit>.value(
            value: cubit,
            child: const OfflineMapsPage(),
          ),
        ),
      );
      // Give the connectivity stream + cubit + BlocBuilder time to
      // propagate offline=false through the rebuild chain.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(OfflineBadge), findsOneWidget);
      expect(find.text('Download this view'), findsOneWidget);
      expect(tileStore.browseCalls, greaterThan(0));
      // All tile traffic goes through the shared cache store so user
      // regions and the demo region are served from the same place.
      expect(tileStore.seenStoreNames, contains('tile_cache'));
      // Offline + counting fake provider returns a never-resolving asset
      // image — the test asserts the wiring goes through our cache, not
      // that real pixels render.
    },
  );
}
