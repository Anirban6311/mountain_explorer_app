import 'package:basic_crud_flutter/features/sos/domain/utils/phone_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneNormalizer.normalize', () {
    test('preserves a leading + and strips formatting', () {
      expect(PhoneNormalizer.normalize('+91 98765 43210'), '+919876543210');
      expect(PhoneNormalizer.normalize('+1 (415) 555-0100'), '+14155550100');
    });

    test('strips formatting on a number with no leading +', () {
      expect(PhoneNormalizer.normalize('(987) 654-3210'), '9876543210');
      expect(PhoneNormalizer.normalize('987.654.3210'), '9876543210');
    });

    test('returns null for input below 8 digits', () {
      expect(PhoneNormalizer.normalize('123'), isNull);
      expect(PhoneNormalizer.normalize('+1234567'), isNull);
    });

    test('returns null for input above 15 digits', () {
      expect(PhoneNormalizer.normalize('12345678901234567'), isNull);
    });

    test('returns null for input with no digits', () {
      expect(PhoneNormalizer.normalize('abc'), isNull);
      expect(PhoneNormalizer.normalize(''), isNull);
    });
  });

  group('PhoneNormalizer.isValid', () {
    test('returns true for valid normalized output', () {
      expect(PhoneNormalizer.isValid('+919876543210'), isTrue);
      expect(PhoneNormalizer.isValid('9876543210'), isTrue);
    });

    test('returns false for invalid input', () {
      expect(PhoneNormalizer.isValid('123'), isFalse);
      expect(PhoneNormalizer.isValid(''), isFalse);
    });
  });
}
