<img src="https://github.com/user-attachments/assets/682d29b1-a45e-4ba8-bad3-daad2988a9fb" width="100"/>

# QR Keychain

QR Keychain is a Flutter-based mobile application designed for securely handling encrypted information stored in QR codes. It provides a streamlined process for scanning, decrypting, and viewing sensitive data that has been protected using AES encryption.

The app features a dedicated scan area to ensure accurate detection of the target QR code. Once a QR code is scanned within this area, the application retrieves your encryption password from secure local storage and attempts to decrypt the content using AES with CBC mode and PKCS7 padding.

Security is a core focus, utilizing flutter_secure_storage for sensitive data and integrating with biometric authentication (like fingerprint or face recognition) as an optional, convenient access method.

### Features:

- Scan encrypted QR codes with a focused scan area.
- Decrypt QR code content using AES-128 with a stored password.
- Securely store the encryption password on the device.
- Toggle between biometric-only and biometric/device credential authentication.
- Visual feedback highlighting the detected QR code.
- Option to reset the stored encryption password.
- Torch control for better scanning conditions.

## Screenshots

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/ae92be0d-fd83-4d00-9146-a14ab68949e4" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/00db01bb-63b7-46bb-8029-b7868a3c9828" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/7830fe9a-7a15-41f2-8bb7-8d72aa77ddec" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/4716c368-27f5-411a-8082-d9c2a712ac83" width="200"/></td>

  </tr>
</table>
