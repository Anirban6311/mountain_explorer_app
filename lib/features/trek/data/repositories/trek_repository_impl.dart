import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/services/battery_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/app_prefs.dart';
import '../../domain/entities/breadcrumb.dart';
import '../../domain/repositories/trek_repository.dart';
import '../datasources/trek_breadcrumbs_local_data_source.dart';

class TrekRepositoryImpl implements TrekRepository {
  TrekRepositoryImpl({
    required LocationService location,
    required BatteryService battery,
    required TrekBreadcrumbsLocalDataSource ds,
    required AppPrefs prefs,
  })  : _location = location,
        _battery = battery,
        _ds = ds,
        _prefs = prefs;

  static const Duration _normalCadence = Duration(seconds: 120);
  static const Duration _lowBatteryCadence = Duration(seconds: 300);
  static const int _lowBatteryThreshold = 20;

  static const String _notificationTitle = 'Trek active — recording';
  static const String _notificationBody =
      'Mountain Explorer is recording your location for trek breadcrumbs.';

  final LocationService _location;
  final BatteryService _battery;
  final TrekBreadcrumbsLocalDataSource _ds;
  final AppPrefs _prefs;

  StreamSubscription<Position>? _positionSub;
  Duration _activeCadence = _normalCadence;
  int _breadcrumbCount = 0;

  final StreamController<String?> _sessionController =
      StreamController<String?>.broadcast();
  final StreamController<int> _countController =
      StreamController<int>.broadcast();

  @override
  Future<Result<String>> start() async {
    final hasPerm = await _location.hasBackgroundPermission();
    if (!hasPerm) {
      return Failure<String>(
        const PermissionError('Background location permission required.'),
      );
    }

    // Idempotency guard — if a session is already active, return the
    // persisted id rather than spinning up a second position stream
    // (would cause duplicate breadcrumbs + dueling cadence flips).
    if (_positionSub != null) {
      final existing = _prefs.getActiveTrekSessionId();
      if (existing != null) return Success<String>(existing);
    }

    try {
      final id = const Uuid().v4();
      await _prefs.setActiveTrekSessionId(id);
      _breadcrumbCount = 0;
      _sessionController.add(id);
      _countController.add(0);
      _activeCadence = _normalCadence;
      await _subscribeStream();
      return Success<String>(id);
    } catch (e) {
      return Failure<String>(
        UnknownError('Failed to start trek.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _positionSub?.cancel();
      _positionSub = null;
      _breadcrumbCount = 0;
      await _prefs.setActiveTrekSessionId(null);
      _sessionController.add(null);
      _countController.add(0);
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(UnknownError('Failed to stop trek.', cause: e));
    }
  }

  @override
  Stream<String?> watchActiveSessionId() async* {
    yield _prefs.getActiveTrekSessionId();
    yield* _sessionController.stream;
  }

  @override
  Stream<int> watchBreadcrumbCount() async* {
    yield _breadcrumbCount;
    yield* _countController.stream;
  }

  @override
  Future<List<Breadcrumb>> latest({int limit = 50}) =>
      _ds.latest(limit: limit);

  @override
  Future<void> suspend() async {
    await _positionSub?.cancel();
    _positionSub = null;
    // Leave _prefs.activeTrekSessionId / _breadcrumbCount / _activeCadence
    // intact so resume() picks up where we left off.
  }

  @override
  Future<void> resume() async {
    if (_positionSub != null) return;
    if (_prefs.getActiveTrekSessionId() == null) return;
    await _subscribeStream();
  }

  /// Awaits the prior subscription's teardown before wiring a new one.
  /// Without the await, geolocator could buffer one more position event
  /// against the OLD subscription after we re-assign `_positionSub`,
  /// causing a duplicate breadcrumb + a feedback loop on the cadence-flip
  /// state machine.
  Future<void> _subscribeStream() async {
    await _positionSub?.cancel();
    _positionSub = _location
        .trekPositionStream(
          interval: _activeCadence,
          notificationTitle: _notificationTitle,
          notificationBody: _notificationBody,
        )
        .listen(_onPosition, onError: (Object e) {
      _sessionController.addError(e);
    });
  }

  Future<void> _onPosition(Position p) async {
    final battery = await _battery.level();
    // Prefer the GPS fix timestamp from the OS over the moment we
    // processed the event — the fix moment is the truthful answer for
    // the SOS responder's last-known-trail use case.
    final crumb = Breadcrumb(
      ts: p.timestamp,
      lat: p.latitude,
      lng: p.longitude,
      accuracy: p.accuracy,
      altitude: p.altitude,
      battery: battery,
    );
    await _ds.insert(crumb);
    _breadcrumbCount++;
    if (!_countController.isClosed) _countController.add(_breadcrumbCount);

    // Cadence flip — re-subscribe with the longer interval when battery
    // drops below the threshold, and back when it recovers.
    final shouldBeLow =
        battery != null && battery < _lowBatteryThreshold;
    final isLow = _activeCadence == _lowBatteryCadence;
    if (shouldBeLow && !isLow) {
      _activeCadence = _lowBatteryCadence;
      await _subscribeStream();
    } else if (!shouldBeLow && isLow) {
      _activeCadence = _normalCadence;
      await _subscribeStream();
    }
  }
}
