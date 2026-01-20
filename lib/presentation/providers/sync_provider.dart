// ============================================
// FICHIER NETTOYÉ : lib/presentation/providers/sync_provider.dart
// ✅ Uniquement logs d'erreurs critiques
// ============================================
import 'package:discipline/presentation/providers/stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/repositories/firebase_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../core/services/logger_service.dart';
import 'user_provider.dart';
import 'habits_provider.dart' hide userRepositoryProvider;

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) => results.first);
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
});

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    ref.watch(firebaseRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(habitRepositoryProvider),
    ref.watch(snapshotRepositoryProvider),
    ref,
  );
});

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final String? message;
  final DateTime? lastSyncAt;
  
  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.lastSyncAt,
  });
  
  SyncState copyWith({
    SyncStatus? status,
    String? message,
    DateTime? lastSyncAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(
    this._firebaseRepo,
    this._userRepo,
    this._habitRepo,
    this._snapshotRepo,
    this._ref,
  ) : super(const SyncState());
  
  final FirebaseRepository _firebaseRepo;
  final UserRepository _userRepo;
  final HabitRepository _habitRepo;
  final SnapshotRepository _snapshotRepo;
  final Ref _ref;

  Future<void> performFirstSync() async {
    state = state.copyWith(
      status: SyncStatus.syncing, 
      message: 'Première synchronisation...'
    );
    
    try {
      final user = _userRepo.getUser();
      if (user == null) {
        throw Exception('No user found');
      }
      
      if (user.firebaseUid == null) {
        throw Exception('User not connected to Firebase');
      }
      
      final habits = _habitRepo.getAllHabits();
      final snapshots = _snapshotRepo.getAllSnapshots();
      
      await _firebaseRepo.performFullBackup(
        uid: user.firebaseUid!,
        user: user,
        habits: habits,
        snapshots: snapshots,
      );
      
      await _userRepo.markBackedUp();
      
      state = state.copyWith(
        status: SyncStatus.success,
        message: '✅ Première sync réussie ! ${habits.length} habitudes synchronisées',
        lastSyncAt: DateTime.now(),
      );
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
      
    } catch (e, stack) {
      LoggerService.error('First sync failed', tag: 'SYNC', error: e, stackTrace: stack);
      
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Erreur de synchronisation: ${e.toString()}',
      );
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
    }
  }
  
  Future<void> backupToCloud() async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Sauvegarde...');
    
    try {
      final user = _userRepo.getUser();
      if (user == null || user.firebaseUid == null) {
        throw Exception('User not authenticated');
      }
      
      final habits = _habitRepo.getAllHabits();
      final snapshots = _snapshotRepo.getAllSnapshots();
      
      await _firebaseRepo.performFullBackup(
        uid: user.firebaseUid!,
        user: user,
        habits: habits,
        snapshots: snapshots,
      );
      
      await _userRepo.markBackedUp();
      
      state = state.copyWith(
        status: SyncStatus.success,
        message: 'Sauvegarde réussie !',
        lastSyncAt: DateTime.now(),
      );
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
      
    } catch (e, stack) {
      LoggerService.error('Backup failed', tag: 'SYNC', error: e, stackTrace: stack);
      
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Erreur: ${e.toString()}',
      );
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
    }
  }
  
  Future<void> restoreFromCloud() async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Restauration...');
    
    try {
      final user = _userRepo.getUser();
      if (user == null || user.firebaseUid == null) {
        throw Exception('User not authenticated');
      }
      
      final data = await _firebaseRepo.performFullRestore(user.firebaseUid!);
      
      await _habitRepo.clearAll();
      await _snapshotRepo.clearAllSnapshots();
      
      if (data['user'] != null) {
        await _userRepo.saveUser(data['user']);
      }
      
      final habits = data['habits'] as List;
      for (final habit in habits) {
        await _habitRepo.saveHabit(habit);
      }
      
      final snapshots = data['snapshots'] as List;
      for (final snapshot in snapshots) {
        await _snapshotRepo.saveSnapshot(snapshot);
      }
      
      _ref.invalidate(userProvider);
      _ref.invalidate(habitsProvider);
      
      state = state.copyWith(
        status: SyncStatus.success,
        message: 'Restauration réussie !',
        lastSyncAt: DateTime.now(),
      );
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
      
    } catch (e, stack) {
      LoggerService.error('Restore failed', tag: 'SYNC', error: e, stackTrace: stack);
      
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Erreur: ${e.toString()}',
      );
      
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
    }
  }
  
  Future<void> autoSync() async {
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) return;
    
    final user = _userRepo.getUser();
    if (user == null || user.firebaseUid == null) return;
    
    try {
      final habits = _habitRepo.getAllHabits();
      await _firebaseRepo.saveMultipleHabits(user.firebaseUid!, habits);
      await _userRepo.markBackedUp();
    } catch (e) {
      // Silent fail for auto-sync
    }
  }
}