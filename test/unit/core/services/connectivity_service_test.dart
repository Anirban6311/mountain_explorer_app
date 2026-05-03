import 'dart:async';

import 'package:basic_crud_flutter/core/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityPlusConnectivityService', () {
    late _MockConnectivity connectivity;
    late ConnectivityPlusConnectivityService service;

    setUp(() {
      connectivity = _MockConnectivity();
      service = ConnectivityPlusConnectivityService(
        connectivity: connectivity,
      );
    });

    test('isOnline returns false when result list is [none]', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await service.isOnline(), isFalse);
    });

    test('isOnline returns true when wifi present', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await service.isOnline(), isTrue);
    });

    test('isOnline returns true when mobile present', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);
      expect(await service.isOnline(), isTrue);
    });

    test('isOnline returns true for wifi+mobile combo', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile],
      );
      expect(await service.isOnline(), isTrue);
    });

    test('onConnectivityChanged maps [none] to false and others to true',
        () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(() => connectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      final emitted = <bool>[];
      final sub = service.onConnectivityChanged().listen(emitted.add);

      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.wifi]);
      controller.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      await controller.close();
      expect(emitted, [false, true, false]);
    });
  });
}
