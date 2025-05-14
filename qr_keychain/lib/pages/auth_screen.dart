import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'scan_code_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authorized = 'Non autorizzato';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    setState(() {
      _isAuthenticating = true;
      _authorized = 'Autenticazione in corso...';
    });

    try {
      authenticated = await auth.authenticate(
        localizedReason:
            'Sblocca l\'app con la tua biometria',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Richiedi solo biometria, non password/PIN
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      //print("Errore durante l'autenticazione: $e");
      setState(() {
        _authorized = 'Errore: ${e.toString()}';
        _isAuthenticating = false;
      });
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _authorized = authenticated ? 'Autorizzato' : 'Non autorizzato';
    });

    if (authenticated) {
      // Se l'autenticazione ha successo, naviga alla pagina dello scanner
      if (mounted) {
        Navigator.pushReplacement(
          // Usa pushReplacement per impedire di tornare indietro
          context,
          MaterialPageRoute(builder: (context) => const ScanCodePage()),
        );
      }
    } else {
      // Handle authentication failure (e.g., show a message, prevent access)
      // You might want to stay on this screen or show an error dialog
      //print("Autenticazione biometrica fallita.");
    }
  }

  void _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accesso Sicuro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text('Autentica per accedere'),
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
    );
  }
}
