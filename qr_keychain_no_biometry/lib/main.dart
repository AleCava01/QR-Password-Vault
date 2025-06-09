import 'package:flutter/material.dart';
import 'package:qr_keychain/pages/splash_screen.dart'; // IMPORTANT: Import your SplashScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Keychain',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness:
            Brightness.dark, // Keep dark theme for better QR scanning contrast
      ),
      home: const SplashScreen(), // Start with the SplashScreen
    );
  }
}
