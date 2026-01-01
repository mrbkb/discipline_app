// ============================================
// FICHIER CORRIGÉ : lib/core/services/analytics_service.dart
// ============================================
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> init() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }
  
  // ========== GENERIC EVENT LOGGING ==========
  
  /// Log a generic event with optional parameters
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  // ========== ONBOARDING ==========
  
  static Future<void> logOnboardingCompleted({
    required String nickname,
    required int habitsCount,
  }) async {
    await _analytics.logEvent(
      name: 'onboarding_completed',
      parameters: {
        'nickname': nickname,
        'habits_count': habitsCount,
      },
    );
  }
  
  // ========== HABIT ACTIONS ==========
  
  static Future<void> logHabitValidated({
    required String habitId,
    required String habitTitle,
    required int currentStreak,
    required int hour,
  }) async {
    await _analytics.logEvent(
      name: 'habit_validated',
      parameters: {
        'habit_id': habitId,
        'habit_title': habitTitle,
        'current_streak': currentStreak,
        'hour': hour,
        'is_late': hour > 22 ? 1 : 0, 
      },
    );
  }
  
  static Future<void> logStreakBroken({
    required String habitId,
    required int lostStreak,
    required bool wasBestStreak,
  }) async {
    await _analytics.logEvent(
      name: 'streak_broken',
      parameters: {
        'habit_id': habitId,
        'lost_streak': lostStreak,
        'was_best_streak': wasBestStreak ? 1 : 0,
      },
    );
  }
  
  static Future<void> logDayValidated({
    required int completedHabits,
    required int totalHabits,
  }) async {
    await _analytics.logEvent(
      name: 'day_validated',
      parameters: {
        'completed_habits': completedHabits,
        'total_habits': totalHabits,
        'completion_rate': completedHabits / totalHabits,
      },
    );
  }
  
  // ========== NOTIFICATIONS ==========
  
  static Future<void> logNotificationOpened({
    required String notifType,
    required int missedDays,
  }) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'notif_type': notifType,
        'missed_days': missedDays,
      },
    );
  }
  
  // ========== SETTINGS ==========
  
  /// ✅ FIX CRITIQUE: Convertir boolean en string
  static Future<void> logHardModeToggled(bool enabled) async {
    await _analytics.logEvent(
      name: 'hard_mode_toggled',
      parameters: {
        'enabled': enabled ? 'true' : 'false', // ✅ STRING au lieu de BOOLEAN
      },
    );
  }
  
  // ========== SCREENS ==========
  
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  // ========== USER PROPERTIES ==========
  
  /// ✅ FIX CRITIQUE: Tous les user properties doivent être STRING
  static Future<void> setUserProperties({
    required bool isHardMode,
    required int totalHabits,
    required int avgStreak,
  }) async {
    // ✅ Convertir TOUT en string
    await _analytics.setUserProperty(
      name: 'hard_mode',
      value: isHardMode ? 'true' : 'false', // ✅ STRING
    );
    await _analytics.setUserProperty(
      name: 'total_habits',
      value: totalHabits.toString(), // ✅ STRING
    );
    await _analytics.setUserProperty(
      name: 'avg_streak',
      value: avgStreak.toString(), // ✅ STRING
    );
  }
  
  // ========== CUSTOM EVENTS ==========
  
  /// Log when user creates a new habit
  static Future<void> logHabitCreated({
    required String habitTitle,
    bool hasEmoji = false,
  }) async {
    await _analytics.logEvent(
      name: 'habit_created',
      parameters: {
        'habit_title': habitTitle,
        'has_emoji': hasEmoji ? 1 : 0,
      },
    );
  }
  
  /// Log when user archives a habit
  static Future<void> logHabitArchived(String habitId) async {
    await _analytics.logEvent(
      name: 'habit_archived',
      parameters: {'habit_id': habitId},
    );
  }
  
  /// Log when user deletes a habit
  static Future<void> logHabitDeleted(String habitId) async {
    await _analytics.logEvent(
      name: 'habit_deleted',
      parameters: {'habit_id': habitId},
    );
  }
  
  /// Log app launch
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }
  
  /// Log when user performs backup
  static Future<void> logBackupPerformed() async {
    await _analytics.logEvent(
      name: 'backup_performed',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }
  
  /// Log when user restores data
  static Future<void> logRestorePerformed() async {
    await _analytics.logEvent(
      name: 'restore_performed',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }
}