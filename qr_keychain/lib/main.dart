import 'package:flutter/material.dart';
// Import your new splash screen
import 'package:qr_keychain/pages/splash_screen.dart';
// You might not need AuthScreen imported here anymore if SplashScreen handles the navigation
// import 'package:qr_keychain/pages/auth_screen.dart';

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
        primarySwatch:
            Colors
                .blue, // Consider using ColorScheme.fromSeed for more modern themes
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Example of modern theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}
