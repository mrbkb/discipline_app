// ============================================
// FICHIER FINAL : lib/core/services/alarm_notification_service.dart
// ✅ Migration complète - Gère TOUTES les notifications
// ============================================
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'dart:math';
import 'logger_service.dart';
import '../constants/notification_messages.dart';
import '../../data/models/user_model.dart';

class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // ========== IDS DES ALARMES ==========
  static const int MAIN_REMINDER_ID = 0;
  static const int LATE_REMINDER_ID = 1;
  static const int HARD_MODE_ID = 2;
  
  // IDs pour les notifications immédiates (milestones, etc.)
  static const int MILESTONE_ID = 100;
  static const int STREAK_BROKEN_ID = 99;
  static const int TEST_ID = 999;
  
  // ========== INITIALISATION ==========
  
  /// ✅ Initialiser le service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      LoggerService.info('Initializing AlarmNotificationService', tag: 'ALARM_NOTIF');
      
      // 1. Initialiser AndroidAlarmManager
      final alarmInitialized = await AndroidAlarmManager.initialize();
      
      if (!alarmInitialized) {
        LoggerService.error('AndroidAlarmManager init failed', tag: 'ALARM_NOTIF');
        return false;
      }
      
      // 2. Initialiser FlutterLocalNotifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidSettings);
      
      final notifInitialized = await _notifications.initialize(settings);
      
      if (notifInitialized != true) {
        LoggerService.error('Notifications init failed', tag: 'ALARM_NOTIF');
        return false;
      }
      
      _isInitialized = true;
      LoggerService.info('AlarmNotificationService initialized successfully', tag: 'ALARM_NOTIF');
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Init error', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  // ========== PERMISSIONS ==========
  
  /// ✅ Demander toutes les permissions nécessaires
  static Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        LoggerService.error('Android plugin not found', tag: 'ALARM_NOTIF');
        return false;
      }
      
      // 1. Permission de notifications (Android 13+)
      LoggerService.debug('Requesting notification permission', tag: 'ALARM_NOTIF');
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      
      if (notifGranted != true) {
        LoggerService.warning('Notification permission denied', tag: 'ALARM_NOTIF');
        return false;
      }
      
      // 2. Permission d'alarmes exactes (Android 12+)
      LoggerService.debug('Checking exact alarm permission', tag: 'ALARM_NOTIF');
      final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
      
      if (canScheduleExact != true) {
        LoggerService.warning('Requesting exact alarm permission', tag: 'ALARM_NOTIF');
        final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
        
        if (alarmGranted != true) {
          LoggerService.error('Exact alarm permission denied', tag: 'ALARM_NOTIF');
          return false;
        }
      }
      
      LoggerService.info('All permissions granted', tag: 'ALARM_NOTIF');
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Permission request failed', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Vérifier si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) return false;
      
      final enabled = await androidPlugin.areNotificationsEnabled();
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      
      return (enabled ?? false) && (canSchedule ?? false);
      
    } catch (e) {
      LoggerService.error('Failed to check status', tag: 'ALARM_NOTIF', error: e);
      return false;
    }
  }
  
  // ========== PROGRAMMATION DEPUIS USERMODEL ==========
  
  /// ✅ MÉTHODE PRINCIPALE : Programmer depuis UserModel
  static Future<bool> scheduleDailyFromUser(UserModel user) async {
    if (!user.notificationsEnabled) {
      LoggerService.info('Notifications disabled by user', tag: 'ALARM_NOTIF');
      await cancelAll();
      return true;
    }
    
    return await scheduleDaily(
      hour: user.reminderHour,
      minute: user.reminderMinute,
      lateHour: user.lateReminderHour,
      lateMinute: user.lateReminderMinute,
      isHardMode: user.isHardMode,
    );
  }
  
  /// ✅ Programmer les alarmes quotidiennes
  static Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required int lateHour,
    required int lateMinute,
    required bool isHardMode,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // 1. Vérifier les permissions
      final hasPermissions = await areNotificationsEnabled();
      if (!hasPermissions) {
        LoggerService.warning('Cannot schedule: no permissions', tag: 'ALARM_NOTIF');
        return false;
      }
      
      // 2. Annuler les alarmes existantes
      await cancelAll();
      
      LoggerService.info('Scheduling alarms', tag: 'ALARM_NOTIF', data: {
        'main_hour': hour,
        'main_minute': minute,
        'late_hour': lateHour,
        'late_minute': lateMinute,
        'hard_mode': isHardMode,
      });
      
      int successCount = 0;
      
      // 3. Programmer rappel principal
      try {
        final mainTime = _calculateNextOccurrence(hour, minute);
        final success = await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          MAIN_REMINDER_ID,
          _showMainReminder,
          startAt: mainTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        
        if (success) {
          successCount++;
          LoggerService.info('Main reminder scheduled', tag: 'ALARM_NOTIF', data: {
            'time': mainTime.toString(),
            'minutes_until': mainTime.difference(DateTime.now()).inMinutes,
          });
        } else {
          LoggerService.error('Failed to schedule main reminder', tag: 'ALARM_NOTIF');
        }
      } catch (e, stack) {
        LoggerService.error('Error scheduling main reminder', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      }
      
      // 4. Programmer rappel tardif
      try {
        final lateTime = _calculateNextOccurrence(lateHour, lateMinute);
        final success = await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          LATE_REMINDER_ID,
          _showLateReminder,
          startAt: lateTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        
        if (success) {
          successCount++;
          LoggerService.info('Late reminder scheduled', tag: 'ALARM_NOTIF', data: {
            'time': lateTime.toString(),
            'minutes_until': lateTime.difference(DateTime.now()).inMinutes,
          });
        } else {
          LoggerService.error('Failed to schedule late reminder', tag: 'ALARM_NOTIF');
        }
      } catch (e, stack) {
        LoggerService.error('Error scheduling late reminder', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      }
      
      // 5. Programmer mode violence si activé (23h)
      if (isHardMode) {
        try {
          final hardTime = _calculateNextOccurrence(23, 0);
          final success = await AndroidAlarmManager.periodic(
            const Duration(days: 1),
            HARD_MODE_ID,
            _showHardModeReminder,
            startAt: hardTime,
            exact: true,
            wakeup: true,
            rescheduleOnReboot: true,
          );
          
          if (success) {
            successCount++;
            LoggerService.info('Hard mode reminder scheduled', tag: 'ALARM_NOTIF', data: {
              'time': hardTime.toString(),
              'minutes_until': hardTime.difference(DateTime.now()).inMinutes,
            });
          } else {
            LoggerService.error('Failed to schedule hard mode reminder', tag: 'ALARM_NOTIF');
          }
        } catch (e, stack) {
          LoggerService.error('Error scheduling hard mode reminder', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
        }
      }
      
      // 6. Vérifier le résultat
      final expectedCount = isHardMode ? 3 : 2;
      final allScheduled = successCount >= expectedCount;
      
      LoggerService.info('Alarm scheduling complete', tag: 'ALARM_NOTIF', data: {
        'scheduled': successCount,
        'expected': expectedCount,
        'success': allScheduled,
      });
      
      return allScheduled;
      
    } catch (e, stack) {
      LoggerService.error('Schedule failed', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  // ========== CALLBACKS DES ALARMES ==========
  
  /// ✅ Callback pour le rappel principal
  @pragma('vm:entry-point')
  static Future<void> _showMainReminder() async {
    LoggerService.info('Main reminder triggered', tag: 'ALARM_NOTIF');
    await _showNotification(
      id: MAIN_REMINDER_ID,
      title: 'Discipline 🔥',
      body: _getRandomMessage(NotificationMessages.doux),
    );
  }
  
  /// ✅ Callback pour le rappel tardif
  @pragma('vm:entry-point')
  static Future<void> _showLateReminder() async {
    LoggerService.info('Late reminder triggered', tag: 'ALARM_NOTIF');
    await _showNotification(
      id: LATE_REMINDER_ID,
      title: 'Discipline ⚠️',
      body: _getRandomMessage(NotificationMessages.piment),
    );
  }
  
  /// ✅ Callback pour le mode violence
  @pragma('vm:entry-point')
  static Future<void> _showHardModeReminder() async {
    LoggerService.info('Hard mode reminder triggered', tag: 'ALARM_NOTIF');
    await _showNotification(
      id: HARD_MODE_ID,
      title: 'DISCIPLINE 💀',
      body: _getRandomMessage(NotificationMessages.violence),
    );
  }
  
  // ========== NOTIFICATIONS IMMÉDIATES ==========
  
  /// ✅ Milestone atteint
  static Future<void> showStreakMilestone(String habitTitle, int streak) async {
    if (!_isInitialized) return;
    
    String message;
    if (streak == 7) {
      message = '🔥 7 jours de $habitTitle ! Tu deviens redoutable';
    } else if (streak == 14) {
      message = '💪 14 jours ! Les résultats arrivent';
    } else if (streak == 21) {
      message = '👑 21 jours ! Une habitude est née';
    } else if (streak == 30) {
      message = '🚀 30 jours ! Tu es une machine';
    } else if (streak == 60) {
      message = '⚡ 60 jours ! Tu es inarrêtable';
    } else if (streak == 90) {
      message = '🏆 90 jours ! Légende absolue';
    } else {
      return;
    }
    
    try {
      await _showNotification(
        id: MILESTONE_ID,
        title: 'Milestone Atteint ! 🎉',
        body: message,
      );
      
      LoggerService.info('Milestone notification shown', tag: 'ALARM_NOTIF', data: {
        'streak': streak,
        'habit': habitTitle,
      });
      
    } catch (e) {
      LoggerService.error('Failed to show milestone', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  /// ✅ Streak perdu
  static Future<void> showStreakBroken(String habitTitle, int lostStreak) async {
    if (!_isInitialized) return;
    
    try {
      await _showNotification(
        id: STREAK_BROKEN_ID,
        title: 'Streak Perdu 💔',
        body: '$habitTitle: $lostStreak jours perdus. Recommence plus fort !',
      );
      
      LoggerService.info('Streak broken notification shown', tag: 'ALARM_NOTIF', data: {
        'habit': habitTitle,
        'lost': lostStreak,
      });
      
    } catch (e) {
      LoggerService.error('Failed to show streak broken', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  // ========== HELPERS ==========
  
  /// ✅ Calculer la prochaine occurrence
  static DateTime _calculateNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Si l'heure est déjà passée, programmer pour demain
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
  
  /// ✅ Afficher une notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      const androidChannel = AndroidNotificationDetails(
        'daily_reminder',
        'Rappels Quotidiens',
        channelDescription: 'Notifications de rappel pour les habitudes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: true,
      );
      
      const notificationDetails = NotificationDetails(android: androidChannel);
      
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
      );
      
      LoggerService.info('Notification shown', tag: 'ALARM_NOTIF', data: {
        'id': id,
        'title': title,
      });
      
    } catch (e, stack) {
      LoggerService.error('Failed to show notification', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
    }
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  // ========== ANNULATION ==========
  
  /// ✅ Annuler toutes les alarmes
  static Future<void> cancelAll() async {
    try {
      await AndroidAlarmManager.cancel(MAIN_REMINDER_ID);
      await AndroidAlarmManager.cancel(LATE_REMINDER_ID);
      await AndroidAlarmManager.cancel(HARD_MODE_ID);
      
      LoggerService.info('All alarms cancelled', tag: 'ALARM_NOTIF');
    } catch (e) {
      LoggerService.error('Cancel failed', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  /// ✅ Lister les notifications programmées
  /// ⚠️ NOTE: Ceci liste uniquement les notifications locales,
  /// PAS les alarmes AndroidAlarmManager (qui sont dans le système Android)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      final pending = await _notifications.pendingNotificationRequests();
      
      LoggerService.debug('Pending LOCAL notifications', tag: 'ALARM_NOTIF', data: {
        'count': pending.length,
      });
      
      return pending;
      
    } catch (e) {
      LoggerService.error('Failed to get pending', tag: 'ALARM_NOTIF', error: e);
      return [];
    }
  }
  
  /// ✅ NOUVELLE MÉTHODE: Vérifier si les alarmes sont probablement actives
  /// On ne peut pas vraiment lister les alarmes AndroidAlarmManager,
  /// donc on vérifie juste que le service est initialisé et les permissions OK
  static Future<bool> areAlarmsActive() async {
    if (!_isInitialized) return false;
    return await areNotificationsEnabled();
  }
  
  // ========== TESTS ==========
  
  /// ✅ Test immédiat
  static Future<bool> testNotification() async {
    if (!_isInitialized) return false;
    
    try {
      await _showNotification(
        id: TEST_ID,
        title: 'Test Discipline 🔥',
        body: 'Si tu vois ce message, les notifications fonctionnent !',
      );
      
      LoggerService.info('Test notification sent', tag: 'ALARM_NOTIF');
      return true;
      
    } catch (e) {
      LoggerService.error('Test failed', tag: 'ALARM_NOTIF', error: e);
      return false;
    }
  }
  
  /// ✅ Test programmé dans 1 minute
  static Future<void> testIn1Minute() async {
    if (!_isInitialized) await initialize();
    
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    
    await AndroidAlarmManager.oneShotAt(
      testTime,
      TEST_ID,
      _testCallback,
      exact: true,
      wakeup: true,
    );
    
    LoggerService.info('Test alarm scheduled', tag: 'ALARM_NOTIF', data: {
      'time': testTime.toString(),
    });
  }
  
  @pragma('vm:entry-point')
  static Future<void> _testCallback() async {
    LoggerService.info('TEST ALARM TRIGGERED!', tag: 'ALARM_NOTIF');
    await _showNotification(
      id: TEST_ID,
      title: 'Test Réussi ! ⏰',
      body: 'L\'alarme fonctionne même quand l\'app est fermée !',
    );
  }
}