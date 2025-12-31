
// ============================================
// FICHIER 20/30 : lib/data/repositories/firebase_repository.dart
// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../models/habit_model.dart';
import '../models/user_model.dart';
import '../models/daily_snapshot_model.dart';

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  
  // ========== USER OPERATIONS ==========
  
  /// Save user to Firestore
  Future<void> saveUser(UserModel user) async {
    if (user.firebaseUid == null) return;
    
    final docRef = FirebaseService.getUserDoc(user.firebaseUid!);
    await docRef.set(user.toFirestore(), SetOptions(merge: true));
  }
  
  /// Get user from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final docRef = FirebaseService.getUserDoc(uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      return null;
    }
  }
  
  // ========== HABIT OPERATIONS ==========
  
  /// Save habit to Firestore
  Future<void> saveHabit(String uid, HabitModel habit) async {
    try {
      final habitRef = FirebaseService.getHabitsCollection(uid).doc(habit.id);
      await habitRef.set(habit.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving habit to Firestore: $e');
      rethrow;
    }
  }
  
  /// Save multiple habits
  Future<void> saveMultipleHabits(String uid, List<HabitModel> habits) async {
    final batch = _firestore.batch();
    
    for (final habit in habits) {
      final habitRef = FirebaseService.getHabitsCollection(uid).doc(habit.id);
      batch.set(habitRef, habit.toFirestore(), SetOptions(merge: true));
    }
    
    await batch.commit();
  }
  
  /// Get all habits from Firestore
  Future<List<HabitModel>> getHabits(String uid) async {
    try {
      final snapshot = await FirebaseService.getHabitsCollection(uid).get();
      
      return snapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting habits from Firestore: $e');
      return [];
    }
  }
  
  /// Delete habit from Firestore
  Future<void> deleteHabit(String uid, String habitId) async {
    try {
      await FirebaseService.getHabitsCollection(uid).doc(habitId).delete();
    } catch (e) {
      print('Error deleting habit from Firestore: $e');
      rethrow;
    }
  }
  
  // ========== SNAPSHOT OPERATIONS ==========
  
  /// Save snapshot to Firestore
  Future<void> saveSnapshot(String uid, DailySnapshotModel snapshot) async {
    try {
      final snapshotRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('snapshots')
          .doc(snapshot.date);
      
      await snapshotRef.set(snapshot.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving snapshot to Firestore: $e');
    }
  }
  
  /// Get snapshots from Firestore
  Future<List<DailySnapshotModel>> getSnapshots(String uid, {int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('snapshots')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => DailySnapshotModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting snapshots from Firestore: $e');
      return [];
    }
  }
  
  // ========== BACKUP & RESTORE ==========
  
  /// Full backup (user + habits + snapshots)
  Future<void> performFullBackup({
    required String uid,
    required UserModel user,
    required List<HabitModel> habits,
    required List<DailySnapshotModel> snapshots,
  }) async {
    try {
      // Save user
      await saveUser(user);
      
      // Save habits in batch
      await saveMultipleHabits(uid, habits);
      
      // Save snapshots
      final batch = _firestore.batch();
      for (final snapshot in snapshots) {
        final snapshotRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('snapshots')
            .doc(snapshot.date);
        batch.set(snapshotRef, snapshot.toFirestore());
      }
      await batch.commit();
      
    } catch (e) {
      print('Error performing full backup: $e');
      rethrow;
    }
  }
  
  /// Full restore (get all data from Firestore)
  Future<Map<String, dynamic>> performFullRestore(String uid) async {
    try {
      final user = await getUser(uid);
      final habits = await getHabits(uid);
      final snapshots = await getSnapshots(uid);
      
      return {
        'user': user,
        'habits': habits,
        'snapshots': snapshots,
      };
    } catch (e) {
      print('Error performing full restore: $e');
      rethrow;
    }
  }
}