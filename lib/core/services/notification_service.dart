// ============================================
// FICHIER CORRIGÉ COMPLET : lib/core/services/notification_service.dart
// ✅ Notifications fonctionnelles en arrière-plan avec alarmes exactes
// ============================================
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'dart:io' show Platform;
import 'logger_service.dart';
import '../constants/notification_messages.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  /// ✅ Initialize notifications avec support Android 13+
  static Future<bool> init() async {
    if (_isInitialized) return true;
    
    try {
      // 1. Initialize timezones
      tz.initializeTimeZones();
      
      // 2. Set local timezone
      const String timeZoneName = 'Africa/Douala'; // Cameroun
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      
      LoggerService.info('Timezone configured', tag: 'NOTIF', data: {
        'timezone': timeZoneName,
        'current_time': tz.TZDateTime.now(tz.local).toString(),
      });
      
      // 3. Initialize plugin avec les bons paramètres Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
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
        LoggerService.info('NotificationService initialized', tag: 'NOTIF');
      } else {
        LoggerService.error('NotificationService init failed', tag: 'NOTIF');
      }
      
      return _isInitialized;
      
    } catch (e, stack) {
      LoggerService.error('Notification init error', tag: 'NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    LoggerService.info('Notification tapped', tag: 'NOTIF', data: {
      'id': response.id,
      'payload': response.payload,
    });
  }
  
  /// ✅ CRITIQUE: Demander TOUTES les permissions nécessaires
  static Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      final initSuccess = await init();
      if (!initSuccess) return false;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin == null) {
          LoggerService.error('Android plugin not found', tag: 'NOTIF');
          return false;
        }
        
        // 1. Permission de notifications (Android 13+)
        LoggerService.debug('Requesting notification permission', tag: 'NOTIF');
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        
        if (notifGranted != true) {
          LoggerService.warning('Notification permission denied', tag: 'NOTIF');
          return false;
        }
        
        // 2. Permission d'alarmes exactes (CRITIQUE pour Android 12+)
        LoggerService.debug('Checking exact alarm permission', tag: 'NOTIF');
        final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
        
        if (canScheduleExact != true) {
          LoggerService.warning('Requesting exact alarm permission', tag: 'NOTIF');
          final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
          
          if (alarmGranted != true) {
            LoggerService.error('Exact alarm permission denied', tag: 'NOTIF');
            return false;
          }
        }
        
        LoggerService.info('All permissions granted', tag: 'NOTIF');
        return true;
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
          
          LoggerService.info('iOS permissions', tag: 'NOTIF', data: {
            'granted': granted,
          });
          return granted == true;
        }
      }
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Permission request failed', tag: 'NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Vérifier si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin == null) return false;
        
        final enabled = await androidPlugin.areNotificationsEnabled();
        final canSchedule = await androidPlugin.canScheduleExactNotifications();
        
        LoggerService.debug('Notification status', tag: 'NOTIF', data: {
          'enabled': enabled,
          'can_schedule_exact': canSchedule,
        });
        
        return (enabled ?? false) && (canSchedule ?? false);
      }
      
      return true;
      
    } catch (e) {
      LoggerService.error('Failed to check status', tag: 'NOTIF', error: e);
      return false;
    }
  }
  
  /// ✅ MÉTHODE PRINCIPALE: Programmer les notifications quotidiennes
  static Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required bool isHardMode,
  }) async {
    if (!_isInitialized) {
      LoggerService.warning('Cannot schedule: not initialized', tag: 'NOTIF');
      return false;
    }
    
    try {
      // 1. Vérifier les permissions
      final hasPermissions = await areNotificationsEnabled();
      if (!hasPermissions) {
        LoggerService.warning('Cannot schedule: no permissions', tag: 'NOTIF');
        return false;
      }
      
      // 2. Annuler toutes les notifications existantes
      await cancelAll();
      
      LoggerService.info('Scheduling notifications', tag: 'NOTIF', data: {
        'main_hour': hour,
        'main_minute': minute,
        'hard_mode': isHardMode,
      });
      
      // 3. Programmer rappel principal
      final mainScheduled = await _scheduleDailyNotification(
        id: 0,
        hour: hour,
        minute: minute,
        title: 'Discipline 🔥',
        body: _getRandomMessage(NotificationMessages.doux),
      );
      
      if (!mainScheduled) {
        LoggerService.error('Failed to schedule main reminder', tag: 'NOTIF');
        return false;
      }
      
      // 4. Programmer rappel tardif (+3h)
      final lateHour = (hour + 3) % 24;
      await _scheduleDailyNotification(
        id: 1,
        hour: lateHour,
        minute: minute,
        title: 'Discipline ⚠️',
        body: _getRandomMessage(NotificationMessages.piment),
      );
      
      // 5. Programmer mode violence si activé (23h)
      if (isHardMode) {
        await _scheduleDailyNotification(
          id: 2,
          hour: 23,
          minute: 0,
          title: 'DISCIPLINE 💀',
          body: _getRandomMessage(NotificationMessages.violence),
        );
      }
      
      // 6. Vérifier que les notifications sont bien programmées
      final pending = await getPendingNotifications();
      final expectedCount = isHardMode ? 3 : 2;
      
      LoggerService.info('Notifications scheduled', tag: 'NOTIF', data: {
        'scheduled': pending.length,
        'expected': expectedCount,
      });
      
      return pending.length >= expectedCount;
      
    } catch (e, stack) {
      LoggerService.error('Schedule failed', tag: 'NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Programmer UNE notification quotidienne avec alarme exacte
  static Future<bool> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      final scheduledDate = _nextInstanceOfTime(hour, minute);
      
      LoggerService.debug('Scheduling notification', tag: 'NOTIF', data: {
        'id': id,
        'title': title,
        'time': '$hour:${minute.toString().padLeft(2, '0')}',
        'next_trigger': scheduledDate.toString(),
        'minutes_until': scheduledDate.difference(tz.TZDateTime.now(tz.local)).inMinutes,
      });
      
      // ✅ Configuration Android CRITIQUE
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Rappels Quotidiens',
        channelDescription: 'Notifications de rappel pour les habitudes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        // ✅ TRÈS IMPORTANT: Options pour alarmes exactes
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        autoCancel: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // ✅ CRITIQUE: Utiliser exactAllowWhileIdle pour garantir le déclenchement
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Répéter chaque jour
      );
      
      LoggerService.info('Notification scheduled', tag: 'NOTIF', data: {
        'id': id,
      });
      
      return true;
      
    } catch (e, stack) {
      LoggerService.error('Failed to schedule notification', tag: 'NOTIF', error: e, stackTrace: stack);
      return false;
    }
  }
  
  /// ✅ Calculer la prochaine occurrence
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
      0,
    );
    
    // Si l'heure est déjà passée, programmer pour demain
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  /// ✅ Notification immédiate (pour milestones, etc.)
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
      
      LoggerService.info('Streak broken notification shown', tag: 'NOTIF');
      
    } catch (e) {
      LoggerService.error('Failed to show streak broken', tag: 'NOTIF', error: e);
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
      
      LoggerService.info('Milestone notification shown', tag: 'NOTIF', data: {
        'streak': streak,
      });
      
    } catch (e) {
      LoggerService.error('Failed to show milestone', tag: 'NOTIF', error: e);
    }
  }
  
  /// ✅ Annuler toutes les notifications
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      LoggerService.info('All notifications cancelled', tag: 'NOTIF');
    } catch (e) {
      LoggerService.error('Failed to cancel', tag: 'NOTIF', error: e);
    }
  }
  
  /// ✅ Lister les notifications programmées
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      final pending = await _notifications.pendingNotificationRequests();
      
      LoggerService.debug('Pending notifications', tag: 'NOTIF', data: {
        'count': pending.length,
      });
      
      for (final notif in pending) {
        LoggerService.debug('- #${notif.id}: ${notif.title}', tag: 'NOTIF');
      }
      
      return pending;
      
    } catch (e) {
      LoggerService.error('Failed to get pending', tag: 'NOTIF', error: e);
      return [];
    }
  }
  
  /// ✅ Test immédiat
  static Future<bool> testNotification() async {
    if (!_isInitialized) return false;
    
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
      
      LoggerService.info('Test notification sent', tag: 'NOTIF');
      return true;
      
    } catch (e) {
      LoggerService.error('Test failed', tag: 'NOTIF', error: e);
      return false;
    }
  }
  
  /// ✅ Test programmé dans 1 minute
  static Future<bool> testScheduledIn1Minute() async {
    if (!_isInitialized) return false;
    
    try {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(minutes: 1));
      
      LoggerService.info('Testing scheduled notification', tag: 'NOTIF', data: {
        'current_time': now.toString(),
        'test_time': testTime.toString(),
      });
      
      await _notifications.zonedSchedule(
        888,
        'Test Programmé ⏰',
        'Cette notification devait arriver dans 1 minute !',
        testTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test',
            'Test',
            channelDescription: 'Test notifications',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      LoggerService.info('Test scheduled successfully', tag: 'NOTIF');
      return true;
      
    } catch (e) {
      LoggerService.error('Test scheduled failed', tag: 'NOTIF', error: e);
      return false;
    }
  }
}