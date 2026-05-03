import 'package:basic_crud_flutter/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logger', () {
    const logger = Logger();

    test('debug/info/warn/error do not throw', () {
      expect(() => logger.debug('d'), returnsNormally);
      expect(() => logger.info('i'), returnsNormally);
      expect(() => logger.warn('w'), returnsNormally);
      expect(() => logger.error('e'), returnsNormally);
    });

    test('accepts optional error and stack trace', () {
      final st = StackTrace.current;
      expect(
        () => logger.error('boom', error: Exception('x'), stackTrace: st),
        returnsNormally,
      );
    });

    test('LogLevel enum has expected values', () {
      expect(LogLevel.values, [
        LogLevel.debug,
        LogLevel.info,
        LogLevel.warn,
        LogLevel.error,
      ]);
    });
  });
}
