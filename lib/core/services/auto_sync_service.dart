// ============================================
// FICHIER NOUVEAU : lib/core/services/auto_sync_service.dart
// ✅ Synchronisation automatique en arrière-plan
// ============================================
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/snapshot_repository.dart';
import 'firebase_service.dart';
import 'logger_service.dart';

class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();
  
  final _firebaseRepo = FirebaseRepository();
  final _habitRepo = HabitRepository();
  final _userRepo = UserRepository();
  final _snapshotRepo = SnapshotRepository();
  
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  
  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  
  // Configuration
  static const Duration _syncInterval = Duration(minutes: 15); // Sync toutes les 15min
  static const Duration _retryDelay = Duration(seconds: 30); // Retry après 30s si échec
  
  /// Initialiser le service de sync automatique
  Future<void> initialize() async {
    LoggerService.info('Initializing auto-sync service', tag: 'AUTO_SYNC');
    
    // 1. Écouter les changements de connectivité
    _listenToConnectivity();
    
    // 2. Lancer le timer de sync périodique
    _startPeriodicSync();
    
    // 3. Sync initial si en ligne
    await _trySync();
  }
  
  /// Écouter les changements de connectivité
  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.first;
      final isOnline = result != ConnectivityResult.none;
      
      LoggerService.info('Connectivity changed', tag: 'AUTO_SYNC', data: {
        'isOnline': isOnline,
        'type': result.name,
      });
      
      if (isOnline) {
        // Connexion rétablie → sync immédiat
        _trySync();
      }
    });
  }
  
  /// Démarrer le sync périodique
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _trySync();
    });
    
    LoggerService.debug('Periodic sync started', tag: 'AUTO_SYNC', data: {
      'interval_minutes': _syncInterval.inMinutes,
    });
  }
  
  /// Tenter une synchronisation
  Future<void> _trySync() async {
    // Éviter les syncs simultanés
    if (_isSyncing) {
      LoggerService.debug('Sync already in progress, skipping', tag: 'AUTO_SYNC');
      return;
    }
    
    // Vérifier la connectivité
    final isOnline = await FirebaseService.isOnline();
    if (!isOnline) {
      LoggerService.debug('Offline, skipping sync', tag: 'AUTO_SYNC');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // 1. S'assurer que l'auth est configurée
      await _ensureAuth();
      
      // 2. Synchroniser les données
      await _performSync();
      
      _lastSyncAt = DateTime.now();
      
      LoggerService.info('Auto-sync completed', tag: 'AUTO_SYNC', data: {
        'timestamp': _lastSyncAt?.toIso8601String(),
      });
      
    } catch (e, stack) {
      LoggerService.error('Auto-sync failed', tag: 'AUTO_SYNC', error: e, stackTrace: stack);
      
      // Retry après un délai
      Timer(_retryDelay, () => _trySync());
      
    } finally {
      _isSyncing = false;
    }
  }
  
  /// S'assurer que Firebase Auth est configurée
  Future<void> _ensureAuth() async {
    final currentUser = FirebaseService.auth.currentUser;
    
    if (currentUser != null) {
      LoggerService.debug('User already authenticated', tag: 'AUTO_SYNC', data: {
        'uid': currentUser.uid,
      });
      return;
    }
    
    // Pas d'utilisateur → se connecter anonymement
    LoggerService.info('No user found, signing in anonymously', tag: 'AUTO_SYNC');
    
    final user = await FirebaseService.tryConnectIfOffline();
    
    if (user != null) {
      // Migrer l'utilisateur local vers Firebase
      final localUser = _userRepo.getUser();
      if (localUser != null && localUser.firebaseUid == null) {
        await _userRepo.migrateToFirebase(user.uid);
        LoggerService.info('Local user migrated to Firebase', tag: 'AUTO_SYNC');
      }
    }
  }
  
  /// Effectuer la synchronisation
  Future<void> _performSync() async {
    final user = _userRepo.getUser();
    
    if (user == null) {
      LoggerService.warning('No user to sync', tag: 'AUTO_SYNC');
      return;
    }
    
    final uid = user.firebaseUid;
    if (uid == null) {
      LoggerService.warning('User has no Firebase UID', tag: 'AUTO_SYNC');
      return;
    }
    
    LoggerService.debug('Starting sync', tag: 'AUTO_SYNC', data: {'uid': uid});
    
    // Récupérer les données locales
    final habits = _habitRepo.getAllHabits();
    final snapshots = _snapshotRepo.getAllSnapshots();
    
    // Envoyer vers Firebase
    await _firebaseRepo.performFullBackup(
      uid: uid,
      user: user,
      habits: habits,
      snapshots: snapshots,
    );
    
    // Marquer comme sauvegardé
    await _userRepo.markBackedUp();
    
    LoggerService.info('Sync completed', tag: 'AUTO_SYNC', data: {
      'habits': habits.length,
      'snapshots': snapshots.length,
    });
  }
  
  /// Forcer une sync immédiate
  Future<void> forceSyncNow() async {
    LoggerService.info('Force sync requested', tag: 'AUTO_SYNC');
    await _trySync();
  }
  
  /// Obtenir le statut de sync
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'lastSyncAt': _lastSyncAt?.toIso8601String(),
      'minutesSinceLastSync': _lastSyncAt != null
          ? DateTime.now().difference(_lastSyncAt!).inMinutes
          : null,
    };
  }
  
  /// Arrêter le service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    LoggerService.info('Auto-sync service disposed', tag: 'AUTO_SYNC');
  }
}

