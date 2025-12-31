

// ============================================
// FICHIER 9/30 : lib/core/services/storage_service.dart
// ============================================
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/daily_snapshot_model.dart';

class StorageService {
  static const String habitsBox = 'habits';
  static const String userBox = 'user';
  static const String snapshotsBox = 'snapshots';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(DailySnapshotModelAdapter());
    
    // Open boxes
    await Hive.openBox<HabitModel>(habitsBox);
    await Hive.openBox<UserModel>(userBox);
    await Hive.openBox<DailySnapshotModel>(snapshotsBox);
  }
  
  static Box<HabitModel> get habits => Hive.box<HabitModel>(habitsBox);
  static Box<UserModel> get user => Hive.box<UserModel>(userBox);
  static Box<DailySnapshotModel> get snapshots => Hive.box<DailySnapshotModel>(snapshotsBox);
  
  static Future<void> compactIfNeeded() async {
    if (habits.length > 100) {
      await habits.compact();
    }
    if (snapshots.length > 30) {
      await snapshots.compact();
    }
  }
  
  static Future<void> clearAll() async {
    await habits.clear();
    await user.clear();
    await snapshots.clear();
  }
}