# QR Encoder 🛠️🔐


This application encrypts text using **AES-128** and generates a **QR code** containing the encrypted data. It features a simple GUI, allowing you to easily create encrypted QR codes. 

<img src="https://github.com/user-attachments/assets/226ec1b2-1bda-4dd9-bbb8-79ad44601e4a" alt="QR code example" width="300">


## Features ✨
- **AES-128 Encryption**: Encrypts text using AES in CBC mode with a 128-bit key and random initialization vector (IV).
- **QR Code Generation**: Converts the encrypted base64 string into a QR code.
- **GUI Interface**: Built using Tkinter for a user-friendly experience.
- **Save and Print Options**: Save the generated QR code as an image or print it directly. 🖨️💾

## Usage 🖥️
### Launching the Application
You can launch the application in two ways:
1. **Run the Standalone EXE**:
 [Download here](https://github.com/AleCava01/QR-Password-Vault/blob/main/qr_encoder/dist/encoder/encoder.exe)
 (No Python installation required)
- **Run with Python**: Navigate to the project directory in your terminal and execute the following command:
  ``` python encoder.py ```
  Make sure all dependencies are installed (see the Requirements section below)

### Generating QR Codes
1. Input Password:
- Enter a password with exactly 16 characters. This password will be used to derive the encryption key (AES-128).
2. Input Text to Encrypt:
- Enter the text that you wish to encrypt in the provided text box. 
3. Click "Generate QR":
- The app will encrypt the text using AES-128 encryption and generate a QR code that contains the encrypted data in base64 format.
- If either the password is less than 16 characters or the input text is empty, the app will show an error message.

### Saving and Printing QR Codes
After generating a QR code, you can:
- Save QR Code:
  - Click the "Save QR" button to save the QR code as a .png file. You will be prompted to choose a save location.
- Print QR Code:
  - Click the "Print QR" button to send the QR code directly to your printer.

## Requirements 📦
The application requires the following Python packages:
- Python 3.x
- pycryptodome for AES encryption
- qrcode for QR code generation
- pillow for handling and displaying images
- tkinter (included by default in most Python installations)

To install the required packages, you can use the following command:
```
pip install pycryptodome qrcode[pil] pillow
```

## Encryption Details 🔒
The encryption uses AES-128 in CBC mode with the following parameters:
- Key: A 16-byte key derived from the user-provided password (first 16 characters).
- IV: A random 16-byte initialization vector (IV) generated using ```os.urandom(16)```.
- Padding: The plaintext is padded to ensure it is a multiple of the AES block size (16 bytes).

The encryption result is a combination of the IV and the ciphertext, both of which are base64-encoded and stored in the QR code.
