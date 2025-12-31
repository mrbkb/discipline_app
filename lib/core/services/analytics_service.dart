

// ============================================
// FICHIER 11/30 : lib/core/services/analytics_service.dart
// ============================================
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> init() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }
  
  // Onboarding
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
  
  // Habit Actions
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
        'is_late': hour > 22,
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
        'was_best_streak': wasBestStreak,
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
  
  // Notifications
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
  
  // Settings
  static Future<void> logHardModeToggled(bool enabled) async {
    await _analytics.logEvent(
      name: 'hard_mode_toggled',
      parameters: {'enabled': enabled},
    );
  }
  
  // Screens
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  // User Properties
  static Future<void> setUserProperties({
    required bool isHardMode,
    required int totalHabits,
    required int avgStreak,
  }) async {
    await _analytics.setUserProperty(
      name: 'hard_mode',
      value: isHardMode.toString(),
    );
    await _analytics.setUserProperty(
      name: 'total_habits',
      value: totalHabits.toString(),
    );
    await _analytics.setUserProperty(
      name: 'avg_streak',
      value: avgStreak.toString(),
    );
  }
}
