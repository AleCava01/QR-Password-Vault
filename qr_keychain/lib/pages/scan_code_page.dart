/// This file contains a Flutter page for scanning encrypted QR codes,
/// decrypting them using AES encryption, and displaying the result.
///
/// The app uses the `mobile_scanner` package for QR code scanning,
/// the `encrypt` package for AES decryption, and the
/// `flutter_secure_storage` package to store and retrieve the encryption
/// password securely.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage instance for storing the encryption password.
final secureStorage = FlutterSecureStorage();

/// Stores the encryption password securely in local storage.
///
/// @param password The password to store.
///
/// @return A Future indicating when the password is stored.
Future<void> storePassword(String password) async {
  await secureStorage.write(key: 'encryption_password', value: password);
}

/// Retrieves the stored encryption password from local storage.
///
/// @return A Future containing the stored password, or null if not found.
Future<String?> retrievePassword() async {
  return await secureStorage.read(key: 'encryption_password');
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

  @override
  void initState() {
    super.initState();
    // Initialize the scanner controller with default settings.
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
    // Load the encryption password from secure storage.
    _loadPassword();
  }

  /// Loads the encryption password from secure storage or prompts the user to enter it.
  ///
  /// This method checks if the password is already stored and if not, it asks the user to input it.
  Future<void> _loadPassword() async {
    String? pwd = await secureStorage.read(key: 'encryption_password');

    if (pwd == null) {
      pwd = await _askPasswordDialog();
      if (pwd != null && pwd.isNotEmpty) {
        await secureStorage.write(key: 'encryption_password', value: pwd);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password required to proceed.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _encryptionPassword = pwd!;
    });
  }

  /// Prompts the user to enter the encryption password.
  ///
  /// This dialog ensures that the entered password is 16 characters long.
  ///
  /// @return The entered password, or null if the user cancels.
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
  ///
  /// @param capture The BarcodeCapture object containing detected barcodes.
  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (capture.barcodes.isNotEmpty) {
      final barcode = capture.barcodes.first;
      final String? rawQrValue = barcode.rawValue;

      // Check QR code corners and update the scanning rectangle.
      if (barcode.corners.length == 4) {
        final corners = barcode.corners;
        final topLeft = corners[0];
        final bottomRight = corners[2];
        final rect = Rect.fromPoints(topLeft, bottomRight);

        if (_qrRect != rect) {
          setState(() {
            _qrRect = rect;
          });
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

      // If QR code content exists, attempt to decrypt it.
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

        // Display the decrypted text.
        if (_displayedValue != decryptedTextToShow) {
          setState(() {
            _displayedValue = decryptedTextToShow;
          });
        }

        // Clear the displayed text after a short delay.
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

  /// Builds the UI of the page.
  ///
  /// This method contains the QR scanner, displays the decrypted text,
  /// and provides buttons for controlling the flashlight and resetting the password.
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
            errorBuilder: (context, error) {
              return const Center(
                child: Text(
                  "Camera error",
                  style: TextStyle(color: Colors.red, fontSize: 20),
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
                        _displayedValue == null ||
                                _displayedValue!.startsWith("Error")
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
                    color:
                        _displayedValue!.startsWith("Error")
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
                  maxLines: null,
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'reset_password',
            onPressed: () async {
              await secureStorage.delete(key: 'encryption_password');

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Encryption password removed from secure storage.",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 500));

              if (!mounted) return;

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
