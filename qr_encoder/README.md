# QR Encoder 🛠️🔐
 <p>
        <strong>QR Encoder</strong> is a fully offline desktop application that allows you to encrypt any text using AES-128 and convert the result into a QR code. 
        Designed for simplicity and privacy, it does not store or transmit any data — everything happens locally on your machine.
      </p>
<table>
  <tr>
    <td>
           <h2>✨ Features</h2>
      <ul>
        <li><strong>AES-128 Encryption</strong>: Securely encrypts input text using a symmetric key and a random IV</li>
        <li><strong>QR Code Generation</strong>: Encodes the encrypted output into a scannable QR code</li>
        <li><strong>GUI</strong>: Built with Tkinter</li>
        <li><strong>Save & Print</strong>: Export or directly print the generated QR code</li>
        <li><strong>Privacy-Focused</strong>: No internet connection required, no cloud syncing, and no data is saved after closing the app</li>
      </ul>
      <h2>🔒 Encryption Details</h2>
      <ul>
        <li><strong>Key</strong>: A 16-byte key derived from the user's password (first 16 characters)</li>
        <li><strong>IV</strong>: Random 16-byte initialization vector generated with <code>os.urandom(16)</code></li>
        <li><strong>Mode</strong>: AES in CBC (Cipher Block Chaining) mode</li>
        <li><strong>Padding</strong>: PKCS7-style to align plaintext to AES block size (16 bytes)</li>
      </ul>
     <br>
     The encryption result is a combination of the IV and the ciphertext, both of which are base64-encoded and stored in the QR code.
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/226ec1b2-1bda-4dd9-bbb8-79ad44601e4a" alt="QR Encoder Screenshot" width="400"/>
    </td>
  </tr>
</table>


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

