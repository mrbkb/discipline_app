// ============================================
// FICHIER MODIFIÉ : lib/presentation/providers/user_provider.dart
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

// ✅ NOUVEAU: Provider pour savoir si l'user est en mode local
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
    
    // ✅ Tenter de se connecter à Firebase si pas encore fait
    if (state != null && state!.firebaseUid == null) {
      await _tryConnectToFirebase();
    }
  }
  
  // ✅ Forcer la notification de Riverpod
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
  
  /// ✅ NOUVEAU: Tenter de se connecter à Firebase (mode différé)
  Future<void> _tryConnectToFirebase() async {
    try {
      // Tenter la connexion
      final firebaseUser = await FirebaseService.tryConnectIfOffline();
      
      if (firebaseUser != null) {
        // Migrer l'utilisateur local vers Firebase
        await _repository.migrateToFirebase(firebaseUser.uid);
        await _loadUser();
        _notifyStateChange();
        
        print('✅ [UserNotifier] User migrated to Firebase');
        
        // Déclencher une sync automatique
        await _autoSyncAfterConnection();
      }
    } catch (e) {
      print('⚠️ [UserNotifier] Firebase connection failed (will retry later): $e');
    }
  }
  
  /// ✅ NOUVEAU: Sync automatique après connexion
  Future<void> _autoSyncAfterConnection() async {
    try {
      // TODO: Trigger auto-sync via SyncProvider
      print('🔄 [UserNotifier] Auto-sync triggered');
    } catch (e) {
      print('❌ [UserNotifier] Auto-sync failed: $e');
    }
  }
  
  /// ✅ NOUVEAU: Forcer la reconnexion à Firebase (appelé manuellement)
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
  
  /// ✅ MODIFIÉ: Créer un user même sans Firebase
  Future<void> createUser({
    required String nickname,
  }) async {
    // Tenter de se connecter à Firebase
    final firebaseUser = await FirebaseService.initializeAuth();
    
    // Créer l'user (avec ou sans Firebase)
    final user = await _repository.createUser(
      nickname: nickname,
      firebaseUid: firebaseUser?.uid, // null si offline
      isAnonymous: firebaseUser?.isAnonymous ?? true,
    );
    
    state = user;
    
    // Si en mode local, afficher un message
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
  
  Future<void> toggleHardMode() async {
    try {
      print('🔵 [UserNotifier] toggleHardMode');
      
      await _repository.toggleHardMode();
      state = _repository.getUser();
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
    
    state = _repository.getUser();
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
    
    await _repository.toggleNotifications();
    state = _repository.getUser();
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
    state = _repository.getUser();
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
    state = _repository.getUser();
    _notifyStateChange();
  }
}