import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class UserController {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  /// **Forces logout before sign-in to ensure account selection**
  Future<void> signOutGoogle() async {
    await googleSignIn.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Force sign out before login
      await signOutGoogle();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }
}
