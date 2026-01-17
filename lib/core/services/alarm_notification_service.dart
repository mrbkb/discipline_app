// ============================================
// NOUVELLE SOLUTION : lib/core/services/alarm_notification_service.dart
// ✅ Utilise android_alarm_manager_plus pour des notifications fiables
// ============================================
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'dart:math';
import 'logger_service.dart';
import '../constants/notification_messages.dart';

class AlarmNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // IDs des alarmes
  static const int MAIN_REMINDER_ID = 0;
  static const int LATE_REMINDER_ID = 1;
  static const int HARD_MODE_ID = 2;
  
  /// ✅ Initialiser le service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
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
      LoggerService.info('AlarmNotificationService initialized', tag: 'ALARM_NOTIF');
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Init error', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Programmer les alarmes quotidiennes
  static Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required bool isHardMode,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Annuler les alarmes existantes
      await cancelAll();
      
      LoggerService.info('Scheduling alarms', tag: 'ALARM_NOTIF', data: {
        'hour': hour,
        'minute': minute,
        'hardMode': isHardMode,
      });
      
      // 1. Alarme principale (18h par défaut)
      final mainTime = _calculateNextOccurrence(hour, minute);
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        MAIN_REMINDER_ID,
        _showMainReminder,
        startAt: mainTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
      LoggerService.info('Main reminder scheduled', tag: 'ALARM_NOTIF', data: {
        'time': mainTime.toString(),
      });
      
      // 2. Alarme tardive (+3h)
      final lateHour = (hour + 3) % 24;
      final lateTime = _calculateNextOccurrence(lateHour, minute);
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        LATE_REMINDER_ID,
        _showLateReminder,
        startAt: lateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      
      LoggerService.info('Late reminder scheduled', tag: 'ALARM_NOTIF', data: {
        'time': lateTime.toString(),
      });
      
      // 3. Mode violence (23h si activé)
      if (isHardMode) {
        final hardTime = _calculateNextOccurrence(23, 0);
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          HARD_MODE_ID,
          _showHardModeReminder,
          startAt: hardTime,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        
        LoggerService.info('Hard mode reminder scheduled', tag: 'ALARM_NOTIF', data: {
          'time': hardTime.toString(),
        });
      }
      
      LoggerService.info('All alarms scheduled successfully', tag: 'ALARM_NOTIF');
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Schedule failed', tag: 'ALARM_NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Calculer la prochaine occurrence
  static DateTime _calculateNextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }
  
  /// ✅ Callback pour le rappel principal
  /// ⚠️ IMPORTANT: Cette fonction doit être STATIQUE et TOP-LEVEL
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
  
  /// ✅ Afficher une notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      // Créer le canal de notification
      const androidChannel = AndroidNotificationDetails(
        'daily_reminder',
        'Rappels Quotidiens',
        channelDescription: 'Notifications de rappel pour les habitudes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
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
  
  /// ✅ Tester avec une alarme dans 1 minute
  static Future<void> testIn1Minute() async {
    if (!_isInitialized) await initialize();
    
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    
    await AndroidAlarmManager.oneShotAt(
      testTime,
      999,
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
      id: 999,
      title: 'Test Réussi ! ⏰',
      body: 'L\'alarme fonctionne même quand l\'app est fermée !',
    );
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}