

// ============================================
// FICHIER 14/30 : lib/data/models/habit_model.dart
// ============================================
import 'package:hive/hive.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/streak_calculator.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String? emoji;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  List<String> completedDates; // Format: 'yyyy-MM-dd'
  
  @HiveField(5)
  int currentStreak;
  
  @HiveField(6)
  int bestStreak;
  
  @HiveField(7)
  bool isActive;
  
  @HiveField(8)
  int orderIndex;
  
  @HiveField(9)
  DateTime? lastModified;
  
  @HiveField(10)
  String? color; // Hex color for UI customization
  
  HabitModel({
    required this.id,
    required this.title,
    this.emoji,
    required this.createdAt,
    List<String>? completedDates,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isActive = true,
    this.orderIndex = 0,
    this.lastModified,
    this.color,
  }) : completedDates = completedDates ?? [];
  
  // ========== COMPUTED PROPERTIES ==========
  
  /// Health score based on current vs best streak
  double get healthScore {
    if (bestStreak == 0) return 1.0;
    return (currentStreak / bestStreak).clamp(0.0, 1.0);
  }
  
  /// Check if completed today
  bool isCompletedToday() {
    final today = DateHelper.getTodayString();
    return completedDates.contains(today);
  }
  
  /// Check if completed yesterday
  bool isCompletedYesterday() {
    final yesterday = DateHelper.getYesterdayString();
    return completedDates.contains(yesterday);
  }
  
  /// Get completion rate for last N days
  double getCompletionRate(int days) {
    final lastDays = DateHelper.getLast7Days();
    final completed = completedDates.where((date) => lastDays.contains(date)).length;
    return completed / days;
  }
  
  // ========== ACTIONS ==========
  
  /// Mark habit as completed for today
  void completeToday() {
    final today = DateHelper.getTodayString();
    
    if (!completedDates.contains(today)) {
      completedDates.add(today);
      
      // Recalculate streak
      currentStreak = StreakCalculator.calculateCurrentStreak(completedDates);
      
      // Update best streak if needed
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
      
      lastModified = DateTime.now();
      save();
    }
  }
  
  /// Undo today's completion
  void uncompleteToday() {
    final today = DateHelper.getTodayString();
    
    if (completedDates.contains(today)) {
      completedDates.remove(today);
      
      // Recalculate streak
      currentStreak = StreakCalculator.calculateCurrentStreak(completedDates);
      
      lastModified = DateTime.now();
      save();
    }
  }
  
  /// Reset streak (called at midnight if not completed)
  void resetStreak() {
    if (currentStreak > 0) {
      currentStreak = 0;
      lastModified = DateTime.now();
      save();
    }
  }
  
  /// Update habit details
  void updateDetails({
    String? title,
    String? emoji,
    String? color,
  }) {
    if (title != null) this.title = title;
    if (emoji != null) this.emoji = emoji;
    if (color != null) this.color = color;
    
    lastModified = DateTime.now();
    save();
  }
  
  /// Archive habit
  void archive() {
    isActive = false;
    lastModified = DateTime.now();
    save();
  }
  
  /// Restore archived habit
  void restore() {
    isActive = true;
    lastModified = DateTime.now();
    save();
  }
  
  // ========== FIREBASE SERIALIZATION ==========
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates': completedDates,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isActive': isActive,
      'orderIndex': orderIndex,
      'lastModified': (lastModified ?? DateTime.now()).millisecondsSinceEpoch,
      'color': color,
    };
  }
  
  /// Create from Firestore document
  factory HabitModel.fromFirestore(Map<String, dynamic> data) {
    return HabitModel(
      id: data['id'] as String,
      title: data['title'] as String,
      emoji: data['emoji'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      completedDates: List<String>.from(data['completedDates'] ?? []),
      currentStreak: data['currentStreak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      orderIndex: data['orderIndex'] as int? ?? 0,
      lastModified: data['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastModified'] as int)
          : null,
      color: data['color'] as String?,
    );
  }
  
  // ========== COPY WITH ==========
  
  HabitModel copyWith({
    String? id,
    String? title,
    String? emoji,
    DateTime? createdAt,
    List<String>? completedDates,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    int? orderIndex,
    DateTime? lastModified,
    String? color,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? List<String>.from(this.completedDates),
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
      lastModified: lastModified ?? this.lastModified,
      color: color ?? this.color,
    );
  }
  
  @override
  String toString() {
    return 'HabitModel(id: $id, title: $title, streak: $currentStreak/$bestStreak, completed: ${completedDates.length})';
  }
}
