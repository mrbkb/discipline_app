// ============================================
// FICHIER 4/4 : lib/data/repositories/firebase_repository.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/logger_service.dart';
import '../models/habit_model.dart';
import '../models/user_model.dart';
import '../models/daily_snapshot_model.dart';

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  
  // ========== USER OPERATIONS ==========
  
  Future<void> saveUser(UserModel user) async {
    if (user.firebaseUid == null) return;
    
    try {
      final docRef = FirebaseService.getUserDoc(user.firebaseUid!);
      await docRef.set(user.toFirestore(), SetOptions(merge: true));
      
      LoggerService.info('User saved to Firestore', tag: 'FIREBASE_REPO', data: {
        'uid': user.firebaseUid,
      });
    } catch (e, stack) {
      LoggerService.error('Failed to save user', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<UserModel?> getUser(String uid) async {
    try {
      final docRef = FirebaseService.getUserDoc(uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e, stack) {
      LoggerService.error('Failed to get user from Firestore', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      return null;
    }
  }
  
  // ========== HABIT OPERATIONS ==========
  
  Future<void> saveHabit(String uid, HabitModel habit) async {
    try {
      final habitRef = FirebaseService.getHabitsCollection(uid).doc(habit.id);
      await habitRef.set(habit.toFirestore(), SetOptions(merge: true));
      
      LoggerService.debug('Habit saved to Firestore', tag: 'FIREBASE_REPO', data: {
        'id': habit.id,
      });
    } catch (e, stack) {
      LoggerService.error('Failed to save habit', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<void> saveMultipleHabits(String uid, List<HabitModel> habits) async {
    try {
      final batch = _firestore.batch();
      
      for (final habit in habits) {
        final habitRef = FirebaseService.getHabitsCollection(uid).doc(habit.id);
        batch.set(habitRef, habit.toFirestore(), SetOptions(merge: true));
      }
      
      await batch.commit();
      
      LoggerService.info('Multiple habits saved to Firestore', tag: 'FIREBASE_REPO', data: {
        'count': habits.length,
      });
    } catch (e, stack) {
      LoggerService.error('Failed to save multiple habits', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<List<HabitModel>> getHabits(String uid) async {
    try {
      final snapshot = await FirebaseService.getHabitsCollection(uid).get();
      
      return snapshot.docs
          .map((doc) => HabitModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      LoggerService.error('Failed to get habits from Firestore', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      return [];
    }
  }
  
  Future<void> deleteHabit(String uid, String habitId) async {
    try {
      await FirebaseService.getHabitsCollection(uid).doc(habitId).delete();
      
      LoggerService.info('Habit deleted from Firestore', tag: 'FIREBASE_REPO', data: {
        'id': habitId,
      });
    } catch (e, stack) {
      LoggerService.error('Failed to delete habit', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  // ========== SNAPSHOT OPERATIONS ==========
  
  Future<void> saveSnapshot(String uid, DailySnapshotModel snapshot) async {
    try {
      final snapshotRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('snapshots')
          .doc(snapshot.date);
      
      await snapshotRef.set(snapshot.toFirestore(), SetOptions(merge: true));
      
      LoggerService.debug('Snapshot saved to Firestore', tag: 'FIREBASE_REPO', data: {
        'date': snapshot.date,
      });
    } catch (e, stack) {
      LoggerService.error('Failed to save snapshot', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
    }
  }
  
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
    } catch (e, stack) {
      LoggerService.error('Failed to get snapshots from Firestore', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      return [];
    }
  }
  
  // ========== BACKUP & RESTORE ==========
  
  Future<void> performFullBackup({
    required String uid,
    required UserModel user,
    required List<HabitModel> habits,
    required List<DailySnapshotModel> snapshots,
  }) async {
    try {
      LoggerService.info('Starting full backup', tag: 'FIREBASE_REPO', data: {
        'habits': habits.length,
        'snapshots': snapshots.length,
      });
      
      await saveUser(user);
      await saveMultipleHabits(uid, habits);
      
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
      
      LoggerService.info('Full backup completed', tag: 'FIREBASE_REPO');
      
    } catch (e, stack) {
      LoggerService.error('Full backup failed', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> performFullRestore(String uid) async {
    try {
      LoggerService.info('Starting full restore', tag: 'FIREBASE_REPO');
      
      final user = await getUser(uid);
      final habits = await getHabits(uid);
      final snapshots = await getSnapshots(uid);
      
      LoggerService.info('Full restore completed', tag: 'FIREBASE_REPO', data: {
        'habits': habits.length,
        'snapshots': snapshots.length,
      });
      
      return {
        'user': user,
        'habits': habits,
        'snapshots': snapshots,
      };
    } catch (e, stack) {
      LoggerService.error('Full restore failed', tag: 'FIREBASE_REPO', error: e, stackTrace: stack);
      rethrow;
    }
  }
}