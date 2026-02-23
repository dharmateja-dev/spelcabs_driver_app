import 'package:logger/logger.dart';

/// A utility class for comprehensive logging throughout the application using the 'logger' package.
/// It wraps the Logger class to provide a consistent interface and allows for easy enabling/disabling.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static bool _enableLogging = true; // Global flag to control logging

  /// Enables all logging.
  static void enable() {
    _enableLogging = true;
    _logger.i("Logging enabled.");
  }

  /// Disables all logging.
  static void disable() {
    _enableLogging = false;
    _logger.i("Logging disabled.");
  }

  /// Logs a debug message.
  static void debug(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    _logger.d("${tag != null ? '[$tag] ' : ''}$message",
        error: error, stackTrace: stackTrace);
  }

  /// Logs an informational message.
  static void info(String message, {String? tag}) {
    if (!_enableLogging) return;
    _logger.i("${tag != null ? '[$tag] ' : ''}$message");
  }

  /// Logs a warning message.
  static void warning(String message, {String? tag}) {
    if (!_enableLogging) return;
    _logger.w("${tag != null ? '[$tag] ' : ''}$message");
  }

  /// Logs an error message.
  static void error(String message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    _logger.e("${tag != null ? '[$tag] ' : ''}$message",
        error: error, stackTrace: stackTrace);
  }
}
