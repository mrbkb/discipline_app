

// ============================================
// FICHIER 16/30 : lib/data/models/daily_snapshot_model.dart
// ============================================
import 'package:hive/hive.dart';

part 'daily_snapshot_model.g.dart';

@HiveType(typeId: 2)
class DailySnapshotModel extends HiveObject {
  @HiveField(0)
  final String date; // Format: 'yyyy-MM-dd'
  
  @HiveField(1)
  final int completedHabits;
  
  @HiveField(2)
  final int totalHabits;
  
  @HiveField(3)
  final double flameLevel; // 0.0 - 1.0
  
  @HiveField(4)
  final int totalStreak; // Sum of all streaks
  
  @HiveField(5)
  final DateTime snapshotTime;
  
  @HiveField(6)
  final Map<String, int> habitStreaks; // habitId -> streak
  
  DailySnapshotModel({
    required this.date,
    required this.completedHabits,
    required this.totalHabits,
    required this.flameLevel,
    required this.totalStreak,
    required this.snapshotTime,
    Map<String, int>? habitStreaks,
  }) : habitStreaks = habitStreaks ?? {};
  
  // ========== COMPUTED PROPERTIES ==========
  
  /// Completion rate (0.0 - 1.0)
  double get completionRate {
    if (totalHabits == 0) return 0.0;
    return completedHabits / totalHabits;
  }
  
  /// Completion percentage (0 - 100)
  int get completionPercentage {
    return (completionRate * 100).round();
  }
  
  /// Check if perfect day (all habits completed)
  bool get isPerfectDay => completedHabits == totalHabits && totalHabits > 0;
  
  /// Get average streak
  double get averageStreak {
    if (totalHabits == 0) return 0.0;
    return totalStreak / totalHabits;
  }
  
  // ========== FIREBASE SERIALIZATION ==========
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'completedHabits': completedHabits,
      'totalHabits': totalHabits,
      'flameLevel': flameLevel,
      'totalStreak': totalStreak,
      'snapshotTime': snapshotTime.millisecondsSinceEpoch,
      'habitStreaks': habitStreaks,
    };
  }
  
  /// Create from Firestore document
  factory DailySnapshotModel.fromFirestore(Map<String, dynamic> data) {
    return DailySnapshotModel(
      date: data['date'] as String,
      completedHabits: data['completedHabits'] as int,
      totalHabits: data['totalHabits'] as int,
      flameLevel: (data['flameLevel'] as num).toDouble(),
      totalStreak: data['totalStreak'] as int,
      snapshotTime: DateTime.fromMillisecondsSinceEpoch(data['snapshotTime'] as int),
      habitStreaks: Map<String, int>.from(data['habitStreaks'] ?? {}),
    );
  }
  
  @override
  String toString() {
    return 'DailySnapshot($date: $completedHabits/$totalHabits, flame: ${(flameLevel * 100).round()}%)';
  }
}
