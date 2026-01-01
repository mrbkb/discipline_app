// ============================================
// NOUVEAU FICHIER : lib/core/services/logger_service.dart
// ============================================
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggerService {
  static const String _tag = 'DISCIPLINE';
  
  /// Log debug message (development only)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag);
    }
  }
  
  /// Log info message
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  /// Log warning
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }
  
  /// Log error
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log critical error (crashes, data loss)
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace);
    
    // TODO: Send to crash reporting service (Firebase Crashlytics)
  }
  
  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(8);
    final tagStr = tag ?? _tag;
    
    final logMessage = '[$timestamp] [$levelStr] [$tagStr] $message';
    
    // Print to console
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        print(logMessage);
        break;
      case LogLevel.warning:
        print('\x1B[33m$logMessage\x1B[0m'); // Yellow
        if (error != null) print('  Error: $error');
        break;
      case LogLevel.error:
      case LogLevel.critical:
        print('\x1B[31m$logMessage\x1B[0m'); // Red
        if (error != null) print('  Error: $error');
        if (stackTrace != null) print('  Stack: $stackTrace');
        break;
    }
  }
  
  /// Log habit action
  static void logHabitAction(String action, String habitId, {Map<String, dynamic>? data}) {
    info('Habit $action: $habitId ${data != null ? '- $data' : ''}', tag: 'HABITS');
  }
  
  /// Log sync operation
  static void logSync(String operation, {bool success = true, String? message}) {
    if (success) {
      info('Sync $operation: SUCCESS ${message ?? ''}', tag: 'SYNC');
    } else {
      error('Sync $operation: FAILED ${message ?? ''}', tag: 'SYNC');
    }
  }
  
  /// Log Firebase operation
  static void logFirebase(String operation, {bool success = true, Object? error}) {
    if (success) {
      debug('Firebase $operation: SUCCESS', tag: 'FIREBASE');
    } else {
      error!;
    }
  }
}