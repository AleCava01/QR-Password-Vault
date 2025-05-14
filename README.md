# 🔐 QR Password Vault Project
End-to-end encrypted QR code system for offline credential storage and retrieval.
Generate AES-128 encrypted QR codes via a Python GUI and securely scan and decrypt them with a Flutter (Android/iOS) app protected by biometrics.
This project is composed of two components: *QR Encoder* and *QR Keychain*.

## ✨ QR Encoder
A Python-based graphical user interface (GUI) that allows users to generate AES-128 encrypted QR codes. Users can input a password and a message—typically including the service name, username, password, and any other relevant account information. The input is then:

1. Encrypted using AES in CBC mode with a randomly generated IV.
2. Encoded into a Base64 string.
3. Converted into a QR code, which can be saved or printed directly from the interface.

This tool is ideal for secure offline storage and transfer of sensitive credentials via QR codes.

## 📱 QR Keychain
A Flutter mobile application for Android and iOS that scans printed or digital QR codes containing AES-128 encrypted credentials. Upon scanning, the data is decrypted and displayed—only after successful biometric authentication, ensuring secure access.

This app enables safe, offline retrieval of stored credentials without relying on cloud services or network connections.
```
+---------------------+
|     User Input      |
|  (service info, pw) |
+----------+----------+
           |
           v
+----------------------------+
|    QR Encoder (Python GUI)|
+----------------------------+
| 1. Encrypt using AES-128   |
|    (CBC mode + IV)         |
| 2. Encode with Base64      |
| 3. Generate QR Code        |
+------------+---------------+
             |
             v
   +------------------------+
   |   Save / Print QR Code |
   +------------+-----------+
                |
                v
      [ Physical QR Code(s) ]
                |
                v
+-----------------------------+
|  QR Keychain (Flutter App)  |
+-----------------------------+
| 1. Unlock via Biometrics    |
| 2. Scan Printed QR Code     |
| 3. Decrypt & Display Data   |
+-----------------------------+
```
