/// This file contains a Flutter page for scanning encrypted QR codes,
/// decrypting them using AES encryption, and displaying the result.
///
/// The app uses the `mobile_scanner` package for QR code scanning,
/// the `encrypt` package for AES decryption, and the
/// `flutter_secure_storage` package to store and retrieve the encryption
/// password and biometric preference securely.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import AuthScreen to potentially navigate to it, though not strictly needed for this toggle.
// We are already navigating to ScanCodePage from AuthScreen.
// For resetting password and re-initiating the auth flow, AuthScreen will pick up the new preference.
// import 'auth_screen.dart'; // If you were to navigate back to AuthScreen explicitly from here.

/// Secure storage instance.
final secureStorage = FlutterSecureStorage();

/// Secure storage key for the encryption password.
const String _encryptionPasswordKey = 'encryption_password';

/// Secure storage key for the biometricOnly preference.
const String _biometricOnlyPreferenceKey = 'biometric_only_preference';

/// Stores the encryption password securely in local storage.
Future<void> storePassword(String password) async {
  await secureStorage.write(key: _encryptionPasswordKey, value: password);
}

/// Retrieves the stored encryption password from local storage.
Future<String?> retrievePassword() async {
  return await secureStorage.read(key: _encryptionPasswordKey);
}

/// Stores the biometricOnly preference.
Future<void> storeBiometricPreference(bool isBiometricOnly) async {
  await secureStorage.write(
      key: _biometricOnlyPreferenceKey, value: isBiometricOnly.toString());
}

/// Retrieves the biometricOnly preference. Defaults to false if not set.
Future<bool> retrieveBiometricPreference() async {
  String? value = await secureStorage.read(key: _biometricOnlyPreferenceKey);
  // Default to false (biometric or pin) if no preference is stored yet
  if (value == null) return false;
  return value == 'False';
}

/// The main page for scanning QR codes and decrypting them.
class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

/// State class for the ScanCodePage.
class _ScanCodePageState extends State<ScanCodePage> {
  late MobileScannerController _scannerController;
  String? _displayedValue;
  Timer? _resetTextTimer;

