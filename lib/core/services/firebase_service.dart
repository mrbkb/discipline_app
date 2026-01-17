// ============================================
// FICHIER PRODUCTION : lib/core/services/firebase_service.dart
// ✅ Tous les print() remplacés par LoggerService
// ============================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logger_service.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Getters
  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  
  /// Check internet connection
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.first != ConnectivityResult.none;
  }
  
  /// Initialize Firebase Auth with offline support
  static Future<User?> initializeAuth() async {
    try {
      User? user = _auth.currentUser;
      
      if (user != null) {
        LoggerService.info('User already signed in', tag: 'FIREBASE', data: {
          'uid': user.uid,
        });
        return user;
      }
      
      final online = await isOnline();
      
      if (!online) {
        LoggerService.warning('No internet - skipping auth (local mode)', tag: 'FIREBASE');
        return null;
      }
      
      LoggerService.debug('Online - signing in anonymously', tag: 'FIREBASE');
      final userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
      
      LoggerService.info('Anonymous sign in successful', tag: 'FIREBASE', data: {
        'uid': user?.uid,
      });
      
      return user;
      
    } catch (e, stack) {
      LoggerService.error('Auth initialization failed', tag: 'FIREBASE', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Try to connect to Firebase if offline
  static Future<User?> tryConnectIfOffline() async {
    try {
      if (_auth.currentUser != null) {
        return _auth.currentUser;
      }
      
      final online = await isOnline();
      if (!online) {
        LoggerService.warning('Still offline', tag: 'FIREBASE');
        return null;
      }
      
      LoggerService.debug('Attempting delayed connection', tag: 'FIREBASE');
      final userCredential = await _auth.signInAnonymously();
      
      LoggerService.info('Delayed connection successful', tag: 'FIREBASE', data: {
        'uid': userCredential.user?.uid,
      });
      
      return userCredential.user;
      
    } catch (e, stack) {
      LoggerService.error('Delayed connection failed', tag: 'FIREBASE', error: e, stackTrace: stack);
      return null;
    }
  }
  
  /// Upgrade Anonymous to Email/Password
  static Future<User?> upgradeToEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      final userCredential = await user.linkWithCredential(credential);
      
      LoggerService.info('Account upgraded to email', tag: 'FIREBASE', data: {
        'email': email,
      });
      
      return userCredential.user;
    } catch (e, stack) {
      LoggerService.error('Account upgrade failed', tag: 'FIREBASE', error: e, stackTrace: stack);
      rethrow;
    }
  }
  
  /// Sign Out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      LoggerService.info('User signed out', tag: 'FIREBASE');
    } catch (e, stack) {
      LoggerService.error('Sign out failed', tag: 'FIREBASE', error: e, stackTrace: stack);
    }
  }
  
  /// Get User Reference
  static DocumentReference getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }
  
  /// Get Habits Collection Reference
  static CollectionReference getHabitsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('habits');
  }
  
  /// Check if user is anonymous
  static bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? true;
  }
  
  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}