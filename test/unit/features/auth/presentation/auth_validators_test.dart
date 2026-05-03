import 'package:basic_crud_flutter/features/auth/presentation/utils/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('null and empty values are rejected', () {
      expect(AuthValidators.validateEmail(null), contains('email'));
      expect(AuthValidators.validateEmail(''), contains('email'));
      expect(AuthValidators.validateEmail('   '), contains('email'));
    });

    test('obviously malformed values are rejected', () {
      expect(AuthValidators.validateEmail('plainstring'), isNotNull);
      expect(AuthValidators.validateEmail('no@domain'), isNotNull);
      expect(AuthValidators.validateEmail('@nope.com'), isNotNull);
    });

    test('well-formed addresses pass', () {
      expect(AuthValidators.validateEmail('a@b.co'), isNull);
      expect(AuthValidators.validateEmail('a.b+tag@example.co.uk'), isNull);
    });

    test('surrounding whitespace is tolerated', () {
      expect(AuthValidators.validateEmail('  a@b.co  '), isNull);
    });
  });

  group('validatePassword', () {
    test('null/empty rejected', () {
      expect(AuthValidators.validatePassword(null), isNotNull);
      expect(AuthValidators.validatePassword(''), isNotNull);
    });

    test('under 8 chars is rejected', () {
      expect(AuthValidators.validatePassword('ab1'), contains('8'));
      expect(AuthValidators.validatePassword('ab34567'), contains('8'));
    });

    test('exactly 8 chars with letter + digit passes (boundary)', () {
      expect(AuthValidators.validatePassword('abcdef12'), isNull);
    });

    test('8+ chars with only letters is rejected', () {
      expect(AuthValidators.validatePassword('abcdefgh'), contains('letter'));
    });

    test('8+ chars with only digits is rejected', () {
      expect(AuthValidators.validatePassword('12345678'), contains('letter'));
    });
  });

  group('validateDisplayName', () {
    test('null/empty rejected', () {
      expect(AuthValidators.validateDisplayName(null), contains('name'));
      expect(AuthValidators.validateDisplayName(''), contains('name'));
      expect(AuthValidators.validateDisplayName('   '), contains('name'));
    });

    test('names > 40 chars are rejected', () {
      expect(
        AuthValidators.validateDisplayName('a' * 41),
        contains('40'),
      );
    });

    test('valid names pass', () {
      expect(AuthValidators.validateDisplayName('Ada Lovelace'), isNull);
      expect(AuthValidators.validateDisplayName('A' * 40), isNull);
    });
  });
}
