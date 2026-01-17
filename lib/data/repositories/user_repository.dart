
// ============================================
// FICHIER 2/4 : lib/data/repositories/user_repository.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/logger_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final Box<UserModel> _box = StorageService.user;
  
  static const String _userKey = 'current_user';
  static const _uuid = Uuid();
  
  // ========== CREATE / UPDATE ==========
  
  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user);
  }
  
  Future<UserModel> createUser({
    required String nickname,
    String? firebaseUid,
    bool isAnonymous = true,
  }) async {
    final userId = firebaseUid ?? 'local_${_uuid.v4()}';
    
    final user = UserModel(
      nickname: nickname,
      firebaseUid: userId.startsWith('local_') ? null : userId,
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      onboardingCompleted: false,
    );
    
    await saveUser(user);
    
    final mode = userId.startsWith('local_') ? 'LOCAL' : 'FIREBASE';
    LoggerService.info('User created', tag: 'USER_REPO', data: {
      'mode': mode,
      'nickname': nickname,
      'uid': userId,
    });
    
    return user;
  }
  
  // ========== READ ==========
  
  UserModel? getUser() {
    return _box.get(_userKey);
  }
  
  bool userExists() {
    return _box.containsKey(_userKey);
  }
  
  bool isOnboardingCompleted() {
    final user = getUser();
    return user?.onboardingCompleted ?? false;
  }
  
  // ========== UPDATE ==========
  
  Future<void> updateNickname(String nickname) async {
    final user = getUser();
    if (user != null) {
      user.updateNickname(nickname);
    }
  }
  
  Future<void> toggleHardMode() async {
    final user = getUser();
    if (user != null) {
      user.toggleHardMode();
    }
  }
  
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
  
  Future<void> toggleNotifications() async {
    final user = getUser();
    if (user != null) {
      user.toggleNotifications();
    }
  }
  
  Future<void> completeOnboarding() async {
    final user = getUser();
    if (user != null) {
      user.completeOnboarding();
    }
  }
  
  Future<void> migrateToFirebase(String firebaseUid) async {
    final user = getUser();
    if (user != null && user.firebaseUid == null) {
      LoggerService.info('Migrating local user to Firebase', tag: 'USER_REPO', data: {
        'uid': firebaseUid,
      });
      user.updateFirebaseUid(firebaseUid, anonymous: true);
      LoggerService.info('Migration successful', tag: 'USER_REPO');
    }
  }
  
  Future<void> updateFirebaseUid(String uid, {bool anonymous = true}) async {
    final user = getUser();
    if (user != null) {
      user.updateFirebaseUid(uid, anonymous: anonymous);
    }
  }
  
  Future<void> upgradeToEmail(String email) async {
    final user = getUser();
    if (user != null) {
      user.upgradeToEmail(email);
    }
  }
  
  Future<void> markBackedUp() async {
    final user = getUser();
    if (user != null) {
      user.markBackedUp();
    }
  }
  
  Future<void> incrementHabitsCreated() async {
    final user = getUser();
    if (user != null) {
      user.incrementHabitsCreated();
    }
  }
  
  Future<void> incrementDaysActive() async {
    final user = getUser();
    if (user != null) {
      user.incrementDaysActive();
    }
  }
  
  // ========== DELETE ==========
  
  Future<void> clearUser() async {
    await _box.clear();
    LoggerService.warning('User data cleared', tag: 'USER_REPO');
  }
}