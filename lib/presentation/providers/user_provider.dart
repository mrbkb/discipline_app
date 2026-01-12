// ============================================
// FICHIER CORRIGÉ : lib/presentation/providers/user_provider.dart
// FIX: Notifications dans les réglages normaux
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/analytics_service.dart';

// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// StateNotifierProvider
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});

// Providers dérivés
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.onboardingCompleted ?? false;
});

final isHardModeProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.isHardMode ?? false;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.notificationsEnabled ?? true;
});

final userNicknameProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider);
  return user?.nickname ?? 'Champion';
});

final lastSyncProvider = Provider<DateTime?>((ref) {
  final user = ref.watch(userProvider);
  return user?.lastSyncAt;
});

final hasBackedUpProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.hasBackedUp ?? false;
});

final isLocalModeProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user?.firebaseUid == null;
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier(this._repository) : super(null) {
    _loadUser();
  }
  
  final UserRepository _repository;
  
  // ========== LOAD ==========
  
  Future<void> _loadUser() async {
    state = _repository.getUser();
    
    if (state != null && state!.firebaseUid == null) {
      await _tryConnectToFirebase();
    }
  }
  
  void _notifyStateChange() {
    if (state != null) {
      print('🔔 [UserNotifier] Forcing state notification');
      state = state!.copyWith();
    }
  }
  
  Future<void> refresh() async {
    await _loadUser();
  }
  
  // ========== FIREBASE AUTH ==========
  
  Future<void> _tryConnectToFirebase() async {
    try {
      final firebaseUser = await FirebaseService.tryConnectIfOffline();
      
      if (firebaseUser != null) {
        await _repository.migrateToFirebase(firebaseUser.uid);
        await _loadUser();
        _notifyStateChange();
        
        print('✅ [UserNotifier] User migrated to Firebase');
        
        await _autoSyncAfterConnection();
      }
    } catch (e) {
      print('⚠️ [UserNotifier] Firebase connection failed (will retry later): $e');
    }
  }
  
  Future<void> _autoSyncAfterConnection() async {
    try {
      print('🔄 [UserNotifier] Auto-sync triggered');
    } catch (e) {
      print('❌ [UserNotifier] Auto-sync failed: $e');
    }
  }
  
  Future<bool> forceConnectToFirebase() async {
    try {
      final firebaseUser = await FirebaseService.tryConnectIfOffline();
      
      if (firebaseUser != null) {
        await _repository.migrateToFirebase(firebaseUser.uid);
        await _loadUser();
        _notifyStateChange();
        
        await _autoSyncAfterConnection();
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ [UserNotifier] Force connect failed: $e');
      return false;
    }
  }
  
  Future<void> upgradeToEmail(String email, String password) async {
    try {
      final firebaseUser = await FirebaseService.upgradeToEmailPassword(
        email: email,
        password: password,
      );
      
      if (firebaseUser != null) {
        await _repository.upgradeToEmail(email);
        await _loadUser();
        _notifyStateChange();
        
        await AnalyticsService.logEvent(
          name: 'account_upgraded',
          parameters: {'method': 'email'},
        );
      }
    } catch (e) {
      print('Error upgrading to email: $e');
      rethrow;
    }
  }
  
  // ========== CREATE ==========
  
  Future<void> createUser({
    required String nickname,
  }) async {
    final firebaseUser = await FirebaseService.initializeAuth();
    
    final user = await _repository.createUser(
      nickname: nickname,
      firebaseUid: firebaseUser?.uid,
      isAnonymous: firebaseUser?.isAnonymous ?? true,
    );
    
    state = user;
    
    if (firebaseUser == null) {
      print('📱 [UserNotifier] User created in LOCAL mode (offline)');
    } else {
      print('☁️ [UserNotifier] User created with Firebase');
    }
  }
  
  // ========== UPDATE ==========
  
  Future<void> updateNickname(String nickname) async {
    print('🔵 [UserNotifier] updateNickname: $nickname');
    
    await _repository.updateNickname(nickname);
    state = _repository.getUser();
    _notifyStateChange();
  }
  
  /// ✅ FIX CRITIQUE: toggleHardMode avec reprogrammation des notifications
  Future<void> toggleHardMode() async {
    try {
      print('');
      print('🔵 ========================================');
      print('🔵 [UserNotifier] toggleHardMode');
      print('🔵 ========================================');
      
      await _repository.toggleHardMode();
      state = _repository.getUser();
      _notifyStateChange();
      
      final user = state;
      if (user != null) {
        print('   Hard mode: ${user.isHardMode}');
        print('   Notifications enabled: ${user.notificationsEnabled}');
        
        // ✅ FIX: Reprogrammer les notifications si activées
        if (user.notificationsEnabled) {
          print('   → Rescheduling notifications...');
          
          try {
            // ✅ Vérifier d'abord les permissions
            final hasPermissions = await NotificationService.areNotificationsEnabled();
            
            if (!hasPermissions) {
              print('   ⚠️ No permissions, requesting...');
              final granted = await NotificationService.requestPermissions();
              
              if (!granted) {
                print('   ❌ Permissions denied, cannot schedule');
                return;
              }
            }
            
            // ✅ Programmer les notifications avec le nouveau mode
            final scheduled = await NotificationService.scheduleDaily(
              hour: user.reminderHour,
              minute: user.reminderMinute,
              isHardMode: user.isHardMode,
            );
            
            if (scheduled) {
              print('   ✅ Notifications rescheduled successfully');
            } else {
              print('   ❌ Failed to reschedule notifications');
            }
            
          } catch (e) {
            print('   ❌ Error rescheduling notifications: $e');
          }
        } else {
          print('   ℹ️ Notifications disabled, skipping reschedule');
        }
      }
      
      // Analytics
      try {
        await AnalyticsService.logHardModeToggled(state!.isHardMode);
      } catch (e) {
        print('   ❌ Error logging hard mode toggle: $e');
      }
      
      print('🔵 ========================================');
      print('');
      
    } catch (e) {
      print('❌ Error in toggleHardMode: $e');
      rethrow;
    }
  }
  
  /// ✅ FIX CRITIQUE: updateReminderTimes avec reprogrammation
  Future<void> updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) async {
    print('');
    print('🔵 ========================================');
    print('🔵 [UserNotifier] updateReminderTimes');
    print('🔵 ========================================');
    
    await _repository.updateReminderTimes(
      reminder: reminder,
      lateReminder: lateReminder,
    );
    
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null) {
      print('   New reminder: ${user.reminderTime}');
      print('   Late reminder: ${user.lateReminderTime}');
      print('   Notifications enabled: ${user.notificationsEnabled}');
      
      // ✅ FIX: Reprogrammer les notifications si activées
      if (user.notificationsEnabled) {
        print('   → Rescheduling notifications...');
        
        try {
          // ✅ Vérifier les permissions
          final hasPermissions = await NotificationService.areNotificationsEnabled();
          
          if (!hasPermissions) {
            print('   ⚠️ No permissions, requesting...');
            final granted = await NotificationService.requestPermissions();
            
            if (!granted) {
              print('   ❌ Permissions denied, cannot schedule');
              return;
            }
          }
          
          // ✅ Programmer avec les nouvelles heures
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            print('   ✅ Notifications rescheduled successfully');
          } else {
            print('   ❌ Failed to reschedule notifications');
          }
          
        } catch (e) {
          print('   ❌ Error rescheduling notifications: $e');
        }
      } else {
        print('   ℹ️ Notifications disabled, skipping reschedule');
      }
    }
    
    print('🔵 ========================================');
    print('');
  }
  
  /// ✅ FIX CRITIQUE: toggleNotifications avec gestion complète
  Future<void> toggleNotifications() async {
    print('');
    print('🔵 ========================================');
    print('🔵 [UserNotifier] toggleNotifications');
    print('🔵 ========================================');
    
    await _repository.toggleNotifications();
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null) {
      print('   Notifications enabled: ${user.notificationsEnabled}');
      
      try {
        if (user.notificationsEnabled) {
          print('   → Enabling notifications...');
          
          // ✅ Demander les permissions d'abord
          final hasPermissions = await NotificationService.areNotificationsEnabled();
          
          if (!hasPermissions) {
            print('   ⚠️ No permissions, requesting...');
            final granted = await NotificationService.requestPermissions();
            
            if (!granted) {
              print('   ❌ Permissions denied');
              
              // ✅ FIX: Re-désactiver si permissions refusées
              await _repository.toggleNotifications();
              state = _repository.getUser();
              _notifyStateChange();
              
              return;
            }
          }
          
          // ✅ Programmer les notifications
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            print('   ✅ Notifications scheduled successfully');
          } else {
            print('   ❌ Failed to schedule notifications');
          }
          
        } else {
          print('   → Disabling notifications...');
          await NotificationService.cancelAll();
          print('   ✅ Notifications cancelled');
        }
        
      } catch (e) {
        print('   ❌ Error toggling notifications: $e');
      }
    }
    
    print('🔵 ========================================');
    print('');
  }
  
  /// ✅ FIX: completeOnboarding avec programmation initiale
  Future<void> completeOnboarding() async {
    print('');
    print('🔵 ========================================');
    print('🔵 [UserNotifier] completeOnboarding');
    print('🔵 ========================================');
    
    await _repository.completeOnboarding();
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null && user.notificationsEnabled) {
      print('   → Scheduling initial notifications...');
      
      try {
        // ✅ Vérifier les permissions
        final hasPermissions = await NotificationService.areNotificationsEnabled();
        
        if (hasPermissions) {
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            print('   ✅ Initial notifications scheduled');
          } else {
            print('   ❌ Failed to schedule initial notifications');
          }
        } else {
          print('   ⚠️ No permissions, skipping initial schedule');
        }
        
      } catch (e) {
        print('   ❌ Error scheduling initial notifications: $e');
      }
    }
    
    print('🔵 ========================================');
    print('');
  }
  
  Future<void> markBackedUp() async {
    print('🔵 [UserNotifier] markBackedUp');
    
    await _repository.markBackedUp();
    state = _repository.getUser();
    _notifyStateChange();
  }
}