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
import 'package:flutter_svg/flutter_svg.dart'; // Keep flutter_svg for the app logo
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import for checking if running on web

/// Secure storage instance.
final secureStorage = FlutterSecureStorage();

/// Secure storage key for the encryption password.
const String _encryptionPasswordKey = 'encryption_password';

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  late MobileScannerController _scannerController;
  String? _displayedValue;
  Timer? _resetTextTimer;

  Rect? _qrRect;
  Timer? _resetRectTimer;
  String?
  _encryptionPassword; // Will hold the password in memory for the session
  bool _passwordDialogShowing = false; // Track if the dialog is already open

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      returnImage: false,
    );
    // Use addPostFrameCallback to ensure context is available before showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePassword();
    });
  }

  /// Initializes the encryption password based on platform.
  /// On web, it always prompts. On mobile, it tries to load from secure storage first.
  Future<void> _initializePassword() async {
    if (_passwordDialogShowing) return; // Prevent multiple dialogs

    String? pwd;

    if (kIsWeb) {
      _passwordDialogShowing = true;
      pwd = await _askPasswordDialog();
      _passwordDialogShowing = false;

      if (pwd == null || pwd.isEmpty) {
        _showPasswordRequiredAndExit(); // Handle cancellation on web
        return;
      }
    } else {
      // On mobile, try to retrieve from secure storage first
      pwd = await secureStorage.read(key: _encryptionPasswordKey);
      if (pwd == null) {
        _passwordDialogShowing = true;
        pwd = await _askPasswordDialog();
        _passwordDialogShowing = false;

        if (pwd != null && pwd.isNotEmpty) {
          // Only store on mobile platforms
          await secureStorage.write(key: _encryptionPasswordKey, value: pwd);
        } else {
          _showPasswordRequiredAndExit(); // Handle cancellation on mobile
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _encryptionPassword = pwd;
      });
    }
  }

  /// Shows a snackbar and potentially exits the app if password is not provided.
  void _showPasswordRequiredAndExit() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password required to proceed. Please restart the app.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      // In a real app, on web, you might redirect to a different page,
      // or show a persistent error that requires the user to refresh.
      // On mobile, you could use SystemNavigator.pop() to exit the app completely.
      // For this example, we just show a message and prevent further interaction.
    }
  }

  /// Prompts the user to enter the encryption password.
  /// The dialog's barrierDismissible is set to false, requiring user input.
  Future<String?> _askPasswordDialog() async {
    TextEditingController controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false, // User must enter a password or cancel
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return PopScope(
              // Use PopScope for back button handling
              canPop: false, // Prevent popping with back button
              onPopInvoked: (didPop) async {
                if (didPop) return; // If system already popped, do nothing
                // If the user tries to go back, show the password required message
                _showPasswordRequiredAndExit();
                Navigator.of(context).pop(null); // Close the dialog
              },
              child: AlertDialog(
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
                      onChanged: (value) {
                        if (errorText != null && value.length == 16) {
                          setState(() {
                            errorText =
                                null; // Clear error if length is correct
                          });
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _showPasswordRequiredAndExit(); // Show message before exiting
                      Navigator.of(
                        context,
                      ).pop(null); // Return null for cancellation
                    },
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
              ),
            );
          },
        );
      },
    );
  }

  /// Handles QR code detection and performs AES decryption on the QR code content.
  Future<void> _handleDetection(BarcodeCapture capture) async {
    // Ensure password is loaded and available before attempting decryption
    if (!mounted ||
        _encryptionPassword == null ||
        _encryptionPassword!.isEmpty) {
      // Potentially re-prompt for password if it became null somehow
      // or just ignore detection until password is set.
      return;
    }

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
          final List<int> passwordBytes = utf8.encode(_encryptionPassword!);
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/app_logo.svg',
              semanticsLabel: 'App Logo',
              height: 30,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "QR Keychain - scan & decrypt",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
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
      body:
          _encryptionPassword == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      kIsWeb
                          ? 'Waiting for encryption password...'
                          : 'Loading encryption password...',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleDetection,
                    errorBuilder: (context, error) {
                      return Center(
                        child: Text(
                          "Camera error: $error",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 20,
                          ),
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
                                        _displayedValue!.startsWith(
                                          "Decryption error",
                                        )
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
                                _displayedValue!.startsWith("Decryption error")
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'reset_password',
            onPressed: () async {
              if (!kIsWeb) {
                // Only delete from secure storage on mobile
                await secureStorage.delete(key: _encryptionPasswordKey);
              }

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    kIsWeb
                        ? "Encryption password cleared from memory. Please re-enter."
                        : "Encryption password removed. Please restart or re-enter.",
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Clear password from current state and re-initialize
              if (mounted) {
                setState(() {
                  _encryptionPassword = null;
                });
              }
              await Future.delayed(const Duration(milliseconds: 500));
              await _initializePassword(); // Re-trigger the password prompt
            },
            backgroundColor: Colors.redAccent,
            tooltip: 'Reset Encryption Password',
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
