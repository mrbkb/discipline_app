
// ============================================
// FICHIER 21/30 : lib/presentation/providers/habits_provider.dart
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_service.dart';

// Repository provider
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

// Habits list provider
final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return HabitsNotifier(repository);
});

// Active habits only provider
final activeHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitsProvider);
  return habits.where((h) => h.isActive).toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
});

// Completed today provider
final completedTodayProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  return habits.where((h) => h.isCompletedToday()).toList();
});

// Not completed today provider
final notCompletedTodayProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  return habits.where((h) => !h.isCompletedToday()).toList();
});

// Today completion rate provider
final todayCompletionRateProvider = Provider<double>((ref) {
  final activeHabits = ref.watch(activeHabitsProvider);
  if (activeHabits.isEmpty) return 0.0;
  
  final completed = activeHabits.where((h) => h.isCompletedToday()).length;
  return completed / activeHabits.length;
});

// All completed provider (check if all habits done today)
final allCompletedProvider = Provider<bool>((ref) {
  final activeHabits = ref.watch(activeHabitsProvider);
  if (activeHabits.isEmpty) return false;
  
  return activeHabits.every((h) => h.isCompletedToday());
});

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  HabitsNotifier(this._repository) : super([]) {
    _loadHabits();
  }
  
  final HabitRepository _repository;
  
  // ========== LOAD ==========
  
  void _loadHabits() {
    state = _repository.getActiveHabits();
  }
  
  void refresh() {
    _loadHabits();
  }
  
  // ========== CREATE ==========
  
  Future<HabitModel> createHabit({
    required String title,
    String? emoji,
    String? color,
  }) async {
    final habit = await _repository.createHabit(
      title: title,
      emoji: emoji,
      color: color,
    );
    
    state = [...state, habit];
    
    // Analytics
    await AnalyticsService.logEvent(
      name: 'habit_created',
      parameters: {
        'habit_title': title,
        'has_emoji': emoji != null,
      },
    );
    
    return habit;
  }
  
  Future<void> createMultipleHabits(List<Map<String, dynamic>> habitsData) async {
    final habits = await _repository.createMultipleHabits(habitsData);
    state = [...state, ...habits];
  }
  
  // ========== UPDATE ==========
  
  Future<void> completeHabit(String id) async {
    await _repository.completeHabit(id);
    _loadHabits();
    
    final habit = state.firstWhere((h) => h.id == id);
    
    // Analytics
    await AnalyticsService.logHabitValidated(
      habitId: habit.id,
      habitTitle: habit.title,
      currentStreak: habit.currentStreak,
      hour: DateTime.now().hour,
    );
    
    // Check for milestone
    if ([7, 14, 21, 30].contains(habit.currentStreak)) {
      await NotificationService.showStreakMilestone(
        habit.title,
        habit.currentStreak,
      );
    }
  }
  
  Future<void> uncompleteHabit(String id) async {
    await _repository.uncompleteHabit(id);
    _loadHabits();
  }
  
  Future<void> toggleHabitCompletion(String id) async {
    final habit = state.firstWhere((h) => h.id == id);
    
    if (habit.isCompletedToday()) {
      await uncompleteHabit(id);
    } else {
      await completeHabit(id);
    }
  }
  
  Future<void> updateHabitDetails({
    required String id,
    String? title,
    String? emoji,
    String? color,
  }) async {
    final habit = _repository.getHabitById(id);
    if (habit != null) {
      habit.updateDetails(title: title, emoji: emoji, color: color);
      _loadHabits();
    }
  }
  
  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    final newState = List<HabitModel>.from(state);
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final habit = newState.removeAt(oldIndex);
    newState.insert(newIndex, habit);
    
    state = newState;
    
    // Update order indices
    final orderedIds = newState.map((h) => h.id).toList();
    await _repository.reorderHabits(orderedIds);
  }
  
  // ========== DELETE ==========
  
  Future<void> archiveHabit(String id) async {
    await _repository.archiveHabit(id);
    _loadHabits();
  }
  
  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    _loadHabits();
  }
  
  // ========== ACTIONS ==========
  
  /// Validate entire day (complete all incomplete habits)
  Future<void> validateDay() async {
    final incomplete = state.where((h) => !h.isCompletedToday()).toList();
    
    for (final habit in incomplete) {
      await completeHabit(habit.id);
    }
    
    // Analytics
    await AnalyticsService.logDayValidated(
      completedHabits: state.length,
      totalHabits: state.length,
    );
  }
  
  /// Perform midnight reset
  Future<void> performMidnightReset() async {
    await _repository.performMidnightReset();
    _loadHabits();
  }
}
