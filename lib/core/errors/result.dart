import 'app_error.dart';

sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success<T>(value: final v) => onSuccess(v),
      Failure<T>(error: final e) => onFailure(e),
    };
  }

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final v) => Success<R>(transform(v)),
      Failure<T>(error: final e) => Failure<R>(e),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final v) => transform(v),
      Failure<T>(error: final e) => Failure<R>(e),
    };
  }
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}
