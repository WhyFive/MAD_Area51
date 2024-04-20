import 'dart:async';
import 'package:event_hub/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        appId: '1:427895010373:android:e313df4f53b7ab2bd85f2c',
        apiKey: "AIzaSyCfcZ-aUfrpWcfCcXUxmpC7LNfFwTv1T-s",
        projectId: "eventhub-31771",
        storageBucket: "eventhub-31771.appspot.com",
        messagingSenderId: "427895010373",));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => const LoginPage(),
        // Define other routes if needed
      },
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Add listener to update the state when animation value changes
    _animation.addListener(() {
      setState(() {});
    });

    // Start the animation
    _controller.forward();

    // Navigate to the login page after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scale: 0.5 + (_animation.value * 0.5), // Scale from smaller to bigger
          child: Opacity(
            opacity: _animation.value, // Change opacity from transparent to solid
            child: Image.asset(
              'assets/logo.jpg', // Path to your logo image
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
            ),
          ),
        ),
      ),
    );
  }
}