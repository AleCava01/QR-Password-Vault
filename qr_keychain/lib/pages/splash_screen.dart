import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_keychain/pages/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a delay for loading (e.g., 2-3 seconds)
    // In a real app, you might be fetching data, initializing services, etc.
    Timer(const Duration(seconds: 3), () {
      // Navigate to the AuthScreen after the delay
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // You can customize your splash screen's appearance here
      backgroundColor: Colors.blue, // Example background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Add your logo or any other widget
            // Example: FlutterLogo
            FlutterLogo(size: 100.0),
            const SizedBox(height: 24.0),
            const Text(
              'QR Keychain',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16.0),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
