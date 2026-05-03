import 'package:basic_crud_flutter/core/errors/app_error.dart';
import 'package:basic_crud_flutter/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success holds a value', () {
      const result = Success<int>(42);
      expect(result, isA<Success<int>>());
      expect(result.value, 42);
    });

    test('Failure holds an AppError', () {
      const error = UnknownError('boom');
      const result = Failure<int>(error);
      expect(result, isA<Failure<int>>());
      expect(result.error, same(error));
    });

    group('fold', () {
      test('calls onSuccess with the value on Success', () {
        const result = Success<int>(10);
        final folded = result.fold<String>(
          onSuccess: (v) => 'got $v',
          onFailure: (_) => 'nope',
        );
        expect(folded, 'got 10');
      });

      test('calls onFailure with the error on Failure', () {
        const error = NetworkError('offline');
        const result = Failure<int>(error);
        final folded = result.fold<String>(
          onSuccess: (_) => 'nope',
          onFailure: (e) => 'fail: ${e.message}',
        );
        expect(folded, 'fail: offline');
      });
    });

    group('map', () {
      test('transforms value in Success', () {
        const result = Success<int>(3);
        final mapped = result.map<int>((v) => v * 2);
        expect(mapped, isA<Success<int>>());
        expect((mapped as Success<int>).value, 6);
      });

      test('passes through in Failure', () {
        const error = ValidationError('bad');
        const result = Failure<int>(error);
        final mapped = result.map<int>((v) => v * 2);
        expect(mapped, isA<Failure<int>>());
        expect((mapped as Failure<int>).error, same(error));
      });
    });

    group('flatMap', () {
      test('chains Result in Success', () {
        const result = Success<int>(3);
        final chained = result.flatMap<String>((v) => Success('v=$v'));
        expect(chained, isA<Success<String>>());
        expect((chained as Success<String>).value, 'v=3');
      });

      test('short-circuits on Failure', () {
        const error = AuthError('unauth');
        const result = Failure<int>(error);
        final chained = result.flatMap<String>((v) => Success('v=$v'));
        expect(chained, isA<Failure<String>>());
        expect((chained as Failure<String>).error, same(error));
      });

      test('propagates inner Failure', () {
        const result = Success<int>(3);
        const innerError = NotFoundError('missing');
        final chained = result.flatMap<String>((_) => const Failure(innerError));
        expect(chained, isA<Failure<String>>());
        expect((chained as Failure<String>).error, same(innerError));
      });
    });

    test('exhaustive switch compiles without default', () {
      Result<int> r = const Success(1);
      final value = switch (r) {
        Success(value: final v) => v,
        Failure() => 0,
      };
      expect(value, 1);
    });
  });
}
