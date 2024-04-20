import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student/student_home.dart';
import 'admin/admin_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // Sign in the user with email and password
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Authentication successful
      final String userEmail = userCredential.user?.email ?? '';

      if (userEmail.endsWith('@1utar.my')) {
        // Student user
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const StudentHomePage()),
        );
      } else if (userEmail.endsWith('@utar.edu.my')) {
        // Admin user
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
        );
      } else {
        // Unknown user type
        // Handle this case based on your application's requirements
      }

      // Check if the user document already exists in Firestore
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      final userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        // Create a new user document in Firestore if it doesn't exist
        await userDocRef.set({
          'email': email,
          // Add more fields here if needed
        });
      }
    } catch (e) {
      // Handle login errors
      if (kDebugMode) {
        print('Failed to login: $e');
      }
      // Show error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/logo.jpg', // Replace with your logo image path
              height: 150, // Adjust the height as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
