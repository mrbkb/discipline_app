// ============================================
// FICHIER 17/30 : lib/data/repositories/habit_repository.dart
// ============================================
import 'package:hive/hive.dart';
import '../../core/services/storage_service.dart';
import '../models/habit_model.dart';
import 'package:uuid/uuid.dart';

class HabitRepository {
  final Box<HabitModel> _box = StorageService.habits;
  final _uuid = const Uuid();
  
  // ========== CREATE ==========
  
  /// Create a new habit
  Future<HabitModel> createHabit({
    required String title,
    String? emoji,
    String? color,
    int? orderIndex,
  }) async {
    final habit = HabitModel(
      id: _uuid.v4(),
      title: title,
      emoji: emoji,
      createdAt: DateTime.now(),
      orderIndex: orderIndex ?? _box.length,
      color: color,
    );
    
    await _box.put(habit.id, habit);
    return habit;
  }
  
  /// Create multiple habits at once (for onboarding)
  Future<List<HabitModel>> createMultipleHabits(
    List<Map<String, dynamic>> habitsData,
  ) async {
    final habits = <HabitModel>[];
    
    for (int i = 0; i < habitsData.length; i++) {
      final data = habitsData[i];
      final habit = HabitModel(
        id: _uuid.v4(),
        title: data['title'] as String,
        emoji: data['emoji'] as String?,
        createdAt: DateTime.now(),
        orderIndex: i,
        color: data['color'] as String?,
      );
      
      await _box.put(habit.id, habit);
      habits.add(habit);
    }
    
    return habits;
  }
  
  // ========== READ ==========
  
  /// Get all habits (active and archived)
  List<HabitModel> getAllHabits() {
    return _box.values.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  
  /// Get only active habits
  List<HabitModel> getActiveHabits() {
    return _box.values
        .where((habit) => habit.isActive)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  
  /// Get archived habits
  List<HabitModel> getArchivedHabits() {
    return _box.values
        .where((habit) => !habit.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  /// Get habit by ID
  HabitModel? getHabitById(String id) {
    return _box.get(id);
  }
  
  /// Get habits completed today
  List<HabitModel> getCompletedToday() {
    return getActiveHabits()
        .where((habit) => habit.isCompletedToday())
        .toList();
  }
  
  /// Get habits not completed today
  List<HabitModel> getNotCompletedToday() {
    return getActiveHabits()
        .where((habit) => !habit.isCompletedToday())
        .toList();
  }
  
  /// Get habits count
  int getHabitsCount({bool activeOnly = false}) {
    if (activeOnly) {
      return getActiveHabits().length;
    }
    return _box.length;
  }
  
  // ========== UPDATE ==========
  
  /// Update habit
  Future<void> updateHabit(HabitModel habit) async {
    habit.lastModified = DateTime.now();
    await habit.save();
  }
  
  /// Save a single habit (for sync/restore)
  Future<void> saveHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
  }
  
  /// Complete habit for today
  Future<void> completeHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.completeToday();
    }
  }
  
  /// Uncomplete habit for today
  Future<void> uncompleteHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.uncompleteToday();
    }
  }
  
  /// Reorder habits
  Future<void> reorderHabits(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      final habit = getHabitById(orderedIds[i]);
      if (habit != null) {
        habit.orderIndex = i;
        await habit.save();
      }
    }
  }
  
  // ========== DELETE ==========
  
  /// Delete habit permanently
  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
  }
  
  /// Archive habit (soft delete)
  Future<void> archiveHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.archive();
    }
  }
  
  /// Restore archived habit
  Future<void> restoreHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.restore();
    }
  }
  
  /// Clear all habits (for restore operation)
  Future<void> clearAll() async {
    await _box.clear();
  }
  
  // ========== ANALYTICS ==========
  
  /// Calculate average streak across all habits
  double getAverageStreak() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0.0;
    
    final totalStreak = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.currentStreak,
    );
    
    return totalStreak / habits.length;
  }
  
  /// Get total completed days across all habits
  int getTotalCompletedDays() {
    return getAllHabits().fold<int>(
      0,
      (sum, habit) => sum + habit.completedDates.length,
    );
  }
  
  /// Get best streak across all habits
  int getBestStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;
    
    return habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  }
  
  /// Get today's completion rate
  double getTodayCompletionRate() {
    final active = getActiveHabits();
    if (active.isEmpty) return 0.0;
    
    final completed = active.where((h) => h.isCompletedToday()).length;
    return completed / active.length;
  }
  
  // ========== MIDNIGHT RESET ==========
  
  /// Reset streaks for habits not completed yesterday
  Future<void> performMidnightReset() async {
    final habits = getActiveHabits();
    
    for (final habit in habits) {
      if (!habit.isCompletedYesterday()) {
        habit.resetStreak();
      }
    }
  }
}