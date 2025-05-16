import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'scan_code_page.dart';

// We can use the functions directly if they are top-level in scan_code_page.dart
// or import a dedicated service file if you create one.

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authorized = 'Non autorizzato';
  bool _isAuthenticating = false;
  bool _biometricOnlyPreference = true; // Default, will be loaded

  @override
  void initState() {
    super.initState();
    _initializeAndAuthenticate();
  }

  Future<void> _initializeAndAuthenticate() async {
    // Load the preference first
    // Assuming retrieveBiometricPreference() is defined elsewhere, possibly in scan_code_page.dart
    // For this example, I'll ensure it's callable. If it's in scan_code_page.dart,
    // ensure it's properly exported or you have an instance if it's part of a class.
    // For simplicity, let's assume it's a global function or properly imported.
    _biometricOnlyPreference = await retrieveBiometricPreference();
    // Then attempt authentication
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    if (mounted) {
      // Check mounted before setState
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Autenticazione in corso...';
      });
    }

    try {
      authenticated = await auth.authenticate(
        localizedReason:
            _biometricOnlyPreference
                ? 'Sblocca l\'app con la tua biometria'
                : 'Sblocca l\'app con biometria o credenziali dispositivo',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: _biometricOnlyPreference, // Use the loaded preference
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      //print("Errore durante l'autenticazione: $e");
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _authorized = 'Errore: ${e.toString()}';
          _isAuthenticating = false;
        });
      }
      return;
    }

    if (mounted) {
      // Check mounted before setState
      setState(() {
        _isAuthenticating = false;
        _authorized = authenticated ? 'Autorizzato' : 'Non autorizzato';
      });
    }

    if (authenticated) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ScanCodePage()),
        );
      }
    } else {
      // Handle authentication failure
      //print("Autenticazione fallita. BiometricOnly: $_biometricOnlyPreference");
      if (mounted) {
        // Check mounted before setState
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // Added const
            content: Text('Autenticazione fallita. Riprova.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _cancelAuthentication() async {
    await auth.stopAuthentication();
    if (mounted) {
      // Check mounted before setState
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accesso Sicuro')),
      body: Center(
        child: Padding(
          // Added Padding for overall spacing
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // **Add your SVG logo here**
              SvgPicture.asset(
                'assets/images/app_logo.svg', // **Make sure this path is correct**
                height: 80.0, // Adjust size as needed
                width: 80.0, // Adjust size as needed
                semanticsLabel: 'App Logo', // Good for accessibility
              ),
              const SizedBox(height: 30), // Spacing after logo

              Text(
                _biometricOnlyPreference
                    ? 'Modalità: Solo Biometrica'
                    : 'Modalità: Biometrica o PIN/Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center, // Good for potentially longer text
              ),
              const SizedBox(height: 20),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  // Changed to ElevatedButton.icon for better UI with an icon
                  icon: const Icon(Icons.fingerprint),
                  onPressed: _authenticate,
                  label: const Text('Autentica per accedere'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Stato: $_authorized'),
              if (_isAuthenticating)
                TextButton(
                  onPressed: _cancelAuthentication,
                  child: const Text('Annulla'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for the function you are importing from scan_code_page.dart
// Ensure this function exists and is accessible.
// If it's defined in scan_code_page.dart, it should be:
// Future<bool> retrieveBiometricPreference() async { /* ... your logic ... */ }
// You might need to import it more specifically if it's part of a class.
// For this example, to make the AuthScreen runnable standalone for UI preview:
Future<bool> retrieveBiometricPreference() async {
  // This is a placeholder. Replace with your actual implementation.
  // For example, if using shared_preferences:
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // return prefs.getBool('biometric_only') ?? true;
  //print("retrieveBiometricPreference called (placeholder)");
  return true; // Defaulting to true for the example
}
