// ============================================
// FICHIER 10/30 : lib/core/services/notification_service.dart
// ============================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

import '../constants/notification_messages.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  static Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  static Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required bool isHardMode,
  }) async {
    await cancelAll();
    
    // Main reminder (18:00)
    await _scheduleDailyNotification(
      id: 0,
      hour: hour,
      minute: minute,
      title: 'Discipline',
      body: _getRandomMessage(NotificationMessages.doux),
    );
    
    // Late reminder (21:00)
    await _scheduleDailyNotification(
      id: 1,
      hour: hour + 3,
      minute: minute,
      title: 'Discipline ⚠️',
      body: _getRandomMessage(NotificationMessages.piment),
    );
    
    // Violence reminder (23:00 - Hard Mode only)
    if (isHardMode) {
      await _scheduleDailyNotification(
        id: 2,
        hour: 23,
        minute: 0,
        title: 'DISCIPLINE',
        body: _getRandomMessage(NotificationMessages.violence),
      );
    }
  }
  
  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappels Quotidiens',
          channelDescription: 'Notifications de rappel pour les habitudes',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  static Future<void> showStreakBroken(String habitTitle, int lostStreak) async {
    await _notifications.show(
      99,
      'Streak Perdu 💔',
      '$habitTitle: $lostStreak jours perdus. Recommence plus fort !',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_updates',
          'Mises à jour Streak',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
  
  static Future<void> showStreakMilestone(String habitTitle, int streak) async {
    String message;
    if (streak == 7) {
      message = '🔥 7 jours de $habitTitle ! Tu deviens redoutable';
    } else if (streak == 14) {
      message = '💪 14 jours ! Les résultats arrivent';
    } else if (streak == 21) {
      message = '👑 21 jours ! Une habitude est née';
    } else if (streak == 30) {
      message = '🚀 30 jours ! Tu es une machine';
    } else {
      return;
    }
    
    await _notifications.show(
      100,
      'Milestone Atteint !',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'milestones',
          'Réalisations',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
  
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}