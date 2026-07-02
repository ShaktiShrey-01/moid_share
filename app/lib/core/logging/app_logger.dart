import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application logging facade.
///
/// The rest of the codebase depends on [AppLogger], never on the `logger`
/// package directly. This keeps the logging implementation swappable (e.g.
/// forwarding to Crashlytics/Sentry later) and lets us silence verbose logs in
/// release builds from a single place.
abstract interface class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});
  void info(String message, {Object? error, StackTrace? stackTrace});
  void warn(String message, {Object? error, StackTrace? stackTrace});
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// Default [AppLogger] backed by the `logger` package.
///
/// In release builds the log level is raised to [Level.warning] so debug/info
/// noise is dropped and no sensitive data leaks to device logs.
class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger()
      : _logger = Logger(
          level: kReleaseMode ? Level.warning : Level.debug,
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 100,
            colors: !kReleaseMode,
            printEmojis: !kReleaseMode,
          ),
        );

  final Logger _logger;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
