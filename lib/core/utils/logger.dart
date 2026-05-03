import 'dart:developer' as developer;

enum LogLevel { debug, info, warn, error }

class Logger {
  const Logger();

  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warn, message, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'app.${level.name}',
      level: _levelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _levelValue(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      };
}
