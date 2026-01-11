// ============================================
// FICHIER PRODUCTION : lib/core/services/notification_service.dart
// ============================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'dart:io' show Platform;

import '../constants/notification_messages.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  /// ✅ Initialize notifications - TOUJOURS appeler au démarrage
  static Future<bool> init() async {
    if (_isInitialized) return true;
    
    try {
      // 1. Initialize timezones
      tz.initializeTimeZones();
      
      // 2. Set local timezone
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Douala'));
      } catch (e) {
        tz.setLocalLocation(tz.local);
      }
      
      // 3. Initialize plugin
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
      
      final result = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _isInitialized = result == true;
      
      if (_isInitialized) {
        print('✅ NotificationService initialized successfully');
      } else {
        print('❌ NotificationService initialization failed');
      }
      
      return _isInitialized;
      
    } catch (e, stack) {
      print('❌ NotificationService init error: $e');
      print(stack);
      return false;
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.id}');
  }
  
  /// ✅ Request permissions - À appeler EXPLICITEMENT
  static Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      print('⚠️ Cannot request permissions: not initialized');
      final initSuccess = await init();
      if (!initSuccess) return false;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // 1. Request notification permission (Android 13+)
          final notifGranted = await androidPlugin.requestNotificationsPermission();
          
          // 2. Request exact alarm permission
          final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
          
          print('📱 Permissions - Notifications: $notifGranted, Alarms: $alarmGranted');
          
          return notifGranted == true && alarmGranted == true;
        }
      }
      
      if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
          print('📱 iOS permissions granted: $granted');
          return granted == true;
        }
      }
      
      return true;
      
    } catch (e) {
      print('❌ Failed to request permissions: $e');
      return false;
    }
  }
  
  /// ✅ Check if permissions are granted
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          return enabled ?? false;
        }
      }
      
      // iOS assume toujours enabled si pas d'erreur
      return true;
      
    } catch (e) {
      print('❌ Failed to check notification status: $e');
      return false;
    }
  }
  
  /// ✅ Schedule daily notifications - VERSION ROBUSTE
  static Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required bool isHardMode,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Cannot schedule: not initialized');
      return false;
    }
    
    try {
      // 1. Vérifier les permissions AVANT de programmer
      final hasPermissions = await areNotificationsEnabled();
      if (!hasPermissions) {
        print('⚠️ Cannot schedule: no permissions');
        return false;
      }
      
      // 2. Annuler toutes les notifications existantes
      await cancelAll();
      
      print('📅 Scheduling notifications: $hour:$minute, Hard: $isHardMode');
      
      // 3. Programmer les notifications
      
      // Main reminder (18h par défaut)
      final mainScheduled = await _scheduleDailyNotification(
        id: 0,
        hour: hour,
        minute: minute,
        title: 'Discipline 🔥',
        body: _getRandomMessage(NotificationMessages.doux),
      );
      
      if (!mainScheduled) {
        print('❌ Failed to schedule main reminder');
        return false;
      }
      
      // Late reminder (+3h)
      final lateHour = (hour + 3) % 24;
      final lateScheduled = await _scheduleDailyNotification(
        id: 1,
        hour: lateHour,
        minute: minute,
        title: 'Discipline ⚠️',
        body: _getRandomMessage(NotificationMessages.piment),
      );
      
      if (!lateScheduled) {
        print('⚠️ Late reminder scheduling failed');
      }
      
      // Violence reminder (Hard Mode only, 23h)
      if (isHardMode) {
        final hardScheduled = await _scheduleDailyNotification(
          id: 2,
          hour: 23,
          minute: 0,
          title: 'DISCIPLINE 💀',
          body: _getRandomMessage(NotificationMessages.violence),
        );
        
        if (!hardScheduled) {
          print('⚠️ Hard mode reminder scheduling failed');
        }
      }
      
      // 4. Vérifier que tout s'est bien passé
      final pending = await getPendingNotifications();
      final expectedCount = isHardMode ? 3 : 2;
      
      if (pending.length != expectedCount) {
        print('⚠️ Expected $expectedCount notifications, got ${pending.length}');
        return false;
      }
      
      print('✅ All notifications scheduled successfully');
      return true;
      
    } catch (e, stack) {
      print('❌ Failed to schedule notifications: $e');
      print(stack);
      return false;
    }
  }
  
  static Future<bool> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfTime(hour, minute);
      
      print('⏰ Scheduling #$id for ${scheduledDate.toString()}');
      
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Rappels Quotidiens',
        channelDescription: 'Notifications de rappel pour les habitudes',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      return true;
      
    } catch (e) {
      print('❌ Failed to schedule notification #$id: $e');
      return false;
    }
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
    
    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  /// ✅ Show immediate notification (streak broken)
  static Future<void> showStreakBroken(String habitTitle, int lostStreak) async {
    if (!_isInitialized) return;
    
    try {
      await _notifications.show(
        99,
        'Streak Perdu 💔',
        '$habitTitle: $lostStreak jours perdus. Recommence plus fort !',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_updates',
            'Mises à jour Streak',
            channelDescription: 'Notifications de perte de streak',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      print('✅ Streak broken notification shown');
      
    } catch (e) {
      print('❌ Failed to show streak broken notification: $e');
    }
  }
  
  /// ✅ Show milestone notification
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
      await _notifications.show(
        100,
        'Milestone Atteint ! 🎉',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'milestones',
            'Réalisations',
            channelDescription: 'Notifications de célébration',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      print('✅ Milestone notification shown: $streak days');
      
    } catch (e) {
      print('❌ Failed to show milestone notification: $e');
    }
  }
  
  /// ✅ Cancel all notifications
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      print('🗑️ All notifications cancelled');
    } catch (e) {
      print('❌ Failed to cancel notifications: $e');
    }
  }
  
  /// ✅ Get pending notifications (for debug)
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      final pending = await _notifications.pendingNotificationRequests();
      
      print('📬 Pending notifications: ${pending.length}');
      for (final notif in pending) {
        print('  - #${notif.id}: ${notif.title}');
      }
      
      return pending;
      
    } catch (e) {
      print('❌ Failed to get pending notifications: $e');
      return [];
    }
  }
  
  /// ✅ NOUVEAU: Test notification immédiate
  static Future<bool> testNotification() async {
    if (!_isInitialized) {
      print('⚠️ Cannot test: not initialized');
      return false;
    }
    
    try {
      await _notifications.show(
        999,
        'Test Discipline 🔥',
        'Si tu vois ce message, les notifications fonctionnent !',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test',
            'Test',
            channelDescription: 'Notifications de test',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      print('✅ Test notification sent');
      return true;
      
    } catch (e) {
      print('❌ Test notification failed: $e');
      return false;
    }
  }
}