// ============================================
// FICHIER 15/30 : lib/data/models/user_model.dart
// ============================================
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  String? firebaseUid; // null if anonymous
  
  @HiveField(1)
  String nickname;
  
  @HiveField(2)
  bool isHardMode;
  
  @HiveField(3)
  String reminderTime; // Format: "HH:mm"
  
  @HiveField(4)
  String lateReminderTime; // Format: "HH:mm"
  
  @HiveField(5)
  bool notificationsEnabled;
  
  @HiveField(6)
  final DateTime createdAt;
  
  @HiveField(7)
  bool hasBackedUp;
  
  @HiveField(8)
  DateTime? lastSyncAt;
  
  @HiveField(9)
  String? email;
  
  @HiveField(10)
  bool onboardingCompleted;
  
  @HiveField(11)
  bool isAnonymous;
  
  @HiveField(12)
  int totalHabitsCreated;
  
  @HiveField(13)
  int totalDaysActive;
  
  UserModel({
    this.firebaseUid,
    required this.nickname,
    this.isHardMode = false,
    this.reminderTime = '18:00',
    this.lateReminderTime = '21:00',
    this.notificationsEnabled = true,
    required this.createdAt,
    this.hasBackedUp = false,
    this.lastSyncAt,
    this.email,
    this.onboardingCompleted = false,
    this.isAnonymous = true,
    this.totalHabitsCreated = 0,
    this.totalDaysActive = 0,
  });
  
  // ========== COMPUTED PROPERTIES ==========
  
  /// Check if user can backup (has Firebase UID)
  bool get canBackup => firebaseUid != null;
  
  /// Check if user has upgraded from anonymous
  bool get isUpgraded => !isAnonymous && email != null;
  
  /// Get reminder hour
  int get reminderHour => int.parse(reminderTime.split(':')[0]);
  
  /// Get reminder minute
  int get reminderMinute => int.parse(reminderTime.split(':')[1]);
  
  /// Get late reminder hour
  int get lateReminderHour => int.parse(lateReminderTime.split(':')[0]);
  
  /// Get late reminder minute
  int get lateReminderMinute => int.parse(lateReminderTime.split(':')[1]);
  
  // ========== ACTIONS ==========
  
  /// Update nickname
  void updateNickname(String newNickname) {
    nickname = newNickname;
    save();
  }
  
  /// Toggle hard mode
  void toggleHardMode() {
    isHardMode = !isHardMode;
    save();
  }
  
  /// Update reminder times
  void updateReminderTimes({
    String? reminder,
    String? lateReminder,
  }) {
    if (reminder != null) reminderTime = reminder;
    if (lateReminder != null) lateReminderTime = lateReminder;
    save();
  }
  
  /// Toggle notifications
  void toggleNotifications() {
    notificationsEnabled = !notificationsEnabled;
    save();
  }
  
  /// Mark onboarding as completed
  void completeOnboarding() {
    onboardingCompleted = true;
    save();
  }
  
  /// Update Firebase UID after auth
  void updateFirebaseUid(String uid, {bool anonymous = true}) {
    firebaseUid = uid;
    isAnonymous = anonymous;
    save();
  }
  
  /// Upgrade to email account
  void upgradeToEmail(String userEmail) {
    email = userEmail;
    isAnonymous = false;
    save();
  }
  
  /// Mark as backed up
  void markBackedUp() {
    hasBackedUp = true;
    lastSyncAt = DateTime.now();
    save();
  }
  
  /// Increment total habits
  void incrementHabitsCreated() {
    totalHabitsCreated++;
    save();
  }
  
  /// Increment total days active
  void incrementDaysActive() {
    totalDaysActive++;
    save();
  }
  
  // ========== FIREBASE SERIALIZATION ==========
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'firebaseUid': firebaseUid,
      'nickname': nickname,
      'isHardMode': isHardMode,
      'reminderTime': reminderTime,
      'lateReminderTime': lateReminderTime,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'hasBackedUp': hasBackedUp,
      'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
      'email': email,
      'isAnonymous': isAnonymous,
      'totalHabitsCreated': totalHabitsCreated,
      'totalDaysActive': totalDaysActive,
    };
  }
  
  /// Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      firebaseUid: data['firebaseUid'] as String?,
      nickname: data['nickname'] as String,
      isHardMode: data['isHardMode'] as bool? ?? false,
      reminderTime: data['reminderTime'] as String? ?? '18:00',
      lateReminderTime: data['lateReminderTime'] as String? ?? '21:00',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      hasBackedUp: data['hasBackedUp'] as bool? ?? false,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSyncAt'] as int)
          : null,
      email: data['email'] as String?,
      onboardingCompleted: true, // Always true if from Firestore
      isAnonymous: data['isAnonymous'] as bool? ?? true,
      totalHabitsCreated: data['totalHabitsCreated'] as int? ?? 0,
      totalDaysActive: data['totalDaysActive'] as int? ?? 0,
    );
  }
  
  // ========== COPY WITH ==========
  
  UserModel copyWith({
    String? firebaseUid,
    String? nickname,
    bool? isHardMode,
    String? reminderTime,
    String? lateReminderTime,
    bool? notificationsEnabled,
    DateTime? createdAt,
    bool? hasBackedUp,
    DateTime? lastSyncAt,
    String? email,
    bool? onboardingCompleted,
    bool? isAnonymous,
    int? totalHabitsCreated,
    int? totalDaysActive,
  }) {
    return UserModel(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      nickname: nickname ?? this.nickname,
      isHardMode: isHardMode ?? this.isHardMode,
      reminderTime: reminderTime ?? this.reminderTime,
      lateReminderTime: lateReminderTime ?? this.lateReminderTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      hasBackedUp: hasBackedUp ?? this.hasBackedUp,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      email: email ?? this.email,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      totalHabitsCreated: totalHabitsCreated ?? this.totalHabitsCreated,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
    );
  }
  
  @override
  String toString() {
    return 'UserModel(nickname: $nickname, uid: $firebaseUid, anonymous: $isAnonymous)';
  }
}