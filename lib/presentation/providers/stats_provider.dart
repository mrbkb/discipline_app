// ============================================
// FICHIER 24/30 : lib/presentation/providers/stats_provider.dart
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_snapshot_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../data/repositories/habit_repository.dart';
import 'habits_provider.dart';

// Repository provider
final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository();
});

// Weekly snapshots provider
final weeklySnapshotsProvider = Provider<List<DailySnapshotModel>>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getLastWeekSnapshots();
});

// Weekly completion rate provider
final weeklyCompletionRateProvider = Provider<double>((ref) {
  final snapshots = ref.watch(weeklySnapshotsProvider);
  if (snapshots.isEmpty) return 0.0;
  
  final totalRate = snapshots.fold<double>(
    0.0,
    (sum, s) => sum + s.completionRate,
  );
  
  return totalRate / snapshots.length;
});

// Weekly completion percentage provider
final weeklyCompletionPercentageProvider = Provider<int>((ref) {
  final rate = ref.watch(weeklyCompletionRateProvider);
  return (rate * 100).round();
});

// Best flame level provider
final bestFlameLevelProvider = Provider<double>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getBestFlameLevel();
});

// Best flame percentage provider
final bestFlamePercentageProvider = Provider<int>((ref) {
  final level = ref.watch(bestFlameLevelProvider);
  return (level * 100).round();
});

// Perfect days count provider
final perfectDaysCountProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.countPerfectDays();
});

// Current perfect streak provider
final currentPerfectStreakProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getCurrentPerfectStreak();
});

// Total active days provider
final totalActiveDaysProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getSnapshotsCount();
});

// Best streak across all habits provider
final bestStreakProvider = Provider<int>((ref) {
  final habitRepository = ref.watch(habitRepositoryProvider);
  return habitRepository.getBestStreak();
});

// Average streak provider
final averageStreakProvider = Provider<double>((ref) {
  final habitRepository = ref.watch(habitRepositoryProvider);
  return habitRepository.getAverageStreak();
});

// Stats notifier for actions
final statsNotifierProvider = StateNotifierProvider<StatsNotifier, AsyncValue<void>>((ref) {
  final snapshotRepository = ref.watch(snapshotRepositoryProvider);
  final habitRepository = ref.watch(habitRepositoryProvider);
  return StatsNotifier(snapshotRepository, habitRepository);
});

class StatsNotifier extends StateNotifier<AsyncValue<void>> {
  StatsNotifier(this._snapshotRepository, this._habitRepository) 
      : super(const AsyncValue.data(null));
  
  final SnapshotRepository _snapshotRepository;
  final HabitRepository _habitRepository;
  
  // ========== SNAPSHOT CREATION ==========
  
  Future<void> createTodaySnapshot() async {
    state = const AsyncValue.loading();
    
    try {
      final habits = _habitRepository.getActiveHabits();
      await _snapshotRepository.createSnapshot(habits: habits);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> createSnapshotForDate(String date, List<HabitModel> habits) async {
    state = const AsyncValue.loading();
    
    try {
      await _snapshotRepository.createSnapshot(
        habits: habits,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  // ========== MAINTENANCE ==========
  
  Future<void> cleanupOldSnapshots({int keepDays = 30}) async {
    try {
      await _snapshotRepository.deleteOldSnapshots(keepDays);
    } catch (e) {
      print('Error cleaning up old snapshots: $e');
    }
  }
}