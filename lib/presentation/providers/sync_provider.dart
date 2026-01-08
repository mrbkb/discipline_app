
// ============================================
// FICHIER 25/30 : lib/presentation/providers/sync_provider.dart
// ============================================
import 'package:discipline/presentation/providers/stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/repositories/firebase_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/snapshot_repository.dart';
import 'user_provider.dart';
import 'habits_provider.dart' hide userRepositoryProvider;

// Firebase repository provider
final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});

// Connectivity provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) => results.first);
});

// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Sync notifier
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

  
/// ✅ NOUVEAU: Première synchronisation (migration local → cloud)
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
    
    // Vérifier qu'on a bien un firebaseUid maintenant
    if (user.firebaseUid == null) {
      throw Exception('User not connected to Firebase');
    }
    
    print('🔄 [Sync] Starting first sync for: ${user.firebaseUid}');
    
    // Récupérer toutes les données locales
    final habits = _habitRepo.getAllHabits();
    final snapshots = _snapshotRepo.getAllSnapshots();
    
    print('📦 [Sync] Data to sync:');
    print('   - ${habits.length} habits');
    print('   - ${snapshots.length} snapshots');
    
    // Envoyer tout sur Firebase
    await _firebaseRepo.performFullBackup(
      uid: user.firebaseUid!,
      user: user,
      habits: habits,
      snapshots: snapshots,
    );
    
    // Marquer comme sauvegardé
    await _userRepo.markBackedUp();
    
    state = state.copyWith(
      status: SyncStatus.success,
      message: '✅ Première sync réussie ! ${habits.length} habitudes synchronisées',
      lastSyncAt: DateTime.now(),
    );
    
    print('✅ [Sync] First sync completed successfully');
    
    // Reset to idle after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle, message: null);
      }
    });
    
  } catch (e) {
    print('❌ [Sync] First sync failed: $e');
    
    state = state.copyWith(
      status: SyncStatus.error,
      message: 'Erreur de synchronisation: ${e.toString()}',
    );
    
    // Reset to idle after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle, message: null);
      }
    });
  }
}
  
  // ========== BACKUP ==========
  
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
      
      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
      
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Erreur: ${e.toString()}',
      );
      
      // Reset to idle after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
    }
  }
  
  // ========== RESTORE ==========
  
  Future<void> restoreFromCloud() async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Restauration...');
    
    try {
      final user = _userRepo.getUser();
      if (user == null || user.firebaseUid == null) {
        throw Exception('User not authenticated');
      }
      
      final data = await _firebaseRepo.performFullRestore(user.firebaseUid!);
      
      // Clear local data
      await _habitRepo.clearAll();
      await _snapshotRepo.clearAllSnapshots();
      
      // Restore user



      if (data['user'] != null) {
        await _userRepo.saveUser(data['user']);
      }
      
      // Restore habits
      final habits = data['habits'] as List;
      for (final habit in habits) {
        await _habitRepo.saveHabit(habit);
      }
      
      // Restore snapshots
      final snapshots = data['snapshots'] as List;
      for (final snapshot in snapshots) {
        await _snapshotRepo.saveSnapshot(snapshot);
      }
      
      // Refresh providers
      _ref.invalidate(userProvider);
      _ref.invalidate(habitsProvider);
      
      state = state.copyWith(
        status: SyncStatus.success,
        message: 'Restauration réussie !',
        lastSyncAt: DateTime.now(),
      );
      
      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
      
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Erreur: ${e.toString()}',
      );
      
      // Reset to idle after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          state = state.copyWith(status: SyncStatus.idle, message: null);
        }
      });
    }
  }
  
  // ========== AUTO SYNC ==========
  
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
      print('Auto sync error: $e');
    }
  }
}
