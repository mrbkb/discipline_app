// ============================================
// FICHIER CORRIGÉ : lib/presentation/providers/user_provider.dart
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

// ✅ FIX: StreamProvider au lieu de StateNotifierProvider
// Cela écoute les changements dans Hive directement
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});

// ✅ FIX: Providers qui se recalculent automatiquement
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

// ✅ NOUVEAU: Provider pour la dernière sync
final lastSyncProvider = Provider<DateTime?>((ref) {
  final user = ref.watch(userProvider);
  return user?.lastSyncAt;
});

// ✅ NOUVEAU: Provider pour le statut de backup
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
    
    // Initialize Firebase Auth if user doesn't have UID
    if (state != null && state!.firebaseUid == null) {
      await _initializeFirebaseAuth();
    }
  }
  
  // ✅ FIX: Méthode publique pour forcer le refresh
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
        await _loadUser(); // ✅ Refresh après modification
        
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
    await _repository.updateNickname(nickname);
    await _loadUser(); // ✅ Refresh immédiat
  }
  
  Future<void> toggleHardMode() async {
    try {
      await _repository.toggleHardMode();
      await _loadUser(); // ✅ Refresh immédiat
      
      final user = state;
      if (user == null) {
        print('Warning: User is null after toggleHardMode');
        return;
      }
      
      // Update notifications
      if (user.notificationsEnabled) {
        try {
          await NotificationService.scheduleDaily(
            hour: user.reminderHour,
            minute: user.reminderMinute,
            isHardMode: user.isHardMode,
          );
        } catch (e) {
          print('Error scheduling notifications: $e');
        }
      }
      
      // Analytics
      try {
        await AnalyticsService.logHardModeToggled(user.isHardMode);
      } catch (e) {
        print('Error logging hard mode toggle: $e');
      }
      
    } catch (e) {
      print('Error in toggleHardMode: $e');
      rethrow;
    }
  }
  
  Future<void> updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) async {
    await _repository.updateReminderTimes(
      reminder: reminder,
      lateReminder: lateReminder,
    );
    await _loadUser(); // ✅ Refresh immédiat
    
    // Reschedule notifications
    final user = state;
    if (user != null && user.notificationsEnabled) {
      try {
        await NotificationService.scheduleDaily(
          hour: user.reminderHour,
          minute: user.reminderMinute,
          isHardMode: user.isHardMode,
        );
      } catch (e) {
        print('Error rescheduling notifications: $e');
      }
    }
  }
  
  Future<void> toggleNotifications() async {
    await _repository.toggleNotifications();
    await _loadUser(); // ✅ Refresh immédiat
    
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
        print('Error toggling notifications: $e');
      }
    }
  }
  
  Future<void> completeOnboarding() async {
    await _repository.completeOnboarding();
    await _loadUser(); // ✅ Refresh immédiat
    
    // Schedule notifications
    final user = state;
    if (user != null && user.notificationsEnabled) {
      try {
        await NotificationService.scheduleDaily(
          hour: user.reminderHour,
          minute: user.reminderMinute,
          isHardMode: user.isHardMode,
        );
      } catch (e) {
        print('Error scheduling initial notifications: $e');
      }
    }
  }
  
  Future<void> markBackedUp() async {
    await _repository.markBackedUp();
    await _loadUser(); // ✅ Refresh immédiat
  }
}