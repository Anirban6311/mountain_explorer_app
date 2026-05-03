import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

import '../utils/logger.dart';

abstract class BatteryService {
  /// Current battery level, 0–100. Returns null if the platform cannot
  /// report it (e.g. desktop, emulator without power reporting).
  Future<int?> level();

  /// Emits the battery level on each charging-state change. `battery_plus`
  /// does not expose a native "level changed" stream, so this is derived:
  /// on every `BatteryState` event we re-read [Battery.batteryLevel].
  Stream<int> onLevelChanged();

  /// True when the device is charging or connected to power at full.
  Future<bool> isCharging();
}

class BatteryPlusBatteryService implements BatteryService {
  BatteryPlusBatteryService({Battery? battery, Logger? logger})
      : _battery = battery ?? Battery(),
        _logger = logger ?? const Logger();

  final Battery _battery;
  final Logger _logger;

  @override
  Future<int?> level() async {
    try {
      return await _battery.batteryLevel;
    } catch (e, st) {
      _logger.warn('BatteryService.level() failed', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Stream<int> onLevelChanged() {
    const sentinel = -1;
    return _battery.onBatteryStateChanged
        .asyncMap<int>((_) async {
          try {
            return await _battery.batteryLevel;
          } catch (_) {
            return sentinel;
          }
        })
        .where((l) => l != sentinel);
  }

  @override
  Future<bool> isCharging() async {
    final state = await _battery.batteryState;
    return state == BatteryState.charging || state == BatteryState.full;
  }
}
