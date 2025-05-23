import base64
import os
import io
import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter.font import Font
from PIL import Image, ImageTk
import qrcode
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

# === Encryption Function ===
def encrypt_aes_cbc_base64(plaintext: str, password: str) -> str:
    key = password.encode('utf-8')[:16]
    iv = os.urandom(16)
    cipher = AES.new(key, AES.MODE_CBC, iv)
    ciphertext = cipher.encrypt(pad(plaintext.encode('utf-8'), AES.block_size))
    return base64.b64encode(iv + ciphertext).decode('utf-8')

# === QR Generation Function ===
def generate_qr(data: str) -> Image.Image:
    qr = qrcode.QRCode(
        version=1, error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=5, border=4  # Changed box_size from 10 to 5
    )
    qr.add_data(data)
    qr.make(fit=True)
    return qr.make_image(fill_color="black", back_color="white")

# === GUI Application ===
class QRGuiApp:
    def __init__(self, root):
        self.root = root
        self.root.title("AES QR Code Generator")
        self.root.geometry("500x900")
        self.root.configure(bg="#f9f9f9")

        title_font = Font(size=14, weight="bold")
        label_font = Font(size=10)

        tk.Label(root, text="AES-128 Encrypted QR Code Generator", font=title_font, bg="#f9f9f9").pack(pady=(10, 5))

        # Password Section
        pw_frame = tk.Frame(root, bg="#f9f9f9")
        pw_frame.pack(pady=(10, 5), fill="x", padx=20)

        tk.Label(pw_frame, text="Password (16 chars):", font=label_font, bg="#f9f9f9").pack(anchor="w")

        pw_inner_frame = tk.Frame(pw_frame, bg="#f9f9f9")
        pw_inner_frame.pack(fill="x")

        self.password_entry = tk.Entry(pw_inner_frame, show="*", font=("Courier", 10))
        self.password_entry.pack(side="left", fill="x", expand=True)

        self.show_pw = False
        self.toggle_button = tk.Button(pw_inner_frame, text="Show", command=self.toggle_password, width=6)
        self.toggle_button.pack(side="right", padx=5)

        # Plaintext Input
        tk.Label(root, text="Text to Encrypt:", font=label_font, bg="#f9f9f9").pack(anchor="w", padx=20)
        self.text_entry = tk.Text(root, height=5, font=("Courier", 10))
        self.text_entry.pack(fill="x", padx=20, pady=(0, 10))

        # Generate Button
        tk.Button(root, text="Generate QR", font=label_font, command=self.generate, bg="#007acc", fg="white").pack(pady=10)

        # Encrypted Output
        tk.Label(root, text="Encrypted Base64 Output:", font=label_font, bg="#f9f9f9").pack(anchor="w", padx=20)
        self.result_text = tk.Text(root, height=5, font=("Courier", 9), bg="#efefef", wrap="word")
        self.result_text.pack(fill="both", padx=20, pady=(0, 10))
        self.result_text.configure(state="disabled")

        # QR Image Display
        self.qr_label = tk.Label(root, bg="#f9f9f9")
        self.qr_label.pack(pady=10)

        # Save / Print Buttons
        btn_frame = tk.Frame(root, bg="#f9f9f9")
        btn_frame.pack(pady=10)

        tk.Button(btn_frame, text="Save QR", width=10, command=self.save_qr).pack(side="left", padx=10)
        tk.Button(btn_frame, text="Print QR", width=10, command=self.print_qr).pack(side="right", padx=10)

        self.qr_image = None  # Pillow image
        self.qr_tk_image = None  # ImageTk for display

    def toggle_password(self):
        self.show_pw = not self.show_pw
        if self.show_pw:
            self.password_entry.config(show="")
            self.toggle_button.config(text="Hide")
        else:
            self.password_entry.config(show="*")
            self.toggle_button.config(text="Show")

    def generate(self):
        password = self.password_entry.get()
        plaintext = self.text_entry.get("1.0", tk.END).strip()

        if len(password) != 16:
            messagebox.showerror("Error", "Password must be exactly 16 characters.")
            return
        if not plaintext:
            messagebox.showerror("Error", "Text to encrypt cannot be empty.")
            return

        try:
            encrypted = encrypt_aes_cbc_base64(plaintext, password)
            self.result_text.configure(state="normal")
            self.result_text.delete("1.0", tk.END)
            self.result_text.insert(tk.END, encrypted)
            self.result_text.configure(state="disabled")

            qr = generate_qr(encrypted)
            self.qr_image = qr
            
            # Resize the QR code image for display in the GUI
            # You can adjust the size as needed (e.g., 200, 200)
            display_width = 200 
            display_height = 200
            resized_qr = qr.resize((display_width, display_height), Image.LANCZOS) 
            
            self.qr_tk_image = ImageTk.PhotoImage(resized_qr) # Use the resized image here
            self.qr_label.configure(image=self.qr_tk_image)

        except Exception as e:
            messagebox.showerror("Encryption error", str(e))

    def save_qr(self):
        if self.qr_image is None:
            messagebox.showinfo("Info", "No QR code to save.")
            return

        file_path = filedialog.asksaveasfilename(defaultextension=".png", filetypes=[("PNG files", "*.png")])
        if file_path:
            self.qr_image.save(file_path)
            messagebox.showinfo("Saved", f"QR code saved.")

    def print_qr(self):
        if self.qr_image is None:
            messagebox.showinfo("Info", "No QR code to print.")
            return
        try:
            temp_path = "_temp_qr_print.png"
            self.qr_image.save(temp_path)
            if os.name == "nt":
                os.startfile(temp_path, "print")  # Windows native print
            else:
                os.system(f"lp '{temp_path}'")  # macOS/Linux
        except Exception as e:
            messagebox.showerror("Print Error", str(e))

# === Run App ===
if __name__ == "__main__":
    root = tk.Tk()
    app = QRGuiApp(root)
    root.mainloop()