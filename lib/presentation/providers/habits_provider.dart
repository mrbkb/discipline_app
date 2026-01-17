// ============================================
// FICHIER PRODUCTION : lib/presentation/providers/habits_provider.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/logger_service.dart';

// Repository provider
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Habits list provider
final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
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

// All completed provider
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
  final UserRepository _userRepository;
  
  // ========== LOAD ==========
  
  void _loadHabits() {
    state = _repository.getActiveHabits();
    LoggerService.debug('Habits loaded', tag: 'HABITS', data: {'count': state.length});
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
    LoggerService.info('Creating habit', tag: 'HABITS', data: {'title': title});
    
    final habit = await _repository.createHabit(
      title: title,
      emoji: emoji,
      color: color,
    );
    
    state = [...state, habit];
    
    await _userRepository.incrementHabitsCreated();
    LoggerService.debug('Habit counter incremented', tag: 'HABITS');
    
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
    LoggerService.info('Creating multiple habits', tag: 'HABITS', data: {
      'count': habitsData.length,
    });
    
    final habits = await _repository.createMultipleHabits(habitsData);
    state = [...state, ...habits];
    
    for (int i = 0; i < habitsData.length; i++) {
      await _userRepository.incrementHabitsCreated();
    }
    
    LoggerService.info('Multiple habits created', tag: 'HABITS', data: {
      'count': habitsData.length,
    });
  }
  
  // ========== UPDATE ==========
  
  Future<void> completeHabit(String id) async {
    await _repository.completeHabit(id);
    _loadHabits();
    
    final habit = state.firstWhere((h) => h.id == id);
    
    LoggerService.info('Habit completed', tag: 'HABITS', data: {
      'title': habit.title,
      'streak': habit.currentStreak,
    });
    
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
    
    LoggerService.debug('Habit uncompleted', tag: 'HABITS', data: {'id': id});
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
      
      LoggerService.info('Habit updated', tag: 'HABITS', data: {
        'id': id,
        'title': title,
      });
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
    
    final orderedIds = newState.map((h) => h.id).toList();
    await _repository.reorderHabits(orderedIds);
    
    LoggerService.debug('Habits reordered', tag: 'HABITS');
  }
  
  // ========== DELETE ==========
  
  Future<void> archiveHabit(String id) async {
    await _repository.archiveHabit(id);
    _loadHabits();
    
    LoggerService.info('Habit archived', tag: 'HABITS', data: {'id': id});
  }
  
  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    _loadHabits();
    
    LoggerService.info('Habit deleted', tag: 'HABITS', data: {'id': id});
  }
  
  // ========== ACTIONS ==========
  
  Future<void> validateDay() async {
    final incomplete = state.where((h) => !h.isCompletedToday()).toList();
    
    LoggerService.info('Validating day', tag: 'HABITS', data: {
      'incomplete': incomplete.length,
      'total': state.length,
    });
    
    for (final habit in incomplete) {
      await completeHabit(habit.id);
    }
    
    await AnalyticsService.logDayValidated(
      completedHabits: state.length,
      totalHabits: state.length,
    );
    
    LoggerService.info('Day validated', tag: 'HABITS');
  }
  
  Future<void> performMidnightReset() async {
    await _repository.performMidnightReset();
    _loadHabits();
    
    LoggerService.info('Midnight reset performed', tag: 'HABITS');
  }
}