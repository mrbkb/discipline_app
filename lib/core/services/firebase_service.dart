// ============================================
// FICHIER MODIFIÉ : lib/core/services/firebase_service.dart
// ============================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Getters
  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  
  // ✅ Vérifier la connexion Internet
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.first != ConnectivityResult.none;
  }
  
  /// ✅ NOUVEAU: Initialize Firebase Auth SEULEMENT si en ligne
  /// Sinon, skip et l'app fonctionne en mode local
  static Future<User?> initializeAuth() async {
    try {
      // Vérifier si Firebase Auth est déjà initialisé
      User? user = _auth.currentUser;
      
      // Si déjà connecté, retourner l'user
      if (user != null) {
        print('✅ [Firebase] User already signed in: ${user.uid}');
        return user;
      }
      
      // ✅ Vérifier la connexion Internet
      final online = await isOnline();
      
      if (!online) {
        print('⚠️ [Firebase] No internet - skipping auth (local mode)');
        return null; // Mode local, pas de Firebase pour le moment
      }
      
      // ✅ Si en ligne, sign in anonymously
      print('🌐 [Firebase] Online - signing in anonymously');
      final userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
      print('✅ [Firebase] Anonymous sign in successful: ${user?.uid}');
      
      return user;
      
    } catch (e) {
      print('❌ [Firebase] Error during auth initialization: $e');
      // En cas d'erreur, retourner null pour continuer en mode local
      return null;
    }
  }
  
  /// ✅ NOUVEAU: Tenter de se connecter à Firebase si pas encore fait
  static Future<User?> tryConnectIfOffline() async {
    try {
      // Si déjà connecté, rien à faire
      if (_auth.currentUser != null) {
        return _auth.currentUser;
      }
      
      // Vérifier la connexion
      final online = await isOnline();
      if (!online) {
        print('⚠️ [Firebase] Still offline');
        return null;
      }
      
      // Tenter de se connecter
      print('🌐 [Firebase] Attempting delayed connection...');
      final userCredential = await _auth.signInAnonymously();
      print('✅ [Firebase] Delayed connection successful: ${userCredential.user?.uid}');
      
      return userCredential.user;
      
    } catch (e) {
      print('❌ [Firebase] Delayed connection failed: $e');
      return null;
    }
  }
  
  // Upgrade Anonymous to Email/Password
  static Future<User?> upgradeToEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');
      
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      final userCredential = await user.linkWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Get User Reference
  static DocumentReference getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }
  
  // Get Habits Collection Reference
  static CollectionReference getHabitsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('habits');
  }
  
  // Check if user is anonymous
  static bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? true;
  }
  
  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}