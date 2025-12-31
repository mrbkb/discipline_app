
// ============================================
// FICHIER 19/30 : lib/data/repositories/snapshot_repository.dart
// ============================================
import 'package:hive/hive.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/date_helper.dart';
import '../models/daily_snapshot_model.dart';
import '../models/habit_model.dart';

class SnapshotRepository {
  final Box<DailySnapshotModel> _box = StorageService.snapshots;
  
  // ========== CREATE ==========
  
  /// Create snapshot from current habits state
  Future<DailySnapshotModel> createSnapshot({
    required List<HabitModel> habits,
    String? date,
  }) async {
    final snapshotDate = date ?? DateHelper.getTodayString();
    
    final completedCount = habits.where((h) => h.isCompletedToday()).length;
    final totalCount = habits.length;
    final flameLevel = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    final totalStreak = habits.fold<int>(
      0,
      (sum, h) => sum + h.currentStreak,
    );
    
    final habitStreaks = <String, int>{};
    for (final habit in habits) {
      habitStreaks[habit.id] = habit.currentStreak;
    }
    
    final snapshot = DailySnapshotModel(
      date: snapshotDate,
      completedHabits: completedCount,
      totalHabits: totalCount,
      flameLevel: flameLevel,
      totalStreak: totalStreak,
      snapshotTime: DateTime.now(),
      habitStreaks: habitStreaks,
    );
    
    await _box.put(snapshotDate, snapshot);
    return snapshot;
  }
  
  // ========== READ ==========
  
  /// Get snapshot by date
  DailySnapshotModel? getSnapshotByDate(String date) {
    return _box.get(date);
  }
  
  /// Get today's snapshot
  DailySnapshotModel? getTodaySnapshot() {
    return getSnapshotByDate(DateHelper.getTodayString());
  }
  
  /// Get last N snapshots
  List<DailySnapshotModel> getLastNSnapshots(int n) {
    final snapshots = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    return snapshots.take(n).toList();
  }
  
  /// Get snapshots for last 7 days
  List<DailySnapshotModel> getLastWeekSnapshots() {
    final last7Days = DateHelper.getLast7Days();
    final snapshots = <DailySnapshotModel>[];
    
    for (final date in last7Days) {
      final snapshot = getSnapshotByDate(date);
      if (snapshot != null) {
        snapshots.add(snapshot);
      } else {
        // Create empty snapshot for missing days
        snapshots.add(DailySnapshotModel(
          date: date,
          completedHabits: 0,
          totalHabits: 0,
          flameLevel: 0.0,
          totalStreak: 0,
          snapshotTime: DateTime.now(),
        ));
      }
    }
    
    return snapshots;
  }
  
  /// Get all snapshots
  List<DailySnapshotModel> getAllSnapshots() {
    return _box.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  
  /// Get snapshots count
  int getSnapshotsCount() {
    return _box.length;
  }
  
  // ========== ANALYTICS ==========
  
  /// Calculate average completion rate over last N days
  double getAverageCompletionRate(int days) {
    final snapshots = getLastNSnapshots(days);
    if (snapshots.isEmpty) return 0.0;
    
    final totalRate = snapshots.fold<double>(
      0.0,
      (sum, s) => sum + s.completionRate,
    );
    
    return totalRate / snapshots.length;
  }
  
  /// Get best flame level
  double getBestFlameLevel() {
    if (_box.isEmpty) return 0.0;
    
    return _box.values
        .map((s) => s.flameLevel)
        .reduce((a, b) => a > b ? a : b);
  }
  
  /// Count perfect days (100% completion)
  int countPerfectDays() {
    return _box.values.where((s) => s.isPerfectDay).length;
  }
  
  /// Get current streak of perfect days
  int getCurrentPerfectStreak() {
    final snapshots = _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    for (final snapshot in snapshots) {
      if (snapshot.isPerfectDay) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  // ========== MAINTENANCE ==========
  
  /// Delete snapshots older than N days
  Future<void> deleteOldSnapshots(int keepDays) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final cutoffString = DateHelper.formatDate(cutoffDate);
    
    final toDelete = <String>[];
    for (final entry in _box.toMap().entries) {
      if (entry.key.compareTo(cutoffString) < 0) {
        toDelete.add(entry.key);
      }
    }
    
    for (final key in toDelete) {
      await _box.delete(key);
    }
  }
  
  /// Clear all snapshots
  Future<void> clearAllSnapshots() async {
    await _box.clear();
  }
}