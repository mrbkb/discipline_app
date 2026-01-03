// ============================================
// NOUVEAU FICHIER : lib/core/services/daily_snapshot_service.dart
// ============================================
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../utils/date_helper.dart';

class DailySnapshotService {
  static const String _lastSnapshotKey = 'last_snapshot_date';
  
  static final HabitRepository _habitRepo = HabitRepository();
  static final SnapshotRepository _snapshotRepo = SnapshotRepository();
  
  /// ✅ Vérifie et crée un snapshot quotidien si nécessaire
  static Future<void> checkAndCreateDailySnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateHelper.getTodayString();
      final lastSnapshot = prefs.getString(_lastSnapshotKey);
      
      print('📸 [DailySnapshot] Today: $today, Last: $lastSnapshot');
      
      // Si on a déjà créé un snapshot aujourd'hui, ne rien faire
      if (lastSnapshot == today) {
        print('✅ [DailySnapshot] Already created for today');
        return;
      }
      
      // Récupérer les habits actifs
      final habits = _habitRepo.getActiveHabits();
      
      if (habits.isEmpty) {
        print('⚠️ [DailySnapshot] No active habits, skipping snapshot');
        return;
      }
      
      // Créer le snapshot du jour
      print('📸 [DailySnapshot] Creating snapshot with ${habits.length} habits');
      await _snapshotRepo.createSnapshot(habits: habits);
      
      // Sauvegarder la date du snapshot
      await prefs.setString(_lastSnapshotKey, today);
      
      print('✅ [DailySnapshot] Snapshot created successfully');
      
      // ✅ BONUS: Nettoyer les anciens snapshots (garder 30 jours)
      await _cleanupOldSnapshots();
      
    } catch (e) {
      print('❌ [DailySnapshot] Error: $e');
    }
  }
  
  /// ✅ Nettoie les snapshots de plus de 30 jours
  static Future<void> _cleanupOldSnapshots() async {
    try {
      await _snapshotRepo.deleteOldSnapshots(30);
      print('🧹 [DailySnapshot] Old snapshots cleaned up');
    } catch (e) {
      print('❌ [DailySnapshot] Cleanup error: $e');
    }
  }
  
  /// ✅ Force la création d'un snapshot (pour debug ou actions manuelles)
  static Future<void> forceCreateSnapshot() async {
    try {
      final habits = _habitRepo.getActiveHabits();
      
      if (habits.isEmpty) {
        print('⚠️ [DailySnapshot] No habits to snapshot');
        return;
      }
      
      await _snapshotRepo.createSnapshot(habits: habits);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSnapshotKey, DateHelper.getTodayString());
      
      print('✅ [DailySnapshot] Forced snapshot created');
    } catch (e) {
      print('❌ [DailySnapshot] Force snapshot error: $e');
    }
  }
  
  /// ✅ Réinitialise la date du dernier snapshot (pour debug)
  static Future<void> resetLastSnapshotDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSnapshotKey);
    print('🔄 [DailySnapshot] Last snapshot date reset');
  }
}