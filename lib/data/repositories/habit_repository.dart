// ============================================
// FICHIER 1/4 : lib/data/repositories/habit_repository.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:hive/hive.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/logger_service.dart';
import '../models/habit_model.dart';
import 'package:uuid/uuid.dart';

class HabitRepository {
  final Box<HabitModel> _box = StorageService.habits;
  final _uuid = const Uuid();
  
  // ========== CREATE ==========
  
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
    LoggerService.debug('Habit created in storage', tag: 'HABIT_REPO', data: {
      'id': habit.id,
      'title': title,
    });
    
    return habit;
  }
  
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
    
    LoggerService.info('Multiple habits created', tag: 'HABIT_REPO', data: {
      'count': habits.length,
    });
    
    return habits;
  }
  
  // ========== READ ==========
  
  List<HabitModel> getAllHabits() {
    return _box.values.toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  
  List<HabitModel> getActiveHabits() {
    return _box.values
        .where((habit) => habit.isActive)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  
  List<HabitModel> getArchivedHabits() {
    return _box.values
        .where((habit) => !habit.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  HabitModel? getHabitById(String id) {
    return _box.get(id);
  }
  
  List<HabitModel> getCompletedToday() {
    return getActiveHabits()
        .where((habit) => habit.isCompletedToday())
        .toList();
  }
  
  List<HabitModel> getNotCompletedToday() {
    return getActiveHabits()
        .where((habit) => !habit.isCompletedToday())
        .toList();
  }
  
  int getHabitsCount({bool activeOnly = false}) {
    if (activeOnly) {
      return getActiveHabits().length;
    }
    return _box.length;
  }
  
  // ========== UPDATE ==========
  
  Future<void> updateHabit(HabitModel habit) async {
    habit.lastModified = DateTime.now();
    await habit.save();
  }
  
  Future<void> saveHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
  }
  
  Future<void> completeHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.completeToday();
      LoggerService.debug('Habit completed', tag: 'HABIT_REPO', data: {'id': id});
    }
  }
  
  Future<void> uncompleteHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.uncompleteToday();
      LoggerService.debug('Habit uncompleted', tag: 'HABIT_REPO', data: {'id': id});
    }
  }
  
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
  
  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
    LoggerService.info('Habit deleted', tag: 'HABIT_REPO', data: {'id': id});
  }
  
  Future<void> archiveHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.archive();
      LoggerService.info('Habit archived', tag: 'HABIT_REPO', data: {'id': id});
    }
  }
  
  Future<void> restoreHabit(String id) async {
    final habit = getHabitById(id);
    if (habit != null) {
      habit.restore();
    }
  }
  
  Future<void> clearAll() async {
    await _box.clear();
    LoggerService.warning('All habits cleared', tag: 'HABIT_REPO');
  }
  
  // ========== ANALYTICS ==========
  
  double getAverageStreak() {
    final habits = getActiveHabits();
    if (habits.isEmpty) return 0.0;
    
    final totalStreak = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.currentStreak,
    );
    
    return totalStreak / habits.length;
  }
  
  int getTotalCompletedDays() {
    return getAllHabits().fold<int>(
      0,
      (sum, habit) => sum + habit.completedDates.length,
    );
  }
  
  int getBestStreak() {
    final habits = getAllHabits();
    if (habits.isEmpty) return 0;
    
    return habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  }
  
  double getTodayCompletionRate() {
    final active = getActiveHabits();
    if (active.isEmpty) return 0.0;
    
    final completed = active.where((h) => h.isCompletedToday()).length;
    return completed / active.length;
  }
  
  // ========== MIDNIGHT RESET ==========
  
  Future<void> performMidnightReset() async {
    final habits = getActiveHabits();
    
    for (final habit in habits) {
      if (!habit.isCompletedYesterday()) {
        habit.resetStreak();
      }
    }
    
    LoggerService.info('Midnight reset completed', tag: 'HABIT_REPO', data: {
      'habits': habits.length,
    });
  }
}
