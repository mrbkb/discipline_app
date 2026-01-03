// ============================================
// FICHIER CORRIGÉ ULTIME : lib/presentation/providers/user_provider.dart
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

// ✅ StateNotifierProvider
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

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier(this._repository) : super(null) {
    _loadUser();
  }
  
  final UserRepository _repository;
  
  // ========== LOAD ==========
  
  Future<void> _loadUser() async {
    state = _repository.getUser();
    
    if (state != null && state!.firebaseUid == null) {
      await _initializeFirebaseAuth();
    }
  }
  
  // ✅ FIX CRITIQUE: Forcer la notification de Riverpod
  // En créant une NOUVELLE instance avec copyWith
  void _notifyStateChange() {
    if (state != null) {
      print('🔔 [UserNotifier] Forcing state notification');
      // ✅ Créer une nouvelle instance pour déclencher le rebuild
      state = state!.copyWith();
    }
  }
  
  Future<void> refresh() async {
    await _loadUser();
  }
  
  // ========== FIREBASE AUTH ==========
  
  Future<void> _initializeFirebaseAuth() async {
    try {
      final user = await FirebaseService.initializeAuth();
      if (user != null) {
        await _repository.updateFirebaseUid(user.uid, anonymous: user.isAnonymous);
        await _loadUser();
        _notifyStateChange(); // ✅ Forcer notification
      }
    } catch (e) {
      print('Error initializing Firebase Auth: $e');
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
        _notifyStateChange(); // ✅ Forcer notification
        
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
  }
  
  // ========== UPDATE ==========
  
  Future<void> updateNickname(String nickname) async {
    print('🔵 [UserNotifier] updateNickname: $nickname');
    print('  Current state: ${state?.nickname}');
    
    await _repository.updateNickname(nickname);
    
    // ✅ Recharger depuis Hive
    state = _repository.getUser();
    print('  New state: ${state?.nickname}');
    
    // ✅ CRITIQUE: Forcer la notification
    _notifyStateChange();
  }
  
  Future<void> toggleHardMode() async {
    try {
      print('🔵 [UserNotifier] toggleHardMode');
      print('  Current state: ${state?.isHardMode}');
      
      await _repository.toggleHardMode();
      
      // ✅ Recharger depuis Hive
      state = _repository.getUser();
      print('  New state: ${state?.isHardMode}');
      
      // ✅ CRITIQUE: Forcer la notification
      _notifyStateChange();
      
      final user = state;
      if (user != null && user.notificationsEnabled) {
        try {
          await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
        } catch (e) {
          print('❌ Error scheduling notifications: $e');
        }
      }
      
      try {
        await AnalyticsService.logHardModeToggled(state!.isHardMode);
      } catch (e) {
        print('❌ Error logging hard mode toggle: $e');
      }
      
    } catch (e) {
      print('❌ Error in toggleHardMode: $e');
      rethrow;
    }
  }
  
  Future<void> updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) async {
    print('🔵 [UserNotifier] updateReminderTimes');
    
    await _repository.updateReminderTimes(
      reminder: reminder,
      lateReminder: lateReminder,
    );
    
    // ✅ Recharger depuis Hive
    state = _repository.getUser();
    print('  New times: ${state?.reminderTime}, ${state?.lateReminderTime}');
    
    // ✅ CRITIQUE: Forcer la notification
    _notifyStateChange();
    
    final user = state;
    if (user != null && user.notificationsEnabled) {
      try {
        await NotificationService.scheduleDaily(
          hour: user.reminderHour,
          minute: user.reminderMinute,
          isHardMode: user.isHardMode,
        );
      } catch (e) {
        print('❌ Error rescheduling notifications: $e');
      }
    }
  }
  
  Future<void> toggleNotifications() async {
    print('🔵 [UserNotifier] toggleNotifications');
    print('  Current state: ${state?.notificationsEnabled}');
    
    await _repository.toggleNotifications();
    
    // ✅ Recharger depuis Hive
    state = _repository.getUser();
    print('  New state: ${state?.notificationsEnabled}');
    
    // ✅ CRITIQUE: Forcer la notification
    _notifyStateChange();
    
    final user = state;
    if (user != null) {
      try {
        if (user.notificationsEnabled) {
          await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
        } else {
          await NotificationService.cancelAll();
        }
      } catch (e) {
        print('❌ Error toggling notifications: $e');
      }
    }
  }
  
  Future<void> completeOnboarding() async {
    print('🔵 [UserNotifier] completeOnboarding');
    
    await _repository.completeOnboarding();
    
    // ✅ Recharger depuis Hive
    state = _repository.getUser();
    
    // ✅ CRITIQUE: Forcer la notification
    _notifyStateChange();
    
    final user = state;
    if (user != null && user.notificationsEnabled) {
      try {
        await NotificationService.scheduleDaily(
          hour: user.reminderHour,
          minute: user.reminderMinute,
          isHardMode: user.isHardMode,
        );
      } catch (e) {
        print('❌ Error scheduling initial notifications: $e');
      }
    }
  }
  
  Future<void> markBackedUp() async {
    print('🔵 [UserNotifier] markBackedUp');
    
    await _repository.markBackedUp();
    
    // ✅ Recharger depuis Hive
    state = _repository.getUser();
    
    // ✅ CRITIQUE: Forcer la notification
    _notifyStateChange();
  }
}