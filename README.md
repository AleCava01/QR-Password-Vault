# QR Password Vault Project
End-to-end encrypted QR code system for offline credential storage and retrieval.
Generate AES-128 encrypted QR codes via a Python GUI and securely scan and decrypt them with a Flutter (Android/iOS) app protected by biometrics.
This project is composed of two components: *QR Encoder* and *QR Keychain*.

## 🔐 [QR Encoder](https://github.com/AleCava01/QR-Password-Vault/tree/main/qr_encoder) - Create your QR Vault
A Python-based graphical user interface (GUI) that allows users to generate AES-128 encrypted QR codes. Users can input a password and a message—typically including the service name, username, password, and any other relevant account information. The input is then:

1. Encrypted using AES in CBC mode with a randomly generated IV.
2. Encoded into a Base64 string.
3. Converted into a QR code, which can be saved or printed directly from the interface.

![encoder drawio (1)](https://github.com/user-attachments/assets/b34801f6-46ba-488b-b143-a0b4835c19a5)

## 📱 [QR Keychain](https://github.com/AleCava01/QR-Password-Vault/tree/main/qr_keychain) - Access the Vault
A Flutter mobile application for Android and iOS that scans printed or digital QR codes containing AES-128 encrypted credentials. Upon scanning, the data is decrypted and displayed—only after successful biometric authentication, ensuring secure access.

This app enables safe, offline retrieval of stored credentials without relying on cloud services or network connections.
<br>
<br>


![decode_diagram drawio (1)](https://github.com/user-attachments/assets/d3657eec-e5b6-4ec8-a4bb-d3c8fce25dd1)
