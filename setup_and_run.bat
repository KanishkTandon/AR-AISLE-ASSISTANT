@echo off
echo ========================================
echo    AR Aisle Assistant - Auto Setup
echo ========================================
echo.

:: Set console colors for better visibility
color 0A

:: Check if running as administrator (for Python installation if needed)
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as administrator.
    echo Python installation may fail if Python is not already installed.
    echo Consider running as administrator for first-time setup.
    echo.
    timeout /t 3 >nul
)

:: Check if Python is installed
echo [1/6] Checking Python installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Python not found. Attempting to install Python...
    echo.
    
    :: Download and install Python 3.11
    echo Downloading Python 3.11...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe' -OutFile 'python_installer.exe'}"
    
    if exist python_installer.exe (
        echo Installing Python... This may take a few minutes.
        echo Please follow the installer prompts and make sure to check "Add Python to PATH"
        start /wait python_installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
        del python_installer.exe
        
        :: Refresh environment variables
        echo Refreshing environment variables...
        call refreshenv >nul 2>&1 || (
            echo Please restart this script after Python installation completes.
            pause
            exit /b 1
        )
        
        :: Test Python again
        python --version >nul 2>&1
        if %errorLevel% neq 0 (
            echo Python installation may have failed or PATH not updated.
            echo Please install Python manually from https://python.org
            echo Make sure to check "Add Python to PATH" during installation.
            pause
            exit /b 1
        )
    ) else (
        echo Failed to download Python installer.
        echo Please install Python manually from https://python.org
        pause
        exit /b 1
    )
)

:: Display Python version
for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo ✓ %PYTHON_VERSION% found
echo.

:: Check if pip is available
echo [2/6] Checking pip installation...
python -m pip --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing pip...
    python -m ensurepip --upgrade
    if %errorLevel% neq 0 (
        echo Failed to install pip. Please install it manually.
        pause
        exit /b 1
    )
)
echo ✓ pip is available
echo.

:: Upgrade pip to latest version
echo [3/6] Updating pip to latest version...
python -m pip install --upgrade pip >nul 2>&1
echo ✓ pip updated
echo.

:: Install required packages
echo [4/6] Installing required packages...
echo Installing qrcode...
python -m pip install qrcode[pil] --quiet
if %errorLevel% neq 0 (
    echo Failed to install qrcode package.
    echo Trying alternative installation...
    python -m pip install qrcode pillow --quiet
)

echo Installing additional dependencies...
python -m pip install requests urllib3 --quiet

:: Verify installations
python -c "import qrcode; import PIL; print('✓ QR Code packages installed successfully')" 2>nul
if %errorLevel% neq 0 (
    echo Warning: QR code generation may not work properly.
    echo Continuing with basic functionality...
)
echo.

