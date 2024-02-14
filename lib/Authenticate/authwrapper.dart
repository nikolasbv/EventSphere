import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eventsphere/landing_page.dart';
import 'package:eventsphere/Authenticate/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            checkAuthenticationAndNavigate(context);
            return const LandingPage();
          }
          return const RegisterPage();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<void> checkAuthenticationAndNavigate(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('User is null');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists) {
          print('User exists in Firestore');
        } else {
          print('User does not exist in Firestore');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RegisterPage()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking authentication: $e');
    }
  }
}
