import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter/foundation.dart';

class EmailAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Development mode flag
  static bool get _isDevelopmentMode => kDebugMode;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Development mode: Simple validation
      if (_isDevelopmentMode) {
        print('Development mode: Attempting sign up for $email');

        // Basic validation
        if (email.isEmpty || !email.contains('@')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email address.',
          );
        }

        if (password.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'Password must be at least 6 characters.',
          );
        }
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update settings with user email
      await updateSettings(
        "currentUserEmail",
        result.user?.email ?? "",
        updateGlobalState: true,
      );

      // Mark as signed in
      await updateSettings(
        "hasSignedIn",
        true,
        updateGlobalState: true,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.code} - ${e.message}');

      // Handle specific errors with user-friendly messages
      if (e.code == 'internal-error' &&
          e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
        throw FirebaseAuthException(
          code: 'service-unavailable',
          message:
              'Authentication service is temporarily unavailable. Please try again later or contact support.',
        );
      } else if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'An account already exists with this email address.',
        );
      } else if (e.code == 'weak-password') {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use at least 6 characters.',
        );
      } else if (e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      }

      throw e;
    } catch (e) {
      print('Sign up error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Development mode: Simple validation
      if (_isDevelopmentMode) {
        print('Development mode: Attempting sign in for $email');

        // Basic validation
        if (email.isEmpty || !email.contains('@')) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Please enter a valid email address.',
          );
        }

        if (password.isEmpty) {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message: 'Please enter your password.',
          );
        }
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update settings with user email
      await updateSettings(
        "currentUserEmail",
        result.user?.email ?? "",
        updateGlobalState: true,
      );

      // Mark as signed in
      await updateSettings(
        "hasSignedIn",
        true,
        updateGlobalState: true,
      );

      return result;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.code} - ${e.message}');

      // Handle specific errors with user-friendly messages
      if (e.code == 'internal-error' &&
          e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
        throw FirebaseAuthException(
          code: 'service-unavailable',
          message:
              'Authentication service is temporarily unavailable. Please try again later or contact support.',
        );
      } else if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account found with this email address.',
        );
      } else if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Incorrect password. Please try again.',
        );
      } else if (e.code == 'invalid-email') {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      } else if (e.code == 'user-disabled') {
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'This account has been disabled.',
        );
      }

      throw e;
    } catch (e) {
      print('Sign in error: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await updateSettings(
        "currentUserEmail",
        "",
        updateGlobalState: true,
      );
    } catch (e) {
      print('Sign out error: $e');
      throw e;
    }
  }

  // Reset password
  static Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Reset password error: ${e.message}');
      throw e;
    } catch (e) {
      print('Reset password error: $e');
      throw e;
    }
  }

  // Get Firebase Firestore instance for authenticated user
  static Future<FirebaseFirestore?> getFirestoreInstance() async {
    try {
      if (_auth.currentUser != null) {
        return _firestore;
      } else {
        print('No authenticated user');
        return null;
      }
    } catch (e) {
      print('Firestore instance error: $e');
      return null;
    }
  }

  // Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Check if the current Firebase user signed in with email/password.
  static bool isEmailPasswordUser() {
    return _auth.currentUser?.providerData
            .any((provider) => provider.providerId == 'password') ??
        false;
  }

  // Get user email
  static String? getUserEmail() {
    return _auth.currentUser?.email;
  }
}
