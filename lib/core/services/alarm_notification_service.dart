// ============================================
// FICHIER FIXÉ COMPLET : lib/core/services/alarm_notification_service.dart
// ✅ Callbacks correctement configurés pour fonctionner en isolat
// ✅ Initialisation du plugin dans chaque callback
// ✅ Logs de debug persistants
// ============================================
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'logger_service.dart';
import '../constants/notification_messages.dart';
import '../../data/models/user_model.dart';

/// ✅ CRITIQUE: Annoter la classe pour AOT (release mode)
@pragma('vm:entry-point')
class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // ========== IDS DES ALARMES ==========
  static const int MAIN_REMINDER_ID = 0;
  static const int LATE_REMINDER_ID = 1;
  static const int HARD_MODE_ID = 2;
  
  static const int MILESTONE_ID = 100;
  static const int STREAK_BROKEN_ID = 99;
  static const int TEST_ID = 999;
  
  // ========== INITIALISATION ==========
  
  /// ✅ Initialiser le service (appelé au démarrage de l'app)
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
      await _initializeNotificationPlugin();
      
      _isInitialized = true;
      LoggerService.info('AlarmNotificationService initialized successfully', tag: 'ALARM_NOTIF');
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Init error', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ NOUVEAU: Initialiser le plugin (utilisé dans isolat aussi)
  @pragma('vm:entry-point')
  static Future<void> _initializeNotificationPlugin() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(settings);
    
    _debugLog('Notification plugin initialized');
  }
  
  // ========== PERMISSIONS ==========
  
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
      
      // 1. Permission de notifications
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      
      if (notifGranted != true) {
        LoggerService.warning('Notification permission denied', tag: 'ALARM_NOTIF');
        return false;
      }
      
      // 2. Permission d'alarmes exactes
      final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
      
      if (canScheduleExact != true) {
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
  
  // ========== PROGRAMMATION ==========
  
  /// ✅ Programmer depuis UserModel
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
      final hasPermissions = await areNotificationsEnabled();
      if (!hasPermissions) {
        LoggerService.warning('Cannot schedule: no permissions', tag: 'ALARM_NOTIF');
        return false;
      }
      
      await cancelAll();
      
      LoggerService.info('Scheduling alarms', tag: 'ALARM_NOTIF', data: {
        'main': '$hour:$minute',
        'late': '$lateHour:$lateMinute',
        'hard_mode': isHardMode,
      });
      
      int successCount = 0;
      
      // ✅ Rappel principal
      final mainTime = _calculateNextOccurrence(hour, minute);
      final mainSuccess = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        MAIN_REMINDER_ID,
        _callbackMainReminder,  // ✅ Callback avec préfixe underscore
        startAt: mainTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
      if (mainSuccess) {
        successCount++;
        _debugLog('✅ Main reminder scheduled for ${mainTime.toString()}');
        LoggerService.info('Main reminder scheduled', tag: 'ALARM_NOTIF', data: {
          'time': mainTime.toString(),
          'minutes_until': mainTime.difference(DateTime.now()).inMinutes,
        });
      } else {
        _debugLog('❌ Main reminder scheduling FAILED');
      }
      
      // ✅ Rappel tardif
      final lateTime = _calculateNextOccurrence(lateHour, lateMinute);
      final lateSuccess = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        LATE_REMINDER_ID,
        _callbackLateReminder,
        startAt: lateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
      if (lateSuccess) {
        successCount++;
        _debugLog('✅ Late reminder scheduled for ${lateTime.toString()}');
      } else {
        _debugLog('❌ Late reminder scheduling FAILED');
      }
      
      // ✅ Mode violence
      if (isHardMode) {
        final hardTime = _calculateNextOccurrence(23, 0);
        final hardSuccess = await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          HARD_MODE_ID,
          _callbackHardModeReminder,
          startAt: hardTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        
        if (hardSuccess) {
          successCount++;
          _debugLog('✅ Hard mode reminder scheduled for ${hardTime.toString()}');
        } else {
          _debugLog('❌ Hard mode reminder scheduling FAILED');
        }
      }
      
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
      _debugLog('❌ EXCEPTION: $e');
      return false;
    }
  }
  
  // ========== CALLBACKS (TOP-LEVEL FUNCTIONS) ==========
  
  /// ✅ CRITIQUE: Callback pour rappel principal
  @pragma('vm:entry-point')
  static Future<void> _callbackMainReminder() async {
    _debugLog('🔔 CALLBACK MAIN REMINDER TRIGGERED at ${DateTime.now()}');
    
    try {
      // ✅ IMPORTANT: Réinitialiser le plugin dans l'isolat
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: MAIN_REMINDER_ID,
        title: 'Discipline 🔥',
        body: _getRandomMessage(NotificationMessages.doux),
      );
      
      _debugLog('✅ Main reminder notification shown');
    } catch (e) {
      _debugLog('❌ Main reminder ERROR: $e');
    }
  }
  
  /// ✅ CRITIQUE: Callback pour rappel tardif
  @pragma('vm:entry-point')
  static Future<void> _callbackLateReminder() async {
    _debugLog('🔔 CALLBACK LATE REMINDER TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: LATE_REMINDER_ID,
        title: 'Discipline ⚠️',
        body: _getRandomMessage(NotificationMessages.piment),
      );
      
      _debugLog('✅ Late reminder notification shown');
    } catch (e) {
      _debugLog('❌ Late reminder ERROR: $e');
    }
  }
  
  /// ✅ CRITIQUE: Callback pour mode violence
  @pragma('vm:entry-point')
  static Future<void> _callbackHardModeReminder() async {
    _debugLog('🔔 CALLBACK HARD MODE TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: HARD_MODE_ID,
        title: 'DISCIPLINE 💀',
        body: _getRandomMessage(NotificationMessages.violence),
      );
      
      _debugLog('✅ Hard mode notification shown');
    } catch (e) {
      _debugLog('❌ Hard mode ERROR: $e');
    }
  }
  
  // ========== NOTIFICATIONS IMMÉDIATES ==========
  
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
      await _showNotificationDirect(
        id: MILESTONE_ID,
        title: 'Milestone Atteint ! 🎉',
        body: message,
      );
      
      LoggerService.info('Milestone notification shown', tag: 'ALARM_NOTIF', data: {
        'streak': streak,
      });
      
    } catch (e) {
      LoggerService.error('Failed to show milestone', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  static Future<void> showStreakBroken(String habitTitle, int lostStreak) async {
    if (!_isInitialized) return;
    
    try {
      await _showNotificationDirect(
        id: STREAK_BROKEN_ID,
        title: 'Streak Perdu 💔',
        body: '$habitTitle: $lostStreak jours perdus. Recommence plus fort !',
      );
      
      LoggerService.info('Streak broken notification shown', tag: 'ALARM_NOTIF');
      
    } catch (e) {
      LoggerService.error('Failed to show streak broken', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  // ========== HELPERS ==========
  
  static DateTime _calculateNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
  
  /// ✅ NOUVEAU: Méthode directe pour afficher notification (utilisée dans callbacks)
  @pragma('vm:entry-point')
  static Future<void> _showNotificationDirect({
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
      
      _debugLog('Notification #$id shown: $title');
      
    } catch (e) {
      _debugLog('ERROR showing notification #$id: $e');
      rethrow;
    }
  }
  
  @pragma('vm:entry-point')
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  /// ✅ NOUVEAU: Debug logs persistants dans un fichier
  @pragma('vm:entry-point')
  static void _debugLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    
    // Log en console
    print('🔔 [ALARM_DEBUG] $logMessage');
    
    // ✅ BONUS: Écrire dans un fichier pour debug
    try {
      final file = File('/data/data/com.example.discipline/alarm_debug.log');
      file.writeAsStringSync('$logMessage\n', mode: FileMode.append);
    } catch (e) {
      // Ignore si pas de permissions fichier
    }
  }
  
  // ========== ANNULATION ==========
  
  static Future<void> cancelAll() async {
    try {
      await AndroidAlarmManager.cancel(MAIN_REMINDER_ID);
      await AndroidAlarmManager.cancel(LATE_REMINDER_ID);
      await AndroidAlarmManager.cancel(HARD_MODE_ID);
      
      LoggerService.info('All alarms cancelled', tag: 'ALARM_NOTIF');
      _debugLog('All alarms cancelled');
    } catch (e) {
      LoggerService.error('Cancel failed', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }
  
  static Future<bool> areAlarmsActive() async {
    if (!_isInitialized) return false;
    return await areNotificationsEnabled();
  }
  
  // ========== TESTS ==========
  
  static Future<bool> testNotification() async {
    if (!_isInitialized) return false;
    
    try {
      await _showNotificationDirect(
        id: TEST_ID,
        title: 'Test Discipline 🔥',
        body: 'Si tu vois ce message, les notifications fonctionnent !',
      );
      
      LoggerService.info('Test notification sent', tag: 'ALARM_NOTIF');
      _debugLog('Test notification sent');
      return true;
      
    } catch (e) {
      LoggerService.error('Test failed', tag: 'ALARM_NOTIF', error: e);
      _debugLog('Test FAILED: $e');
      return false;
    }
  }
  
  /// ✅ Test programmé dans 1 minute
  static Future<void> testIn1Minute() async {
    if (!_isInitialized) await initialize();
    
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    
    _debugLog('Scheduling test alarm for ${testTime.toString()}');
    
    final success = await AndroidAlarmManager.oneShotAt(
      testTime,
      TEST_ID,
      _callbackTest,
      exact: true,
      wakeup: true,
    );
    
    if (success) {
      _debugLog('✅ Test alarm scheduled successfully');
      LoggerService.info('Test alarm scheduled', tag: 'ALARM_NOTIF', data: {
        'time': testTime.toString(),
      });
    } else {
      _debugLog('❌ Test alarm scheduling FAILED');
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _callbackTest() async {
    _debugLog('🧪 TEST CALLBACK TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: TEST_ID,
        title: 'Test Réussi ! ⏰',
        body: 'L\'alarme fonctionne même quand l\'app est fermée !',
      );
      
      _debugLog('✅ Test notification shown successfully');
    } catch (e) {
      _debugLog('❌ Test callback ERROR: $e');
    }
  }
}