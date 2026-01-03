// ============================================
// FICHIER CORRIGÉ : lib/presentation/providers/stats_provider.dart
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

// ✅ FIX: Calculer les stats en temps réel depuis les habits, pas les snapshots
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
  
  // Calculer en temps réel
  final completedToday = habits.where((h) => h.isCompletedToday()).length;
  final totalHabits = habits.length;
  final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;
  
  // Total streak = somme de tous les streaks actuels
  final totalStreak = habits.fold<int>(0, (sum, h) => sum + h.currentStreak);
  
  // Average streak
  final averageStreak = totalHabits > 0 ? totalStreak / totalHabits : 0.0;
  
  // Best streak parmi toutes les habitudes
  final bestStreak = habits.isEmpty 
      ? 0 
      : habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  
  // Snapshots pour les stats historiques
  final snapshotRepo = ref.watch(snapshotRepositoryProvider);
  final perfectDays = snapshotRepo.countPerfectDays();
  final totalActiveDays = snapshotRepo.getSnapshotsCount();
  
  print('📊 [Stats] Calculated:');
  print('  Completed today: $completedToday/$totalHabits');
  print('  Total streak: $totalStreak');
  print('  Average streak: $averageStreak');
  print('  Best streak: $bestStreak');
  print('  Perfect days: $perfectDays');
  print('  Total active days: $totalActiveDays');
  
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

// Best flame level provider (depuis les snapshots)
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
  final stats = ref.watch(currentStatsProvider);
  return stats.bestStreak;
});

// Average streak provider
final averageStreakProvider = Provider<double>((ref) {
  final stats = ref.watch(currentStatsProvider);
  return stats.averageStreak;
});

// Stats notifier for actions
final statsNotifierProvider = StateNotifierProvider<StatsNotifier, AsyncValue<void>>((ref) {
  final snapshotRepository = ref.watch(snapshotRepositoryProvider);
  final habitRepository = ref.watch(habitRepositoryProvider);
  return StatsNotifier(snapshotRepository, habitRepository);
});

// ✅ Classe pour regrouper les stats actuelles
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
  
  // ========== SNAPSHOT CREATION ==========
  
  Future<void> createTodaySnapshot() async {
    state = const AsyncValue.loading();
    
    try {
      final habits = _habitRepository.getActiveHabits();
      await _snapshotRepository.createSnapshot(habits: habits);
      state = const AsyncValue.data(null);
      
      print('✅ [StatsNotifier] Today snapshot created');
    } catch (e, stack) {
      print('❌ [StatsNotifier] Error creating snapshot: $e');
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
      
      print('✅ [StatsNotifier] Snapshot created for $date');
    } catch (e, stack) {
      print('❌ [StatsNotifier] Error creating snapshot for $date: $e');
      state = AsyncValue.error(e, stack);
    }
  }
  
  // ========== MAINTENANCE ==========
  
  Future<void> cleanupOldSnapshots({int keepDays = 30}) async {
    try {
      await _snapshotRepository.deleteOldSnapshots(keepDays);
      print('✅ [StatsNotifier] Old snapshots cleaned up');
    } catch (e) {
      print('❌ [StatsNotifier] Error cleaning up old snapshots: $e');
    }
  }
}