// ============================================
// FICHIER CORRIGÉ : lib/core/services/notification_service.dart
// FIX: Notifications programmées aux bonnes heures
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
  
  /// ✅ Initialize notifications
  static Future<bool> init() async {
    if (_isInitialized) return true;
    
    try {
      // 1. Initialize timezones
      tz.initializeTimeZones();
      
      // 2. ✅ FIX: Configurer le timezone LOCAL (très important!)
      final String timeZoneName = await _getLocalTimeZone();
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      
      print('⏰ Timezone configured: $timeZoneName');
      print('⏰ Current local time: ${tz.TZDateTime.now(tz.local)}');
      
      // 3. Initialize plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // On demande manuellement
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
        print('✅ NotificationService initialized');
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
  
  /// ✅ FIX: Détecter le timezone local automatiquement
  static Future<String> _getLocalTimeZone() async {
    try {
      // Pour l'Afrique (Cameroun/Douala)
      return 'Africa/Douala';
    } catch (e) {
      // Fallback: utiliser UTC
      print('⚠️ Could not detect timezone, using UTC');
      return 'UTC';
    }
  }
  
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.id}');
  }
  
  /// ✅ Request permissions
  static Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      final initSuccess = await init();
      if (!initSuccess) return false;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // 1. Request notification permission
          final notifGranted = await androidPlugin.requestNotificationsPermission();
          print('📱 Notification permission: $notifGranted');
          
          // 2. ✅ FIX: Vérifier ET demander la permission d'alarmes exactes
          final canScheduleExact = await androidPlugin.canScheduleExactNotifications();
          print('⏰ Can schedule exact alarms: $canScheduleExact');
          
          if (canScheduleExact == false) {
            print('⚠️ Requesting exact alarm permission...');
            final alarmGranted = await androidPlugin.requestExactAlarmsPermission();
            print('⏰ Exact alarm permission: $alarmGranted');
            
            if (alarmGranted != true) {
              print('❌ User denied exact alarm permission');
              return false;
            }
          }
          
          return notifGranted == true;
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
  
  /// ✅ Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final enabled = await androidPlugin.areNotificationsEnabled();
          final canSchedule = await androidPlugin.canScheduleExactNotifications();
          
          print('📱 Notifications enabled: $enabled');
          print('⏰ Can schedule exact: $canSchedule');
          
          return (enabled ?? false) && (canSchedule ?? false);
        }
      }
      
      return true;
      
    } catch (e) {
      print('❌ Failed to check status: $e');
      return false;
    }
  }
  
  /// ✅ FIX: Schedule daily notifications ROBUSTE
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
      // 1. Vérifier les permissions
      final hasPermissions = await areNotificationsEnabled();
      if (!hasPermissions) {
        print('⚠️ Cannot schedule: no permissions');
        return false;
      }
      
      // 2. Annuler les notifications existantes
      await cancelAll();
      
      print('');
      print('📅 ========================================');
      print('📅 SCHEDULING NOTIFICATIONS');
      print('📅 ========================================');
      print('📅 Main reminder: $hour:${minute.toString().padLeft(2, '0')}');
      print('📅 Hard mode: $isHardMode');
      print('📅 Current time: ${DateTime.now()}');
      print('📅 ========================================');
      print('');
      
      // 3. Programmer les notifications
      
      // ✅ Rappel principal (18h par défaut)
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
      
      // ✅ Rappel tardif (+3h)
      final lateHour = (hour + 3) % 24;
      final lateScheduled = await _scheduleDailyNotification(
        id: 1,
        hour: lateHour,
        minute: minute,
        title: 'Discipline ⚠️',
        body: _getRandomMessage(NotificationMessages.piment),
      );
      
      if (!lateScheduled) {
        print('⚠️ Late reminder failed (non-critical)');
      }
      
      // ✅ Mode violence (23h, Hard Mode uniquement)
      if (isHardMode) {
        final hardScheduled = await _scheduleDailyNotification(
          id: 2,
          hour: 23,
          minute: 0,
          title: 'DISCIPLINE 💀',
          body: _getRandomMessage(NotificationMessages.violence),
        );
        
        if (!hardScheduled) {
          print('⚠️ Hard mode reminder failed (non-critical)');
        }
      }
      
      // 4. Vérifier les notifications programmées
      final pending = await getPendingNotifications();
      final expectedCount = isHardMode ? 3 : 2;
      
      print('');
      print('✅ Notifications scheduled: ${pending.length}/$expectedCount');
      print('');
      
      return pending.isNotEmpty;
      
    } catch (e, stack) {
      print('❌ Failed to schedule notifications: $e');
      print(stack);
      return false;
    }
  }
  
  /// ✅ FIX: Programmer UNE notification quotidienne
  static Future<bool> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      // ✅ Calculer la prochaine occurrence
      final scheduledDate = _nextInstanceOfTime(hour, minute);
      
      // ✅ Debug: Afficher l'heure programmée
      print('');
      print('⏰ Notification #$id:');
      print('   Title: $title');
      print('   Time: $hour:${minute.toString().padLeft(2, '0')}');
      print('   Next trigger: $scheduledDate');
      print('   In: ${scheduledDate.difference(tz.TZDateTime.now(tz.local)).inMinutes} minutes');
      
      // ✅ Configuration Android
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        'Rappels Quotidiens',
        channelDescription: 'Notifications de rappel pour les habitudes',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        // ✅ CRITIQUE: Options pour alarmes exactes
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
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
      
      // ✅ FIX: Utiliser exactAllowWhileIdle pour garantir le déclenchement
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // ✅ Répéter chaque jour
      );
      
      print('   ✅ Scheduled successfully');
      
      return true;
      
    } catch (e, stack) {
      print('   ❌ Failed to schedule #$id: $e');
      print(stack);
      return false;
    }
  }
  
  /// ✅ FIX: Calculer la prochaine occurrence CORRECTEMENT
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    
    // ✅ Créer la date pour aujourd'hui à l'heure spécifiée
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0, // secondes = 0
      0, // millisecondes = 0
    );
    
    // ✅ Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('   ℹ️ Time already passed today, scheduling for tomorrow');
    }
    
    return scheduledDate;
  }
  
  static String _getRandomMessage(List<String> messages) {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
  
  /// ✅ Show immediate notification
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
      print('❌ Failed to show streak broken: $e');
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
      print('❌ Failed to show milestone: $e');
    }
  }
  
  /// ✅ Cancel all notifications
  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      print('🗑️ All notifications cancelled');
    } catch (e) {
      print('❌ Failed to cancel: $e');
    }
  }
  
  /// ✅ Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    
    try {
      final pending = await _notifications.pendingNotificationRequests();
      
      print('');
      print('📬 Pending notifications: ${pending.length}');
      for (final notif in pending) {
        print('   - #${notif.id}: ${notif.title}');
      }
      print('');
      
      return pending;
      
    } catch (e) {
      print('❌ Failed to get pending: $e');
      return [];
    }
  }
  
  /// ✅ Test notification immédiate
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
  
  /// ✅ NOUVEAU: Tester une notification programmée dans 1 minute
  static Future<bool> testScheduledIn1Minute() async {
    if (!_isInitialized) return false;
    
    try {
      final now = tz.TZDateTime.now(tz.local);
      final testTime = now.add(const Duration(minutes: 1));
      
      print('');
      print('🧪 Testing scheduled notification in 1 minute');
      print('   Current time: $now');
      print('   Test time: $testTime');
      
      const androidDetails = AndroidNotificationDetails(
        'test',
        'Test',
        channelDescription: 'Test notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
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
        888,
        'Test Programmé ⏰',
        'Cette notification devait arriver dans 1 minute !',
        testTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Test scheduled notification set');
      return true;
      
    } catch (e) {
      print('❌ Test scheduled failed: $e');
      return false;
    }
  }
}