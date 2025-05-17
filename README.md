# QR Password Vault Project
End-to-end encrypted QR code system for offline credential storage and retrieval.
Generate AES-128 encrypted QR codes via a Python GUI and securely scan and decrypt them with a Flutter (Android/iOS) app protected by biometrics.
This project is composed of two components: *QR Encoder* and *QR Keychain*.

## 🔐 [QR Encoder](https://github.com/AleCava01/QR-Password-Vault/tree/main/qr_encoder) - Create your QR Vault
A Python-based graphical user interface (GUI) that allows users to generate AES-128 encrypted QR codes. Users can input a password and a message—typically including the service name, username, password, and any other relevant account information. The input is then:

1. Encrypted using AES in CBC mode with a randomly generated IV.
2. Encoded into a Base64 string.
3. Converted into a QR code, which can be saved or printed directly from the interface.
   
<br>

![encode_diagram drawio (5)](https://github.com/user-attachments/assets/7cf90d46-9d6d-49e2-9e5a-125a85881293)

## 📱 [QR Keychain](https://github.com/AleCava01/QR-Password-Vault/tree/main/qr_keychain) - Access the Vault
A Flutter mobile application for Android and iOS that scans printed or digital QR codes containing AES-128 encrypted credentials. Upon scanning, the data is decrypted and displayed—only after successful biometric authentication, ensuring secure access.

This app enables safe, offline retrieval of stored credentials without relying on cloud services or network connections.
<br>

![decode_diagram drawio (18)](https://github.com/user-attachments/assets/6e08b6a4-6eb2-47e3-8c68-0cad68a8767c)
