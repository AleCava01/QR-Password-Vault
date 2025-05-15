import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'scan_code_page.dart'; // Already importing for navigation and now for secureStorage functions

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
      // You might want to show a specific message or allow retry.
      //print("Autenticazione fallita. BiometricOnly: $_biometricOnlyPreference");
      if (mounted) {
        // Check mounted before setState
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _biometricOnlyPreference
                  ? 'Modalità: Solo Biometrica'
                  : 'Modalità: Biometrica o PIN/Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 20),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _authenticate, // Allow re-authentication attempt
                child: const Text('Autentica per accedere'),
              ),
            const SizedBox(height: 20),
            Text('Stato: $_authorized'),
            if (_isAuthenticating)
              TextButton(
                onPressed: _cancelAuthentication,
                child: const Text('Annulla'),
              ),
            // You could add a button here to exit the app if auth fails repeatedly.
          ],
        ),
      ),
    );
  }
}
