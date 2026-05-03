import 'dart:async';

import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:basic_crud_flutter/core/services/location_service.dart';
import 'package:basic_crud_flutter/core/storage/app_prefs.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/start_trek.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/stop_trek.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/watch_active_session.dart';
import 'package:basic_crud_flutter/features/trek/domain/usecases/watch_breadcrumb_count.dart';
import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_cubit.dart';
import 'package:basic_crud_flutter/features/trek/presentation/cubit/trek_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStart extends Mock implements StartTrek {}

class _MockStop extends Mock implements StopTrek {}

class _MockWatchSession extends Mock implements WatchActiveTrekSession {}

class _MockWatchCount extends Mock implements WatchBreadcrumbCount {}

class _MockLocation extends Mock implements LocationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStart start;
  late _MockStop stop;
  late _MockWatchSession watchSession;
  late _MockWatchCount watchCount;
  late _MockLocation location;
  late AppPrefs prefs;
  late StreamController<String?> sessionController;
  late StreamController<int> countController;

  Future<TrekCubit> build() async => TrekCubit(
        startTrek: start,
        stopTrek: stop,
        watchSession: watchSession,
        watchCount: watchCount,
        location: location,
        prefs: prefs,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPrefs.create();
    start = _MockStart();
    stop = _MockStop();
    watchSession = _MockWatchSession();
    watchCount = _MockWatchCount();
    location = _MockLocation();
    sessionController = StreamController<String?>.broadcast();
    countController = StreamController<int>.broadcast();
    when(() => watchSession()).thenAnswer((_) => sessionController.stream);
    when(() => watchCount()).thenAnswer((_) => countController.stream);
    when(() => location.hasBackgroundPermission())
        .thenAnswer((_) async => true);
  });

  tearDown(() async {
    await sessionController.close();
    await countController.close();
  });

  test('bootstrap with no stored session emits TrekIdle', () async {
    final cubit = await build();
    await cubit.bootstrap();
    expect(cubit.state, isA<TrekIdle>());
    expect(cubit.state.hasBackgroundPermission, isTrue);
    await cubit.close();
  });

  test('bootstrap with stored session but no permission clears the pref',
      () async {
    await prefs.setActiveTrekSessionId('s1');
    when(() => location.hasBackgroundPermission())
        .thenAnswer((_) async => false);
    final cubit = await build();
    await cubit.bootstrap();
    expect(cubit.state, isA<TrekIdle>());
    expect(prefs.getActiveTrekSessionId(), isNull);
    await cubit.close();
  });

  test('bootstrap with stored session and permission re-issues start',
      () async {
    await prefs.setActiveTrekSessionId('s1');
    when(() => start()).thenAnswer((_) async => const Success<String>('s2'));
    final cubit = await build();
    await cubit.bootstrap();
    verify(() => start()).called(1);
    await cubit.close();
  });

  test('start with permission already granted invokes the start use case',
      () async {
    when(() => start()).thenAnswer((_) async => const Success<String>('s1'));
    final cubit = await build();
    // No BuildContext path needed because hasBackgroundPermission==true.
    await cubit.start(_FakeContext());
    verify(() => start()).called(1);
    await cubit.close();
  });

  test('start use-case Failure transitions to TrekError', () async {
    when(() => start())
        .thenAnswer((_) async => const Failure<String>(UnknownError('nope')));
    final cubit = await build();
    await cubit.start(_FakeContext());
    expect(cubit.state, isA<TrekError>());
    expect((cubit.state as TrekError).message, 'nope');
    await cubit.close();
  });

  test('session stream null emits TrekIdle; non-null emits TrekActive',
      () async {
    final cubit = await build();
    sessionController.add('session-1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, isA<TrekActive>());
    expect((cubit.state as TrekActive).sessionId, 'session-1');
    sessionController.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state, isA<TrekIdle>());
    await cubit.close();
  });

  test('count stream updates breadcrumbCount only when active', () async {
    final cubit = await build();
    sessionController.add('s1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    countController.add(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect((cubit.state as TrekActive).breadcrumbCount, 7);
    await cubit.close();
  });

  test('stop calls the stop use case', () async {
    when(() => stop()).thenAnswer((_) async => const Success<void>(null));
    final cubit = await build();
    await cubit.stop();
    verify(() => stop()).called(1);
    await cubit.close();
  });

  test('session stream error clears active session pref + emits TrekError',
      () async {
    await prefs.setActiveTrekSessionId('s1');
    final cubit = await build();
    sessionController.addError(Exception('background permission revoked'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state, isA<TrekError>());
    expect((cubit.state as TrekError).hasBackgroundPermission, isFalse);
    expect(prefs.getActiveTrekSessionId(), isNull);
    await cubit.close();
  });
}

/// Lightweight stand-in. The cubit's `start` only consults the context
/// when permission is missing; in this test suite permission is granted
/// in setUp, so the context is unused.
class _FakeContext extends Mock implements BuildContext {}
