import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import the package
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
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Example background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // **Use SvgPicture.asset for your SVG logo**
            SvgPicture.asset(
              'assets/images/app_logo.svg', // **Update with your actual path and filename**
              height: 100.0, // Adjust the size as needed
              width: 100.0, // Adjust the size as needed
              // You can also add a placeholder or semantics label:
              // placeholderBuilder: (BuildContext context) => Container(
              //   padding: const EdgeInsets.all(30.0),
              //   child: const CircularProgressIndicator(),
              // ),
              // semanticsLabel: 'App Logo'
            ),
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
