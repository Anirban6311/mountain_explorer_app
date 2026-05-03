sealed class AppError {
  final String message;
  final Object? cause;

  const AppError(this.message, {this.cause});

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.cause});
}

class AuthError extends AppError {
  const AuthError(super.message, {super.cause});
}

class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.cause});
}

class PermissionError extends AppError {
  const PermissionError(super.message, {super.cause});
}

class ValidationError extends AppError {
  const ValidationError(super.message, {super.cause});
}

class UnknownError extends AppError {
  const UnknownError(super.message, {super.cause});
}

/// Signals that a user-initiated flow (e.g. Google sign-in sheet) was
/// dismissed before completion. Consumers typically treat this as a
/// benign cancellation — no snackbar, no retry.
class CancelledError extends AppError {
  const CancelledError([super.message = 'Cancelled']);
}
