
// ============================================
// FICHIER 18/30 : lib/data/repositories/user_repository.dart
// ============================================
import 'package:hive/hive.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final Box<UserModel> _box = StorageService.user;
  
  static const String _userKey = 'current_user';
  
  // ========== CREATE / UPDATE ==========
  
  /// Save user
  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user);
  }
  
  /// Create initial user
  Future<UserModel> createUser({
    required String nickname,
    String? firebaseUid,
    bool isAnonymous = true,
  }) async {
    final user = UserModel(
      nickname: nickname,
      firebaseUid: firebaseUid,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      onboardingCompleted: false,
    );
    
    await saveUser(user);
    return user;
  }
  
  // ========== READ ==========
  
  /// Get current user
  UserModel? getUser() {
    return _box.get(_userKey);
  }
  
  /// Check if user exists
  bool userExists() {
    return _box.containsKey(_userKey);
  }
  
  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    final user = getUser();
    return user?.onboardingCompleted ?? false;
  }
  
  // ========== UPDATE ==========
  
  /// Update user nickname
  Future<void> updateNickname(String nickname) async {
    final user = getUser();
    if (user != null) {
      user.updateNickname(nickname);
    }
  }
  
  /// Toggle hard mode
  Future<void> toggleHardMode() async {
    final user = getUser();
    if (user != null) {
      user.toggleHardMode();
    }
  }
  
  /// Update reminder times
  Future<void> updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) async {
    final user = getUser();
    if (user != null) {
      user.updateReminderTimes(
        reminder: reminder,
        lateReminder: lateReminder,
      );
    }
  }
  
  /// Toggle notifications
  Future<void> toggleNotifications() async {
    final user = getUser();
    if (user != null) {
      user.toggleNotifications();
    }
  }
  
  /// Complete onboarding
  Future<void> completeOnboarding() async {
    final user = getUser();
    if (user != null) {
      user.completeOnboarding();
    }
  }
  
  /// Update Firebase UID
  Future<void> updateFirebaseUid(String uid, {bool anonymous = true}) async {
    final user = getUser();
    if (user != null) {
      user.updateFirebaseUid(uid, anonymous: anonymous);
    }
  }
  
  /// Upgrade to email account
  Future<void> upgradeToEmail(String email) async {
    final user = getUser();
    if (user != null) {
      user.upgradeToEmail(email);
    }
  }
  
  /// Mark as backed up
  Future<void> markBackedUp() async {
    final user = getUser();
    if (user != null) {
      user.markBackedUp();
    }
  }
  
  /// Increment habits created
  Future<void> incrementHabitsCreated() async {
    final user = getUser();
    if (user != null) {
      user.incrementHabitsCreated();
    }
  }
  
  /// Increment days active
  Future<void> incrementDaysActive() async {
    final user = getUser();
    if (user != null) {
      user.incrementDaysActive();
    }
  }
  
  // ========== DELETE ==========
  
  /// Clear user data
  Future<void> clearUser() async {
    await _box.clear();
  }
}
