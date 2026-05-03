import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/app_error.dart';

/// Thin seam over `Geolocator`'s static API to make [GeolocatorLocationService]
/// testable without platform channels.
abstract class GeolocatorFacade {
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<Position> getCurrentPosition({LocationSettings? locationSettings});
  Stream<Position> getPositionStream({LocationSettings? locationSettings});
}

class _RealGeolocator implements GeolocatorFacade {
  const _RealGeolocator();
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      Geolocator.getCurrentPosition(locationSettings: locationSettings);
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      Geolocator.getPositionStream(locationSettings: locationSettings);
}

abstract class LocationService {
  Future<bool> hasForegroundPermission();
  Future<bool> requestForegroundPermission();
  Future<bool> hasBackgroundPermission();

  /// Must be called only after the background-location disclosure screen has
  /// been shown and accepted. Throws [StateError] if foreground permission
  /// hasn't been granted first (Android escalation requirement).
  Future<bool> requestBackgroundPermission();

  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  });

  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration interval = const Duration(seconds: 30),
  });

  /// Long-running background-friendly position stream. On Android, the
  /// `geolocator` plugin starts a foreground service tied to the
  /// supplied [notificationTitle]/[notificationBody]; on iOS this
  /// requires `UIBackgroundModes: location` (added in Iter 5b).
  ///
  /// The stream survives app backgrounding while the foreground service
  /// is alive. Cancelling the subscription tears down the service.
  Stream<Position> trekPositionStream({
    required Duration interval,
    required String notificationTitle,
    required String notificationBody,
  });

  Future<bool> isLocationServiceEnabled();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({GeolocatorFacade? facade})
      : _facade = facade ?? const _RealGeolocator();

  final GeolocatorFacade _facade;

  @override
  Future<bool> hasForegroundPermission() async {
    try {
      final p = await _facade.checkPermission();
      return p == LocationPermission.whileInUse ||
          p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestForegroundPermission() async {
    try {
      final current = await _facade.checkPermission();
      if (current == LocationPermission.whileInUse ||
          current == LocationPermission.always) {
        return true;
      }
      final result = await _facade.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasBackgroundPermission() async {
    try {
      final p = await _facade.checkPermission();
      return p == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestBackgroundPermission() async {
    final current = await _facade.checkPermission();
    if (current != LocationPermission.whileInUse &&
        current != LocationPermission.always) {
      throw StateError(
        'Foreground location permission must be granted before requesting '
        'background permission.',
      );
    }
    if (current == LocationPermission.always) return true;
    final result = await _facade.requestPermission();
    return result == LocationPermission.always;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!await hasForegroundPermission()) {
      throw const PermissionError('Location permission not granted.');
    }
    try {
      return await _facade.getCurrentPosition(
        locationSettings: _buildSettings(accuracy, timeout),
      );
    } on TimeoutException catch (e) {
      throw NetworkError('Location fix timed out.', cause: e);
    } on LocationServiceDisabledException catch (e) {
      throw PermissionError('Location services are disabled.', cause: e);
    } on PermissionDeniedException catch (e) {
      throw PermissionError('Location permission denied.', cause: e);
    } catch (e) {
      throw UnknownError('Failed to get location.', cause: e);
    }
  }

  @override
  Stream<Position> positionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration interval = const Duration(seconds: 30),
  }) {
    return _facade.getPositionStream(
      locationSettings: _buildStreamSettings(accuracy, interval),
    );
  }

  @override
  Stream<Position> trekPositionStream({
    required Duration interval,
    required String notificationTitle,
    required String notificationBody,
  }) {
    return _facade.getPositionStream(
      locationSettings: _buildTrekSettings(
        interval: interval,
        notificationTitle: notificationTitle,
        notificationBody: notificationBody,
      ),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() => _facade.isLocationServiceEnabled();

  LocationSettings _buildSettings(LocationAccuracy accuracy, Duration timeout) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(accuracy: accuracy, timeLimit: timeout);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(accuracy: accuracy, timeLimit: timeout);
    }
    return LocationSettings(accuracy: accuracy, timeLimit: timeout);
  }

  LocationSettings _buildStreamSettings(
    LocationAccuracy accuracy,
    Duration interval,
  ) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        intervalDuration: interval,
        distanceFilter: 5,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(accuracy: accuracy, distanceFilter: 5);
    }
    return LocationSettings(accuracy: accuracy, distanceFilter: 5);
  }

  /// Trek-mode settings. On Android we attach a
  /// [ForegroundNotificationConfig] so the plugin keeps a foreground
  /// service alive while the trek is recording. iOS gets background
  /// updates via Info.plist's `UIBackgroundModes: [location]` (added in
  /// Iter 5b); until then the iOS path mirrors the regular stream.
  LocationSettings _buildTrekSettings({
    required Duration interval,
    required String notificationTitle,
    required String notificationBody,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: interval,
        distanceFilter: 20,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationBody,
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
  }
}
