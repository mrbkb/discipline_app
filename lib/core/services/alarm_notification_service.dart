// ============================================
// FICHIER FIXÉ : lib/core/services/alarm_notification_service.dart
// ✅ Remplacé print() par debugPrint() et logs fichier retirés
// ============================================
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'logger_service.dart';
import '../constants/notification_messages.dart';
import '../../data/models/user_model.dart';

@pragma('vm:entry-point')
class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  static const int mainReminderId = 0;
  static const int lateReminderId = 1;
  static const int hardModeId = 2;
  
  static const int milestoneId = 100;
  static const int streakBrokenId = 99;
  static const int testId = 999;
  
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      LoggerService.info('Initializing AlarmNotificationService', tag: 'ALARM_NOTIF');
      
      final alarmInitialized = await AndroidAlarmManager.initialize();
      
      if (!alarmInitialized) {
        LoggerService.error('AndroidAlarmManager init failed', tag: 'ALARM_NOTIF');
        return false;
      }
      
      await _initializeNotificationPlugin();
      
      _isInitialized = true;
      LoggerService.info('AlarmNotificationService initialized successfully', tag: 'ALARM_NOTIF');
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Init error', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _initializeNotificationPlugin() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(settings);
    
    _debugLog('Notification plugin initialized');
  }
  
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
      
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      
      if (notifGranted != true) {
        LoggerService.warning('Notification permission denied', tag: 'ALARM_NOTIF');
        return false;
      }
      
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
      
      final mainTime = _calculateNextOccurrence(hour, minute);
      final mainSuccess = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        mainReminderId,
        _callbackMainReminder,
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
      
      final lateTime = _calculateNextOccurrence(lateHour, lateMinute);
      final lateSuccess = await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        lateReminderId,
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
      
      if (isHardMode) {
        final hardTime = _calculateNextOccurrence(23, 0);
        final hardSuccess = await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          hardModeId,
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
  
  @pragma('vm:entry-point')
  static Future<void> _callbackMainReminder() async {
    _debugLog('🔔 CALLBACK MAIN REMINDER TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: mainReminderId,
        title: 'Discipline 🔥',
        body: _getRandomMessage(NotificationMessages.doux),
      );
      
      _debugLog('✅ Main reminder notification shown');
    } catch (e) {
      _debugLog('❌ Main reminder ERROR: $e');
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _callbackLateReminder() async {
    _debugLog('🔔 CALLBACK LATE REMINDER TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: lateReminderId,
        title: 'Discipline ⚠️',
        body: _getRandomMessage(NotificationMessages.piment),
      );
      
      _debugLog('✅ Late reminder notification shown');
    } catch (e) {
      _debugLog('❌ Late reminder ERROR: $e');
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _callbackHardModeReminder() async {
    _debugLog('🔔 CALLBACK HARD MODE TRIGGERED at ${DateTime.now()}');
    
    try {
      await _initializeNotificationPlugin();
      
      await _showNotificationDirect(
        id: hardModeId,
        title: 'DISCIPLINE 💀',
        body: _getRandomMessage(NotificationMessages.violence),
      );
      
      _debugLog('✅ Hard mode notification shown');
    } catch (e) {
      _debugLog('❌ Hard mode ERROR: $e');
    }
  }
  
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
        id: milestoneId,
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
        id: streakBrokenId,
        title: 'Streak Perdu 💔',
        body: '$habitTitle: $lostStreak jours perdus. Recommence plus fort !',
      );
      
      LoggerService.info('Streak broken notification shown', tag: 'ALARM_NOTIF');
      
    } catch (e) {
      LoggerService.error('Failed to show streak broken', tag: 'ALARM_NOTIF', error: e);
    }
  }
  
  static DateTime _calculateNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
  
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
  
  // ✅ FIX: Utiliser debugPrint au lieu de print + retirer écriture fichier
  @pragma('vm:entry-point')
  static void _debugLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    
    // ✅ debugPrint au lieu de print (autorisé en production)
    debugPrint('🔔 [ALARM_DEBUG] $logMessage');
  }
  
  static Future<void> cancelAll() async {
    try {
      await AndroidAlarmManager.cancel(mainReminderId);
      await AndroidAlarmManager.cancel(lateReminderId);
      await AndroidAlarmManager.cancel(hardModeId);
      
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
  
  static Future<bool> testNotification() async {
    if (!_isInitialized) return false;
    
    try {
      await _showNotificationDirect(
        id: testId,
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
  
  static Future<void> testIn1Minute() async {
    if (!_isInitialized) await initialize();
    
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    
    _debugLog('Scheduling test alarm for ${testTime.toString()}');
    
    final success = await AndroidAlarmManager.oneShotAt(
      testTime,
      testId,
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
        id: testId,
        title: 'Test Réussi ! ⏰',
        body: 'L\'alarme fonctionne même quand l\'app est fermée !',
      );
      
      _debugLog('✅ Test notification shown successfully');
    } catch (e) {
      _debugLog('❌ Test callback ERROR: $e');
    }
  }
}