:: Create server.py if it doesn't exist
echo [5/6] Setting up AR Aisle Assistant server...
if not exist "server.py" (
    echo Creating server.py...
    (
        echo import http.server
        echo import socketserver
        echo import ssl
        echo import socket
        echo import os
        echo import sys
        echo import webbrowser
        echo from urllib.parse import urlparse
        echo import threading
        echo import time
        echo.
        echo try:
        echo     import qrcode
        echo     from PIL import Image
        echo     QR_AVAILABLE = True
        echo except ImportError:
        echo     QR_AVAILABLE = False
        echo     print("QR code generation not available. Install with: pip install qrcode[pil]"^)
        echo.
        echo class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler^):
        echo     def end_headers(self^):
        echo         self.send_header('Access-Control-Allow-Origin', '*'^)
        echo         self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS'^)
        echo         self.send_header('Access-Control-Allow-Headers', '*'^)
        echo         self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate'^)
        echo         super(^).end_headers(^)
        echo.
        echo     def do_OPTIONS(self^):
        echo         self.send_response(200^)
        echo         self.end_headers(^)
        echo.
        echo def get_local_ip(^):
        echo     try:
        echo         # Connect to a remote server to determine local IP
        echo         s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM^)
        echo         s.connect(("8.8.8.8", 80^)^)
        echo         ip = s.getsockname()[0]
        echo         s.close(^)
        echo         return ip
        echo     except Exception:
        echo         return "127.0.0.1"
        echo.
        echo def create_ssl_cert(^):
        echo     """Create a self-signed SSL certificate for HTTPS"""
        echo     try:
        echo         from cryptography import x509
        echo         from cryptography.x509.oid import NameOID
        echo         from cryptography.hazmat.primitives import hashes, serialization
        echo         from cryptography.hazmat.primitives.asymmetric import rsa
        echo         import datetime
        echo.
        echo         # Generate private key
        echo         private_key = rsa.generate_private_key(
        echo             public_exponent=65537,
        echo             key_size=2048
        echo         ^)
        echo.
        echo         # Create certificate
        echo         subject = issuer = x509.Name([
        echo             x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"^),
        echo             x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"Local"^),
        echo             x509.NameAttribute(NameOID.LOCALITY_NAME, u"LocalHost"^),
        echo             x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"AR Assistant"^),
        echo             x509.NameAttribute(NameOID.COMMON_NAME, u"localhost"^),
        echo         ]^)
        echo.
        echo         cert = x509.CertificateBuilder(^).subject_name(
        echo             subject
        echo         ^).issuer_name(
        echo             issuer
        echo         ^).public_key(
        echo             private_key.public_key(^)
        echo         ^).serial_number(
        echo             x509.random_serial_number(^)
        echo         ^).not_valid_before(
        echo             datetime.datetime.utcnow(^)
        echo         ^).not_valid_after(
        echo             datetime.datetime.utcnow(^) + datetime.timedelta(days=365^)
        echo         ^).sign(private_key, hashes.SHA256(^)^)
        echo.
        echo         # Write certificate and key to files
        echo         with open("cert.pem", "wb"^) as f:
        echo             f.write(cert.public_bytes(serialization.Encoding.PEM^)^)
        echo.
        echo         with open("key.pem", "wb"^) as f:
        echo             f.write(private_key.private_bytes(
        echo                 encoding=serialization.Encoding.PEM,
        echo                 format=serialization.PrivateFormat.PKCS8,
        echo                 encryption_algorithm=serialization.NoEncryption(^)
        echo             ^)^)
        echo.
        echo         return True
        echo     except ImportError:
        echo         return False
        echo     except Exception as e:
        echo         print(f"SSL certificate creation failed: {e}"^)
        echo         return False
        echo.
        echo def generate_qr_code(url^):
        echo     if not QR_AVAILABLE:
        echo         return False
        echo.
        echo     try:
        echo         qr = qrcode.QRCode(
        echo             version=1,
        echo             error_correction=qrcode.constants.ERROR_CORRECT_L,
        echo             box_size=3,
        echo             border=2,
        echo         ^)
        echo         qr.add_data(url^)
        echo         qr.make(fit=True^)
        echo.
        echo         # Create ASCII QR code for console
        echo         qr_ascii = qrcode.QRCode(
        echo             version=1,
        echo             error_correction=qrcode.constants.ERROR_CORRECT_L,
        echo             box_size=1,
        echo             border=1,
        echo         ^)
        echo         qr_ascii.add_data(url^)
        echo         qr_ascii.make(fit=True^)
        echo.
        echo         # Print ASCII QR code
        echo         print("\\n" + "="*50^)
        echo         print("📱 SCAN QR CODE WITH YOUR MOBILE DEVICE 📱"^)
        echo         print("="*50^)
        echo         qr_ascii.print_ascii(tty=True^)
        echo         print("="*50^)
        echo         print(f"🔗 Or open this URL manually: {url}"^)
        echo         print("="*50 + "\\n"^)
        echo.
        echo         # Save QR code image
        echo         img = qr.make_image(fill_color="black", back_color="white"^)
        echo         img.save("ar_assistant_qr.png"^)
        echo         print("💾 QR code saved as 'ar_assistant_qr.png'"^)
        echo.
        echo         return True
        echo     except Exception as e:
        echo         print(f"QR code generation failed: {e}"^)
        echo         return False
        echo.
        echo def start_server(port=8000^):
        echo     local_ip = get_local_ip(^)
        echo     
        echo     print(f"🌐 Starting AR Aisle Assistant server..."^)
        echo     print(f"📍 Local IP: {local_ip}"^)
        echo.
        echo     # Try HTTPS first
        echo     https_success = False
        echo     if create_ssl_cert(^) or (os.path.exists("cert.pem"^) and os.path.exists("key.pem"^)^):
        echo         try:
        echo             httpd = socketserver.TCPServer(("", port^), CORSHTTPRequestHandler^)
        echo             httpd.socket = ssl.wrap_socket(httpd.socket, 
        echo                                          certfile="cert.pem", 
        echo                                          keyfile="key.pem", 
        echo                                          server_side=True^)
        echo             https_url = f"https://{local_ip}:{port}/ar_aisle_assistant.html"
        echo             
        echo             print(f"🔒 HTTPS Server starting on port {port}"^)
        echo             print(f"🎯 AR Assistant URL: {https_url}"^)
        echo             
        echo             # Generate QR code
        echo             generate_qr_code(https_url^)
        echo             
        echo             print("\\n🚀 Server is running! Use Ctrl+C to stop."^)
        echo             print("📱 Camera access requires HTTPS - QR code ready for mobile!"^)
        echo             
        echo             # Open in default browser
        echo             threading.Timer(2.0, lambda: webbrowser.open(f"http://localhost:{port}/ar_aisle_assistant.html"^)^).start(^)
        echo             
        echo             httpd.serve_forever(^)
        echo             https_success = True
        echo             
        echo         except Exception as e:
        echo             print(f"❌ HTTPS failed: {e}"^)
        echo             print("🔄 Falling back to HTTP..."^)
        echo.
        echo     # Fallback to HTTP
        echo     if not https_success:
        echo         try:
        echo             httpd = socketserver.TCPServer(("", port^), CORSHTTPRequestHandler^)
        echo             http_url = f"http://{local_ip}:{port}/ar_aisle_assistant.html"
        echo             
        echo             print(f"🌐 HTTP Server starting on port {port}"^)
        echo             print(f"🎯 AR Assistant URL: {http_url}"^)
        echo             print("⚠️  Camera may not work over HTTP - use HTTPS for full AR features"^)
        echo             
        echo             # Generate QR code
        echo             generate_qr_code(http_url^)
        echo             
        echo             print("\\n🚀 Server is running! Use Ctrl+C to stop."^)
        echo             
        echo             # Open in default browser
        echo             threading.Timer(2.0, lambda: webbrowser.open(f"http://localhost:{port}/ar_aisle_assistant.html"^)^).start(^)
        echo             
        echo             httpd.serve_forever(^)
        echo             
        echo         except Exception as e:
        echo             print(f"❌ Failed to start server: {e}"^)
        echo             return False
        echo.
        echo     return True
        echo.
        echo if __name__ == "__main__":
        echo     try:
        echo         # Check if HTML file exists
        echo         if not os.path.exists("ar_aisle_assistant.html"^):
        echo             print("❌ ar_aisle_assistant.html not found!"^)
        echo             print("Make sure you're running this from the correct directory."^)
        echo             input("Press Enter to exit..."^)
        echo             sys.exit(1^)
        echo.
        echo         start_server(^)
        echo         
        echo     except KeyboardInterrupt:
        echo         print("\\n\\n🛑 Server stopped by user"^)
        echo     except Exception as e:
        echo         print(f"\\n❌ Server error: {e}"^)
        echo     finally:
        echo         print("👋 Thank you for using AR Aisle Assistant!"^)
        echo         input("Press Enter to exit..."^)
    ) > server.py
    echo ✓ Server created
) else (
    echo ✓ Server already exists
)

