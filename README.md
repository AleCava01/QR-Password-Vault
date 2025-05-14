# 🔐 QR Password Vault Project
This project consists of two components: QR Encoder and QR Keychain.

## ✨ QR Encoder
A Python-based graphical user interface (GUI) that allows users to generate AES-128 encrypted QR codes. Users can input a password and a message—typically including the service name, username, password, and any other relevant account information. The input is then:

1. Encrypted using AES in CBC mode with a randomly generated IV.
2. Encoded into a Base64 string.
3. Converted into a QR code, which can be saved or printed directly from the interface.

This tool is ideal for secure offline storage and transfer of sensitive credentials via QR codes.

## 📱 QR Keychain
A Flutter app for Android and iOS that scans QR codes containing AES-128 encrypted credentials (e.g., printed QR codes) and decrypts them to display the stored information. The app is secured using biometric authentication to prevent unauthorized access.
