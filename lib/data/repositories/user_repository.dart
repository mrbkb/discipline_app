// ============================================
// FICHIER MODIFIÉ : lib/data/repositories/user_repository.dart
// ============================================
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final Box<UserModel> _box = StorageService.user;
  
  static const String _userKey = 'current_user';
  static const _uuid = Uuid();
  
  // ========== CREATE / UPDATE ==========
  
  /// Save user
  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user);
  }
  
  /// ✅ MODIFIÉ: Create initial user SANS exiger firebaseUid
  /// Génère un UUID local si pas de Firebase
  Future<UserModel> createUser({
    required String nickname,
    String? firebaseUid,
    bool isAnonymous = true,
  }) async {
    // ✅ Si pas de firebaseUid (mode offline), générer un UUID local
    final userId = firebaseUid ?? 'local_${_uuid.v4()}';
    
    final user = UserModel(
      nickname: nickname,
      firebaseUid: userId.startsWith('local_') ? null : userId, // null si local
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      onboardingCompleted: false,
    );
    
    await saveUser(user);
    
    print('✅ [UserRepo] User created: ${userId.startsWith('local_') ? 'LOCAL' : 'FIREBASE'}');
    print('   Nickname: $nickname');
    print('   UID: $userId');
    
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
  
  /// ✅ NOUVEAU: Migrer un utilisateur local vers Firebase
  /// Appelé quand la connexion Internet est rétablie
  Future<void> migrateToFirebase(String firebaseUid) async {
    final user = getUser();
    if (user != null && user.firebaseUid == null) {
      print('🔄 [UserRepo] Migrating local user to Firebase: $firebaseUid');
      user.updateFirebaseUid(firebaseUid, anonymous: true);
      print('✅ [UserRepo] Migration successful');
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