:: Create requirements.txt if it doesn't exist
if not exist "requirements.txt" (
    echo Creating requirements.txt...
    (
        echo qrcode[pil]^>=7.4.2
        echo Pillow^>=9.0.0
        echo cryptography^>=3.0.0
        echo requests^>=2.25.0
    ) > requirements.txt
    echo ✓ Requirements file created
)
echo.

:: Start the server
echo [6/6] Starting AR Aisle Assistant...
echo.
echo ========================================
echo   🚀 LAUNCHING AR AISLE ASSISTANT 🚀
echo ========================================
echo.
echo 📋 What this does:
echo   • Starts a local web server
echo   • Generates QR code for mobile access
echo   • Opens the app in your default browser
echo   • Enables AR camera features (HTTPS)
echo.
echo 📱 For mobile use:
echo   • Scan the QR code with your phone
echo   • Allow camera permissions when prompted
echo   • Enjoy full AR navigation features!
echo.
echo 🛑 To stop the server: Press Ctrl+C
echo.

:: Final check for HTML file
if not exist "ar_aisle_assistant.html" (
    echo ❌ CRITICAL ERROR: ar_aisle_assistant.html not found!
    echo.
    echo This file is required for the AR Aisle Assistant to work.
    echo Please make sure you have the complete project files:
    echo   • ar_aisle_assistant.html
    echo   • server.py
    echo   • setup_and_run.bat (this file)
    echo.
    pause
    exit /b 1
)

:: Start the Python server
python server.py

:: If we get here, the server has stopped
echo.
echo ========================================
echo        🏁 SESSION COMPLETE 🏁
echo ========================================
echo.
echo Thank you for using AR Aisle Assistant!
echo.
pause
