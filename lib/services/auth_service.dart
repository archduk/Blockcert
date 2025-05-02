import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and save to Firestore
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String dob,
    required String gender,
    required String country,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save additional data to Firestore
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'fullName': fullName,
          'phone': phone,
          'dob': dob,
          'gender': gender,
          'country': country,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': userCredential.user!.uid,
        })
            .then((_) => debugPrint('User data saved to Firestore'))
            .catchError((e) => debugPrint('Firestore error: $e'));
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Sign in with email
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify Firestore data exists
      if (userCredential.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!doc.exists) {
          debugPrint('No user data found in Firestore');
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('Reset Error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}