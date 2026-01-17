// ============================================
// FICHIER PRODUCTION : lib/presentation/providers/user_provider.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/notification_service.dart';

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
      LoggerService.debug('Forcing state notification', tag: 'USER');
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
        
        LoggerService.info('User migrated to Firebase', tag: 'USER', data: {
          'uid': firebaseUser.uid,
        });
        
        await _autoSyncAfterConnection();
      }
    } catch (e, stack) {
      LoggerService.warning('Firebase connection failed (will retry later)', tag: 'USER', error: e);
    }
  }
  
  Future<void> _autoSyncAfterConnection() async {
    try {
      LoggerService.debug('Auto-sync triggered after connection', tag: 'USER');
    } catch (e) {
      LoggerService.error('Auto-sync failed', tag: 'USER', error: e);
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
        
        LoggerService.info('Force connect successful', tag: 'USER');
        return true;
      }
      
      return false;
    } catch (e, stack) {
      LoggerService.error('Force connect failed', tag: 'USER', error: e, stackTrace: stack);
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
        
        LoggerService.info('Account upgraded to email', tag: 'USER');
      }
    } catch (e, stack) {
      LoggerService.error('Account upgrade failed', tag: 'USER', error: e, stackTrace: stack);
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
    
    final mode = firebaseUser == null ? 'local' : 'cloud';
    LoggerService.info('User created', tag: 'USER', data: {
      'mode': mode,
      'nickname': nickname,
    });
  }
  
  // ========== UPDATE ==========
  
  Future<void> updateNickname(String nickname) async {
    LoggerService.debug('Updating nickname', tag: 'USER', data: {'nickname': nickname});
    
    await _repository.updateNickname(nickname);
    state = _repository.getUser();
    _notifyStateChange();
  }
  
  Future<void> toggleHardMode() async {
    try {
      LoggerService.debug('Toggling hard mode', tag: 'USER');
      
      await _repository.toggleHardMode();
      state = _repository.getUser();
      _notifyStateChange();
      
      final user = state;
      if (user != null) {
        LoggerService.info('Hard mode toggled', tag: 'USER', data: {
          'hardMode': user.isHardMode,
          'notificationsEnabled': user.notificationsEnabled,
        });
        
        if (user.notificationsEnabled) {
          LoggerService.debug('Rescheduling notifications with new mode', tag: 'USER');
          
          try {
            final hasPermissions = await NotificationService.areNotificationsEnabled();
            
            if (!hasPermissions) {
              LoggerService.warning('No notification permissions, requesting', tag: 'USER');
              final granted = await NotificationService.requestPermissions();
              
              if (!granted) {
                LoggerService.warning('Permissions denied, cannot schedule', tag: 'USER');
                return;
              }
            }
            
            final scheduled = await NotificationService.scheduleDaily(
              hour: user.reminderHour,
              minute: user.reminderMinute,
              isHardMode: user.isHardMode,
            );
            
            if (scheduled) {
              LoggerService.info('Notifications rescheduled', tag: 'USER');
            } else {
              LoggerService.error('Failed to reschedule notifications', tag: 'USER');
            }
            
          } catch (e, stack) {
            LoggerService.error('Error rescheduling notifications', tag: 'USER', error: e, stackTrace: stack);
          }
        }
      }
      
      await AnalyticsService.logHardModeToggled(state!.isHardMode);
      
    } catch (e, stack) {
      LoggerService.error('Error in toggleHardMode', tag: 'USER', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) async {
    LoggerService.debug('Updating reminder times', tag: 'USER', data: {
      'reminder': reminder,
      'lateReminder': lateReminder,
    });
    
    await _repository.updateReminderTimes(
      reminder: reminder,
      lateReminder: lateReminder,
    );
    
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null) {
      if (user.notificationsEnabled) {
        LoggerService.debug('Rescheduling notifications with new times', tag: 'USER');
        
        try {
          final hasPermissions = await NotificationService.areNotificationsEnabled();
          
          if (!hasPermissions) {
            LoggerService.warning('No notification permissions', tag: 'USER');
            final granted = await NotificationService.requestPermissions();
            
            if (!granted) {
              LoggerService.warning('Permissions denied', tag: 'USER');
              return;
            }
          }
          
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            LoggerService.info('Notifications rescheduled with new times', tag: 'USER');
          } else {
            LoggerService.error('Failed to reschedule', tag: 'USER');
          }
          
        } catch (e, stack) {
          LoggerService.error('Error rescheduling', tag: 'USER', error: e, stackTrace: stack);
        }
      }
    }
  }
  
  Future<void> toggleNotifications() async {
    LoggerService.debug('Toggling notifications', tag: 'USER');
    
    await _repository.toggleNotifications();
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null) {
      LoggerService.info('Notifications toggled', tag: 'USER', data: {
        'enabled': user.notificationsEnabled,
      });
      
      try {
        if (user.notificationsEnabled) {
          LoggerService.debug('Enabling notifications', tag: 'USER');
          
          final hasPermissions = await NotificationService.areNotificationsEnabled();
          
          if (!hasPermissions) {
            LoggerService.debug('Requesting notification permissions', tag: 'USER');
            final granted = await NotificationService.requestPermissions();
            
            if (!granted) {
              LoggerService.warning('Permissions denied', tag: 'USER');
              
              // Re-disable if permissions refused
              await _repository.toggleNotifications();
              state = _repository.getUser();
              _notifyStateChange();
              
              return;
            }
          }
          
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            LoggerService.info('Notifications scheduled', tag: 'USER');
          } else {
            LoggerService.error('Failed to schedule notifications', tag: 'USER');
          }
          
        } else {
          LoggerService.debug('Disabling notifications', tag: 'USER');
          await NotificationService.cancelAll();
          LoggerService.info('Notifications cancelled', tag: 'USER');
        }
        
      } catch (e, stack) {
        LoggerService.error('Error toggling notifications', tag: 'USER', error: e, stackTrace: stack);
      }
    }
  }
  
  Future<void> completeOnboarding() async {
    LoggerService.debug('Completing onboarding', tag: 'USER');
    
    await _repository.completeOnboarding();
    state = _repository.getUser();
    _notifyStateChange();
    
    final user = state;
    if (user != null && user.notificationsEnabled) {
      LoggerService.debug('Scheduling initial notifications', tag: 'USER');
      
      try {
        final hasPermissions = await NotificationService.areNotificationsEnabled();
        
        if (hasPermissions) {
          final scheduled = await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
          
          if (scheduled) {
            LoggerService.info('Initial notifications scheduled', tag: 'USER');
          } else {
            LoggerService.warning('Failed to schedule initial notifications', tag: 'USER');
          }
        } else {
          LoggerService.warning('No permissions, skipping initial schedule', tag: 'USER');
        }
        
      } catch (e, stack) {
        LoggerService.error('Error scheduling initial notifications', tag: 'USER', error: e, stackTrace: stack);
      }
    }
    
    LoggerService.info('Onboarding completed', tag: 'USER');
  }
  
  Future<void> markBackedUp() async {
    LoggerService.debug('Marking as backed up', tag: 'USER');
    
    await _repository.markBackedUp();
    state = _repository.getUser();
    _notifyStateChange();
  }
}