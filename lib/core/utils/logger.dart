import 'package:logger/logger.dart' as log;

/// Application logger singleton
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static final log.Logger _logger = log.Logger(
    filter: _AppLogFilter(),
    printer: log.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: log.DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: null,
  );

  /// Log debug message
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical message
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log trace message (verbose)
  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}

/// Custom log filter - allows all logs in debug mode
class _AppLogFilter extends log.LogFilter {
  @override
  bool shouldLog(log.LogEvent event) {
    // In production, you might want to filter based on level
    // For now, log everything in debug mode
    return true;
  }
}

/// Extension to make logging easier
extension LoggerExtension on Object {
  void logDebug() => AppLogger.d(toString());
  void logInfo() => AppLogger.i(toString());
  void logWarning() => AppLogger.w(toString());
  void logError([StackTrace? stackTrace]) =>
      AppLogger.e(toString(), null, stackTrace);
}