  Rect? _qrRect;
  Timer? _resetRectTimer;
  late String _encryptionPassword;
  bool _isBiometricOnlyEnabled = true; // Default, will be loaded from storage

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
    _loadPassword();
    _loadBiometricPreference(); // Load the biometric preference
  }

  Future<void> _loadBiometricPreference() async {
    bool preference = await retrieveBiometricPreference();
    if (mounted) {
      setState(() {
        _isBiometricOnlyEnabled = preference;
      });
    }
  }

  Future<void> _toggleBiometricPreference() async {
    final newPreference = !_isBiometricOnlyEnabled;
    await storeBiometricPreference(newPreference);
    if (mounted) {
      setState(() {
        _isBiometricOnlyEnabled = newPreference;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPreference
                ? 'Biometric only authentication enabled.'
                : 'Biometric with device credentials enabled.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Loads the encryption password from secure storage or prompts the user to enter it.
  Future<void> _loadPassword() async {
    String? pwd = await secureStorage.read(key: _encryptionPasswordKey);

    if (pwd == null) {
      pwd = await _askPasswordDialog();
      if (pwd != null && pwd.isNotEmpty) {
        await secureStorage.write(key: _encryptionPasswordKey, value: pwd);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password required to proceed.'),
              duration: Duration(seconds: 3),
            ),
          );
          // Potentially navigate back or handle lack of password
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _encryptionPassword = pwd!;
      });
    }
  }

  /// Prompts the user to enter the encryption password.
  Future<String?> _askPasswordDialog() async {
    TextEditingController controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter encryption password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password (16 characters)',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final pwd = controller.text.trim();
                    if (pwd.length != 16) {
                      setState(() {
                        errorText = 'Password must be exactly 16 characters.';
                      });
                    } else {
                      Navigator.of(context).pop(pwd);
                    }
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Handles QR code detection and performs AES decryption on the QR code content.
  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (!mounted || _encryptionPassword.isEmpty) return; // Ensure password is loaded

    if (capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      final String? rawQrValue = barcode.rawValue;

      if (barcode.corners.length == 4) {
        final corners = barcode.corners;
        final topLeft = corners[0];
        final bottomRight = corners[2];
        final rect = Rect.fromPoints(topLeft, bottomRight);

        if (_qrRect != rect) {
          if (mounted) {
            setState(() {
              _qrRect = rect;
            });
          }
        }

        _resetRectTimer?.cancel();
        _resetRectTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _qrRect = null;
            });
          }
        });
      }

      if (rawQrValue != null && rawQrValue.isNotEmpty) {
        String decryptedTextToShow;
        try {
          final List<int> passwordBytes = utf8.encode(_encryptionPassword);
          final Uint8List keyBytes = Uint8List.fromList(
            passwordBytes.sublist(0, 16),
          );
          final key = encrypt.Key(keyBytes);

          Uint8List encryptedBytesWithIv;
          try {
            encryptedBytesWithIv = base64.decode(rawQrValue);
          } catch (e) {
            throw Exception("QR content is not valid Base64: $e");
          }

          if (encryptedBytesWithIv.length < 16) {
            throw Exception(
              "Encrypted data too short to contain IV (${encryptedBytesWithIv.length} bytes).",
            );
          }
          final iv = encrypt.IV(encryptedBytesWithIv.sublist(0, 16));
          final ciphertextBytes = encryptedBytesWithIv.sublist(16);

          if (ciphertextBytes.isEmpty) {
            throw Exception("Empty ciphertext after IV extraction.");
          }

          final encrypter = encrypt.Encrypter(
            encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
          );

          final decrypted = encrypter.decrypt(
            encrypt.Encrypted(ciphertextBytes),
            iv: iv,
          );
          decryptedTextToShow = decrypted;
        } catch (e) {
          decryptedTextToShow =
              "Decryption error: ${e.toString().split(':').last.trim()}";
        }

        if (_displayedValue != decryptedTextToShow) {
          if (mounted) {
            setState(() {
              _displayedValue = decryptedTextToShow;
            });
          }
        }

        _resetTextTimer?.cancel();
        _resetTextTimer = Timer(const Duration(seconds: 7), () {
          if (mounted) {
            setState(() {
              _displayedValue = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "QR Keychain - scan & decrypt",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(
              Icons.qr_code_scanner,
              color: Colors.white.withAlpha(180),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
            errorBuilder: (context, error) { // Added child parameter
              //print("MobileScanner Error: ${error.name}, ${error.errorDetails}"); // Log the error
              return Center(
                child: Text(
                  "Camera error: $error",
                  style: const TextStyle(color: Colors.red, fontSize: 20),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent.withAlpha(128),
                  width: 2,
                ),
              ),
            ),
          ),
          if (_qrRect != null)
            Positioned(
              left: _qrRect!.left,
              top: _qrRect!.top,
              width: _qrRect!.width,
              height: _qrRect!.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _displayedValue == null || _displayedValue!.startsWith("Decryption error")
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                    width: 3.0,
                  ),
                ),
              ),
            ),
          if (_displayedValue != null)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 20.0,
              right: 20.0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(204),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _displayedValue!.startsWith("Decryption error")
                        ? Colors.redAccent
                        : Colors.green,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(128),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _displayedValue!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: null, // Allow text to wrap
                  overflow: TextOverflow.visible,
                ),
              ),
            )
          else
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 20.0,
              right: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.grey.withAlpha(128),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  "Scan an encrypted QR code...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'reset_password',
            onPressed: () async {
              await secureStorage.delete(key: _encryptionPasswordKey);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Encryption password removed. Please restart or re-authenticate.",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 500));

              if (!mounted) return;

              // Instead of pushing ScanCodePage again, you might want to navigate
              // to a screen that forces re-authentication, like AuthScreen.
              // For simplicity, current behavior reloads ScanCodePage which will trigger password prompt.
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ScanCodePage()),
              );
            },
            backgroundColor: Colors.redAccent,
            tooltip: 'Reset Password',
            child: const Icon(Icons.lock_reset),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'toggle_biometric_preference',
            onPressed: _toggleBiometricPreference,
            tooltip: _isBiometricOnlyEnabled
                ? 'Auth: Biometric Only'
                : 'Auth: Biometric or Device PIN/Pass',
            backgroundColor: _isBiometricOnlyEnabled ? Colors.blueAccent : Colors.teal,
            child: Icon(
              _isBiometricOnlyEnabled ? Icons.fingerprint : Icons.phonelink_lock_outlined,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'toggle_torch',
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: 'Toggle Torch',
            child: const Icon(Icons.flash_on),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _resetTextTimer?.cancel();
    _resetRectTimer?.cancel();
    _scannerController.dispose();
    super.dispose();
  }
}