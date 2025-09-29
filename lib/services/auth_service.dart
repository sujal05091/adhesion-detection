import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    print('AuthService: authStateChanges stream accessed');
    return _auth.authStateChanges();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Step 2: Get authentication details from Google
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Step 3: Create Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in to Firebase with Google credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      // Step 5: Get the signed-in user
      final User? user = userCredential.user;

      if (user != null) {
        // Step 6: Save/update user data in Firestore
        await _saveUserToFirestore(user);
      }

      return user;
    } catch (e) {
      // Handle different types of errors
      if (e is FirebaseAuthException) {
        throw _handleFirebaseAuthError(e);
      } else if (e is FirebaseException) {
        throw _handleFirebaseError(e);
      } else {
        throw AuthException('Google Sign-In failed: $e');
      }
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'provider': 'google.com',
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use set with merge to update existing or create new document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
    } catch (e) {
      // Log the error but don't prevent login
      print('Error saving user to Firestore: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw AuthException('Failed to get user profile: $e');
    }
  }

  // Error handling methods
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method.';
      case 'invalid-credential':
        return 'The credential is malformed or has expired.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  String _handleFirebaseError(FirebaseException e) {
    return 'Firebase error: ${e.message}';
  }
}

// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}