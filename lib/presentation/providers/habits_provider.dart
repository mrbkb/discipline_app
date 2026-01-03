// ============================================
// FICHIER CORRIGÉ : lib/presentation/providers/habits_provider.dart
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/user_repository.dart'; // ✅ AJOUT
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_service.dart';

// Repository provider
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

// ✅ User Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Habits list provider
final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider); // ✅ AJOUT
  return HabitsNotifier(repository, userRepository);
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
  HabitsNotifier(this._repository, this._userRepository) : super([]) {
    _loadHabits();
  }
  
  final HabitRepository _repository;
  final UserRepository _userRepository; // ✅ AJOUT
  
  // ========== LOAD ==========
  
  void _loadHabits() {
    state = _repository.getActiveHabits();
    print('📋 [HabitsNotifier] Loaded ${state.length} habits');
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
    print('➕ [HabitsNotifier] Creating habit: $title');
    
    final habit = await _repository.createHabit(
      title: title,
      emoji: emoji,
      color: color,
    );
    
    state = [...state, habit];
    
    // ✅ INCRÉMENTER le compteur d'habitudes créées
    await _userRepository.incrementHabitsCreated();
    print('✅ [HabitsNotifier] Habit created, counter incremented');
    
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
    print('➕ [HabitsNotifier] Creating ${habitsData.length} habits');
    
    final habits = await _repository.createMultipleHabits(habitsData);
    state = [...state, ...habits];
    
    // ✅ INCRÉMENTER le compteur pour chaque habitude
    for (int i = 0; i < habitsData.length; i++) {
      await _userRepository.incrementHabitsCreated();
    }
    print('✅ [HabitsNotifier] ${habitsData.length} habits created, counters incremented');
  }
  
  // ========== UPDATE ==========
  
  Future<void> completeHabit(String id) async {
    await _repository.completeHabit(id);
    _loadHabits();
    
    final habit = state.firstWhere((h) => h.id == id);
    
    print('✅ [HabitsNotifier] Habit completed: ${habit.title}');
    
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
    
    print('↩️ [HabitsNotifier] Habit uncompleted');
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
      print('📝 [HabitsNotifier] Habit updated: $title');
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
    
    print('🔄 [HabitsNotifier] Habits reordered');
  }
  
  // ========== DELETE ==========
  
  Future<void> archiveHabit(String id) async {
    await _repository.archiveHabit(id);
    _loadHabits();
    
    print('📦 [HabitsNotifier] Habit archived');
  }
  
  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    _loadHabits();
    
    print('🗑️ [HabitsNotifier] Habit deleted');
  }
  
  // ========== ACTIONS ==========
  
  /// Validate entire day (complete all incomplete habits)
  Future<void> validateDay() async {
    final incomplete = state.where((h) => !h.isCompletedToday()).toList();
    
    print('✅ [HabitsNotifier] Validating day: ${incomplete.length} habits to complete');
    
    for (final habit in incomplete) {
      await completeHabit(habit.id);
    }
    
    // Analytics
    await AnalyticsService.logDayValidated(
      completedHabits: state.length,
      totalHabits: state.length,
    );
    
    print('🎉 [HabitsNotifier] Day validated!');
  }
  
  /// Perform midnight reset
  Future<void> performMidnightReset() async {
    await _repository.performMidnightReset();
    _loadHabits();
    
    print('🌙 [HabitsNotifier] Midnight reset performed');
  }
}