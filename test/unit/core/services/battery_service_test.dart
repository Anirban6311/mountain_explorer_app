import 'dart:async';

import 'package:basic_crud_flutter/core/services/battery_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBattery extends Mock implements Battery {}

void main() {
  group('BatteryPlusBatteryService', () {
    late _MockBattery battery;
    late BatteryPlusBatteryService service;

    setUp(() {
      battery = _MockBattery();
      service = BatteryPlusBatteryService(battery: battery);
    });

    test('level() forwards Battery.batteryLevel', () async {
      when(() => battery.batteryLevel).thenAnswer((_) async => 73);
      expect(await service.level(), 73);
    });

    test('isCharging returns true for charging state', () async {
      when(() => battery.batteryState)
          .thenAnswer((_) async => BatteryState.charging);
      expect(await service.isCharging(), isTrue);
    });

    test('isCharging returns true for connectedNotCharging (full)', () async {
      when(() => battery.batteryState)
          .thenAnswer((_) async => BatteryState.full);
      expect(await service.isCharging(), isTrue);
    });

    test('isCharging returns false for discharging', () async {
      when(() => battery.batteryState)
          .thenAnswer((_) async => BatteryState.discharging);
      expect(await service.isCharging(), isFalse);
    });

    test('onLevelChanged re-polls level on each battery-state event',
        () async {
      final controller = StreamController<BatteryState>.broadcast();
      when(() => battery.onBatteryStateChanged)
          .thenAnswer((_) => controller.stream);
      final levels = <int>[40, 41, 42];
      var i = 0;
      when(() => battery.batteryLevel)
          .thenAnswer((_) async => levels[i++]);

      final expected = expectLater(
        service.onLevelChanged(),
        emitsInOrder([40, 41, 42, emitsDone]),
      );

      // give onListen time to attach the upstream subscription
      await Future<void>.delayed(Duration.zero);
      controller.add(BatteryState.discharging);
      controller.add(BatteryState.charging);
      controller.add(BatteryState.discharging);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await controller.close();

      await expected;
    });
  });
}
