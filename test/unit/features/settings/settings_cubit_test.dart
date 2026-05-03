import 'dart:async';

import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/entities/offline_region.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/total_size_bytes.dart';
import 'package:basic_crud_flutter/features/offline_maps/domain/usecases/watch_regions.dart';
import 'package:basic_crud_flutter/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:basic_crud_flutter/features/settings/presentation/cubit/settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockTotal extends Mock implements TotalSizeBytes {}

class _MockWatch extends Mock implements WatchRegions {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPrefs prefs;
  late _MockTotal total;
  late _MockWatch watch;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'quota_mb': 250});
    prefs = await AppPrefs.create();
    total = _MockTotal();
    watch = _MockWatch();
    when(() => total())
        .thenAnswer((_) async => const Success<int>(42 * 1024 * 1024));
    when(() => watch())
        .thenAnswer((_) => const Stream<List<OfflineRegion>>.empty());
  });

  blocTest<SettingsCubit, SettingsState>(
    'load populates quotaMb and totalUsedBytes',
    build: () => SettingsCubit(
      prefs: prefs,
      totalSizeBytes: total,
      watchRegions: watch,
    ),
    act: (c) => c.load(),
    wait: const Duration(milliseconds: 10),
    verify: (c) {
      expect(c.state.quotaMb, 250);
      expect(c.state.totalUsedBytes, 42 * 1024 * 1024);
      expect(c.state.loading, isFalse);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'setQuota writes to prefs and emits new state',
    build: () => SettingsCubit(
      prefs: prefs,
      totalSizeBytes: total,
      watchRegions: watch,
    ),
    act: (c) async {
      await c.load();
      await c.setQuota(500);
    },
    wait: const Duration(milliseconds: 10),
    verify: (c) {
      expect(c.state.quotaMb, 500);
      expect(prefs.getQuotaMb(), 500);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'setQuota clamps below 50 to 50',
    build: () => SettingsCubit(
      prefs: prefs,
      totalSizeBytes: total,
      watchRegions: watch,
    ),
    act: (c) async {
      await c.load();
      await c.setQuota(10);
    },
    wait: const Duration(milliseconds: 10),
    verify: (c) {
      expect(c.state.quotaMb, 50);
      expect(prefs.getQuotaMb(), 50);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'setQuota clamps above 1000 to 1000',
    build: () => SettingsCubit(
      prefs: prefs,
      totalSizeBytes: total,
      watchRegions: watch,
    ),
    act: (c) async {
      await c.load();
      await c.setQuota(2000);
    },
    wait: const Duration(milliseconds: 10),
    verify: (c) {
      expect(c.state.quotaMb, 1000);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'regions stream emission triggers usage refresh',
    build: () {
      final controller = StreamController<List<OfflineRegion>>();
      when(() => watch()).thenAnswer((_) => controller.stream);
      var callCount = 0;
      when(() => total()).thenAnswer((_) async {
        callCount++;
        return Success<int>(callCount * 1000);
      });
      scheduleMicrotask(() async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        controller.add(const []);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await controller.close();
      });
      return SettingsCubit(
        prefs: prefs,
        totalSizeBytes: total,
        watchRegions: watch,
      );
    },
    act: (c) => c.load(),
    wait: const Duration(milliseconds: 30),
    verify: (c) {
      // Initial load uses callCount=1; the stream emit triggers a 2nd call.
      expect(c.state.totalUsedBytes, greaterThan(1000));
    },
  );
}
