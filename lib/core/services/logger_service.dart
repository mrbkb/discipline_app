// ============================================
// FICHIER PRODUCTION FINAL : lib/core/services/logger_service.dart
// ✅ Système de logging professionnel avec désactivation en production
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
  
  // ✅ CONFIGURATION PRODUCTION
  // Debug logs uniquement en mode développement
  static const bool _enableDebugLogs = kDebugMode;
  // Info logs toujours actifs (utiles pour tracking)
  static const bool _enableInfoLogs = true;
  
  // ========== PUBLIC API ==========
  
  /// Log debug message (développement uniquement)
  /// Exemples: état interne, valeurs calculées, flow de navigation
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (!_enableDebugLogs) return;
    _log(LogLevel.debug, message, tag: tag, data: data);
  }
  
  /// Log info message (production aussi)
  /// Exemples: user actions, état de l'app, milestones
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    if (!_enableInfoLogs && !kDebugMode) return;
    _log(LogLevel.info, message, tag: tag, data: data);
  }
  
  /// Log warning (toujours actif)
  /// Exemples: opération échouée mais récupérable, état incohérent
  static void warning(String message, {String? tag, Object? error, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, error: error, data: data);
  }
  
  /// Log error (toujours actif)
  /// Exemples: exceptions catchées, opérations échouées critiques
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }
  
  /// Log critical error (toujours actif)
  /// Exemples: crashes, perte de données, état irréversible
  /// TODO: Envoyer à Firebase Crashlytics en production
  static void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
    
    // TODO: En production, envoyer à Crashlytics
    // if (kReleaseMode) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }
  
  // ========== INTERNAL IMPLEMENTATION ==========
  
  /// Méthode interne de logging
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Formatter le timestamp
    final timestamp = DateTime.now().toIso8601String();
    
    // Formatter le niveau
    final levelStr = level.name.toUpperCase().padRight(8);
    
    // Tag par défaut ou custom
    final tagStr = tag ?? _tag;
    
    // Message principal
    final logMessage = '[$timestamp] [$levelStr] [$tagStr] $message';
    
    // Affichage selon le niveau
    switch (level) {
      case LogLevel.debug:
        _printDebug(logMessage, data: data);
        break;
        
      case LogLevel.info:
        _printInfo(logMessage, data: data);
        break;
        
      case LogLevel.warning:
        _printWarning(logMessage, error: error, data: data);
        break;
        
      case LogLevel.error:
        _printError(logMessage, error: error, stackTrace: stackTrace, data: data);
        break;
        
      case LogLevel.critical:
        _printCritical(logMessage, error: error, stackTrace: stackTrace, data: data);
        break;
    }
  }
  
  // ========== FORMATTERS ==========
  
  static void _printDebug(String message, {Map<String, dynamic>? data}) {
    // Couleur: gris (default console)
    print(message);
    if (data != null && data.isNotEmpty) {
      print('  📊 Data: ${_formatData(data)}');
    }
  }
  
  static void _printInfo(String message, {Map<String, dynamic>? data}) {
    // Couleur: bleu
    print('\x1B[34m$message\x1B[0m');
    if (data != null && data.isNotEmpty) {
      print('  📊 Data: ${_formatData(data)}');
    }
  }
  
  static void _printWarning(String message, {Object? error, Map<String, dynamic>? data}) {
    // Couleur: jaune
    print('\x1B[33m$message\x1B[0m');
    if (data != null && data.isNotEmpty) {
      print('  📊 Data: ${_formatData(data)}');
    }
    if (error != null) {
      print('  ⚠️  Error: $error');
    }
  }
  
  static void _printError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Couleur: rouge
    print('\x1B[31m$message\x1B[0m');
    if (data != null && data.isNotEmpty) {
      print('  📊 Data: ${_formatData(data)}');
    }
    if (error != null) {
      print('  ❌ Error: $error');
    }
    if (stackTrace != null) {
      print('  📍 Stack: ${_formatStackTrace(stackTrace)}');
    }
  }
  
  static void _printCritical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Couleur: rouge bold + background
    print('\x1B[41m\x1B[1m$message\x1B[0m');
    if (data != null && data.isNotEmpty) {
      print('  📊 Data: ${_formatData(data)}');
    }
    if (error != null) {
      print('  💀 Error: $error');
    }
    if (stackTrace != null) {
      print('  📍 Stack: ${_formatStackTrace(stackTrace)}');
    }
  }
  
  /// Formater les données en JSON lisible
  static String _formatData(Map<String, dynamic> data) {
    final entries = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '{$entries}';
  }
  
  /// Formater le stacktrace (première ligne uniquement pour lisibilité)
  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    // Retourner les 3 premières lignes pour contexte
    return lines.take(3).join('\n  ');
  }
  
  // ========== HELPERS MÉTIERS ==========
  
  /// Log une action utilisateur
  /// Exemple: LoggerService.logUserAction('habit_completed', habitId: '123')
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User action: $action', tag: 'USER_ACTION', data: data);
  }
  
  /// Log une action sur les habitudes
  static void logHabitAction(String action, String habitId, {Map<String, dynamic>? data}) {
    final enrichedData = {'habitId': habitId, ...?data};
    info('Habit $action', tag: 'HABITS', data: enrichedData);
  }
  
  /// Log une opération de sync
  static void logSync(String operation, {bool success = true, String? message, Map<String, dynamic>? data}) {
    if (success) {
      info('Sync $operation: SUCCESS ${message ?? ''}', tag: 'SYNC', data: data);
    } else {
      error('Sync $operation: FAILED ${message ?? ''}', tag: 'SYNC', data: data);
    }
  }
  
  /// Log une opération Firebase
  static void logFirebase(String operation, {bool success = true, Object? error, Map<String, dynamic>? data}) {
    if (success) {
      debug('Firebase $operation: SUCCESS', tag: 'FIREBASE', data: data);
    } else {
      LoggerService.error('Firebase $operation: FAILED', tag: 'FIREBASE', error: error, data: data);
    }
  }
  
  /// Log une notification
  static void logNotification(String type, {bool success = true, Map<String, dynamic>? data}) {
    if (success) {
      debug('Notification $type: SUCCESS', tag: 'NOTIF', data: data);
    } else {
      warning('Notification $type: FAILED', tag: 'NOTIF', data: data);
    }
  }
  
  // ========== ANALYTICS TRACKING ==========
  
  /// Log un événement analytics
  /// À utiliser en complément de AnalyticsService
  static void logAnalyticsEvent(String event, {Map<String, dynamic>? parameters}) {
    debug('Analytics event: $event', tag: 'ANALYTICS', data: parameters);
  }
  
  // ========== PERFORMANCE TRACKING ==========
  
  /// Mesurer la performance d'une opération
  /// Exemple:
  /// ```dart
  /// final stopwatch = LoggerService.startPerformanceTracking('load_habits');
  /// // ... opération ...
  /// LoggerService.endPerformanceTracking('load_habits', stopwatch);
  /// ```
  static Stopwatch startPerformanceTracking(String operation) {
    debug('Performance tracking started: $operation', tag: 'PERF');
    return Stopwatch()..start();
  }
  
  static void endPerformanceTracking(String operation, Stopwatch stopwatch) {
    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;
    
    // Log warning si l'opération prend trop de temps
    if (duration > 1000) {
      warning('Performance: $operation took ${duration}ms (slow)', tag: 'PERF', data: {
        'operation': operation,
        'duration_ms': duration,
      });
    } else {
      debug('Performance: $operation took ${duration}ms', tag: 'PERF', data: {
        'operation': operation,
        'duration_ms': duration,
      });
    }
  }
}