// ============================================
// FICHIER NETTOYÉ : lib/presentation/providers/stats_provider.dart
// ✅ Tous les print() retirés
// ============================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_snapshot_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../core/services/logger_service.dart';
import 'habits_provider.dart';

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository();
});

final currentStatsProvider = Provider<CurrentStats>((ref) {
  final habits = ref.watch(activeHabitsProvider);
  
  if (habits.isEmpty) {
    return CurrentStats(
      completedToday: 0,
      totalHabits: 0,
      completionRate: 0.0,
      totalStreak: 0,
      averageStreak: 0.0,
      bestStreak: 0,
      perfectDays: 0,
      totalActiveDays: 0,
    );
  }
  
  final completedToday = habits.where((h) => h.isCompletedToday()).length;
  final totalHabits = habits.length;
  final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;
  
  final totalStreak = habits.fold<int>(0, (sum, h) => sum + h.currentStreak);
  final averageStreak = totalHabits > 0 ? totalStreak / totalHabits : 0.0;
  
  final bestStreak = habits.isEmpty 
      ? 0 
      : habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  
  final snapshotRepo = ref.watch(snapshotRepositoryProvider);
  final perfectDays = snapshotRepo.countPerfectDays();
  final totalActiveDays = snapshotRepo.getSnapshotsCount();
  
  return CurrentStats(
    completedToday: completedToday,
    totalHabits: totalHabits,
    completionRate: completionRate,
    totalStreak: totalStreak,
    averageStreak: averageStreak,
    bestStreak: bestStreak,
    perfectDays: perfectDays,
    totalActiveDays: totalActiveDays,
  );
});

final weeklySnapshotsProvider = Provider<List<DailySnapshotModel>>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getLastWeekSnapshots();
});

final weeklyCompletionRateProvider = Provider<double>((ref) {
  final snapshots = ref.watch(weeklySnapshotsProvider);
  if (snapshots.isEmpty) return 0.0;
  
  final totalRate = snapshots.fold<double>(
    0.0,
    (sum, s) => sum + s.completionRate,
  );
  
  return totalRate / snapshots.length;
});

final weeklyCompletionPercentageProvider = Provider<int>((ref) {
  final rate = ref.watch(weeklyCompletionRateProvider);
  return (rate * 100).round();
});

final bestFlameLevelProvider = Provider<double>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getBestFlameLevel();
});

final bestFlamePercentageProvider = Provider<int>((ref) {
  final level = ref.watch(bestFlameLevelProvider);
  return (level * 100).round();
});

final perfectDaysCountProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.countPerfectDays();
});

final currentPerfectStreakProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getCurrentPerfectStreak();
});

final totalActiveDaysProvider = Provider<int>((ref) {
  final repository = ref.watch(snapshotRepositoryProvider);
  return repository.getSnapshotsCount();
});

final bestStreakProvider = Provider<int>((ref) {
  final stats = ref.watch(currentStatsProvider);
  return stats.bestStreak;
});

final averageStreakProvider = Provider<double>((ref) {
  final stats = ref.watch(currentStatsProvider);
  return stats.averageStreak;
});

final statsNotifierProvider = StateNotifierProvider<StatsNotifier, AsyncValue<void>>((ref) {
  final snapshotRepository = ref.watch(snapshotRepositoryProvider);
  final habitRepository = ref.watch(habitRepositoryProvider);
  return StatsNotifier(snapshotRepository, habitRepository);
});

class CurrentStats {
  final int completedToday;
  final int totalHabits;
  final double completionRate;
  final int totalStreak;
  final double averageStreak;
  final int bestStreak;
  final int perfectDays;
  final int totalActiveDays;
  
  CurrentStats({
    required this.completedToday,
    required this.totalHabits,
    required this.completionRate,
    required this.totalStreak,
    required this.averageStreak,
    required this.bestStreak,
    required this.perfectDays,
    required this.totalActiveDays,
  });
}

class StatsNotifier extends StateNotifier<AsyncValue<void>> {
  StatsNotifier(this._snapshotRepository, this._habitRepository) 
      : super(const AsyncValue.data(null));
  
  final SnapshotRepository _snapshotRepository;
  final HabitRepository _habitRepository;
  
  Future<void> createTodaySnapshot() async {
    state = const AsyncValue.loading();
    
    try {
      final habits = _habitRepository.getActiveHabits();
      await _snapshotRepository.createSnapshot(habits: habits);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      LoggerService.error('Snapshot creation error', tag: 'STATS', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> createSnapshotForDate(String date, List<HabitModel> habits) async {
    state = const AsyncValue.loading();
    
    try {
      await _snapshotRepository.createSnapshot(habits: habits, date: date);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      LoggerService.error('Snapshot creation error', tag: 'STATS', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> cleanupOldSnapshots({int keepDays = 30}) async {
    try {
      await _snapshotRepository.deleteOldSnapshots(keepDays);
    } catch (e, stack) {
      LoggerService.error('Cleanup error', tag: 'STATS', error: e, stackTrace: stack);
    }
  }
}