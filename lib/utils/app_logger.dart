import 'dart:developer';

/// A utility class for comprehensive logging throughout the application.
/// It allows for easy enabling/disabling of logs and provides different log levels.
class AppLogger {
  static const String _tag = "APP_LOG"; // Default tag for logs
  static bool _enableLogging = true; // Global flag to control logging

  /// Enables all logging.
  static void enable() {
    _enableLogging = true;
    log("Logging enabled.", name: _tag);
  }

  /// Disables all logging.
  static void disable() {
    _enableLogging = false;
    log("Logging disabled.", name: _tag);
  }

  /// Logs a debug message.
  /// Used for detailed information helpful in debugging.
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    _log("DEBUG: $message", tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs an informational message.
  /// Used for general application flow.
  static void info(String message, {String? tag}) {
    if (!_enableLogging) return;
    _log("INFO: $message", tag: tag);
  }

  /// Logs a warning message.
  /// Indicates a potential issue that might not be an error but should be noted.
  static void warning(String message, {String? tag}) {
    if (!_enableLogging) return;
    _log("WARNING: $message", tag: tag);
  }

  /// Logs an error message.
  /// Used for critical issues that prevent normal operation or signify a failure.
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    _log("ERROR: $message", tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal method to handle the actual logging.
  static void _log(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final logTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = "[$timestamp][$logTag] $message";

    log(logMessage, name: logTag); // Use dart:developer's log for better IDE integration

    if (error != null) {
      log("[$timestamp][$logTag] Error Details: $error", name: logTag);
    }
    if (stackTrace != null) {
      log("[$timestamp][$logTag] StackTrace: $stackTrace", name: logTag);
    }
  }
}
