// ============================================
// FICHIER 12/30 : lib/core/services/firebase_service.dart
// ============================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Getters
  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  
  // Initialize Firebase Auth with Anonymous
  static Future<User?> initializeAuth() async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      // Sign in anonymously if no user
      final userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
    }
    
    return user;
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