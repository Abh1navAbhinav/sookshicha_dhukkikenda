import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:sookshicha_dhukkikenda/core/error/exceptions.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';

/// Abstract class for Firebase Auth operations
abstract class FirebaseAuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  Future<void> updateDisplayName(String displayName);
  Future<void> updatePhotoUrl(String photoUrl);
  Future<UserCredential> signInWithCredential(AuthCredential credential);
  Future<void> deleteAccount();
}

/// Implementation of FirebaseAuthService
@LazySingleton(as: FirebaseAuthService)
class FirebaseAuthServiceImpl implements FirebaseAuthService {
  FirebaseAuthServiceImpl(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign in failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Registration failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign out failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Password reset failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Email verification failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      AppLogger.e('User reload failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _firebaseAuth.currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Update display name failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Update photo URL failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign in with credential failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Delete account failed', e);
      throw AuthException(
        message: _getFirebaseAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  /// Map Firebase error codes to user-friendly messages
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please log in again to complete this action.';
      default:
        return 'An authentication error occurred.';
    }
  }
}
