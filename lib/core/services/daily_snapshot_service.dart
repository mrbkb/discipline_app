// ============================================
// FICHIER NETTOYÉ : lib/core/services/daily_snapshot_service.dart
// ✅ Uniquement logs d'erreurs critiques
// ============================================
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../utils/date_helper.dart';
import 'logger_service.dart';

class DailySnapshotService {
  static const String _lastSnapshotKey = 'last_snapshot_date';
  
  static final HabitRepository _habitRepo = HabitRepository();
  static final SnapshotRepository _snapshotRepo = SnapshotRepository();
  
  static Future<void> checkAndCreateDailySnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateHelper.getTodayString();
      final lastSnapshot = prefs.getString(_lastSnapshotKey);
      
      if (lastSnapshot == today) return;
      
      final habits = _habitRepo.getActiveHabits();
      if (habits.isEmpty) return;
      
      await _snapshotRepo.createSnapshot(habits: habits);
      await prefs.setString(_lastSnapshotKey, today);
      await _cleanupOldSnapshots();
      
    } catch (e, stack) {
      LoggerService.error('Snapshot creation failed', tag: 'SNAPSHOT', error: e, stackTrace: stack);
    }
  }
  
  static Future<void> _cleanupOldSnapshots() async {
    try {
      await _snapshotRepo.deleteOldSnapshots(30);
    } catch (e) {
      // Ignore cleanup errors
    }
  }
  
  static Future<void> forceCreateSnapshot() async {
    try {
      final habits = _habitRepo.getActiveHabits();
      if (habits.isEmpty) return;
      
      await _snapshotRepo.createSnapshot(habits: habits);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSnapshotKey, DateHelper.getTodayString());
      
    } catch (e, stack) {
      LoggerService.error('Force snapshot failed', tag: 'SNAPSHOT', error: e, stackTrace: stack);
    }
  }
  
  static Future<void> resetLastSnapshotDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSnapshotKey);
  }
}