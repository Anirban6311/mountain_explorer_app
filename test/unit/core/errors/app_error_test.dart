import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppError', () {
    test('NetworkError exposes message and cause', () {
      final cause = Exception('socket');
      final error = NetworkError('offline', cause: cause);
      expect(error.message, 'offline');
      expect(error.cause, cause);
      expect(error.toString(), contains('NetworkError'));
      expect(error.toString(), contains('offline'));
    });

    test('AuthError constructs with message', () {
      const error = AuthError('bad creds');
      expect(error.message, 'bad creds');
      expect(error.cause, isNull);
      expect(error.toString(), contains('AuthError'));
    });

    test('NotFoundError constructs with message', () {
      const error = NotFoundError('post missing');
      expect(error.message, 'post missing');
      expect(error.toString(), contains('NotFoundError'));
    });

    test('PermissionError constructs with message', () {
      const error = PermissionError('forbidden');
      expect(error.message, 'forbidden');
      expect(error.toString(), contains('PermissionError'));
    });

    test('ValidationError constructs with message', () {
      const error = ValidationError('required');
      expect(error.message, 'required');
      expect(error.toString(), contains('ValidationError'));
    });

    test('UnknownError constructs with message', () {
      const error = UnknownError('???');
      expect(error.message, '???');
      expect(error.toString(), contains('UnknownError'));
    });

    test('CancelledError defaults to "Cancelled" message', () {
      const error = CancelledError();
      expect(error.message, 'Cancelled');
      expect(error, isA<AppError>());
    });

    test('sealed switch over AppError compiles exhaustively', () {
      const AppError error = NetworkError('x');
      final label = switch (error) {
        NetworkError() => 'net',
        AuthError() => 'auth',
        NotFoundError() => 'not-found',
        PermissionError() => 'perm',
        ValidationError() => 'val',
        UnknownError() => 'unk',
        CancelledError() => 'cancel',
      };
      expect(label, 'net');
    });
  });
}
