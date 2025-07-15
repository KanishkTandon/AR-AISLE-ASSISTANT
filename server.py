#!/usr/bin/env python3
"""
Simple HTTP Server for AR Aisle Assistant
Hosts the HTML file with HTTPS support for camera access on mobile devices
"""

import http.server
import socketserver
import ssl
import socket
import qrcode
import webbrowser
import os
import ipaddress
import datetime
from pathlib import Path

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add headers for camera access and security
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Permissions-Policy', 'camera=*, microphone=*')
        super().end_headers()

def get_local_ip():
    """Get the local IP address of the machine"""
    try:
        # Connect to a remote server to get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"

def create_ssl_certificate():
    """Create a self-signed SSL certificate for HTTPS"""
    try:
        from cryptography import x509
        from cryptography.x509.oid import NameOID
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import rsa
        import datetime
        
        # Generate private key
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=2048,
        )
        
        # Create certificate
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Local"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Local"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "AR Assistant"),
            x509.NameAttribute(NameOID.COMMON_NAME, "localhost"),
        ])
        
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            private_key.public_key()
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.datetime.now(datetime.timezone.utc)
        ).not_valid_after(
            datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=365)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("localhost"),
                x509.IPAddress(ipaddress.IPv4Address(get_local_ip())),
            ]),
            critical=False,
        ).sign(private_key, hashes.SHA256())
        
        # Write certificate and key to files
        with open("server.crt", "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        
        with open("server.key", "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        return True
    except ImportError:
        print("⚠️  cryptography library not found. Installing...")
        os.system("pip install cryptography")
        return create_ssl_certificate()
    except Exception as e:
        print(f"❌ Could not create SSL certificate: {e}")
        return False

def generate_qr_code(url):
    """Generate QR code for the given URL"""
    try:
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(url)
        qr.make(fit=True)
        
        # Create QR code image
        img = qr.make_image(fill_color="black", back_color="white")
        img.save("ar_assistant_qr.png")
        
        # Also create ASCII QR code for terminal
        qr_ascii = qrcode.QRCode()
        qr_ascii.add_data(url)
        qr_ascii.make()
        qr_ascii.print_ascii(invert=True)
        
        return True
    except ImportError:
        print("⚠️  qrcode library not found. Installing...")
        os.system("pip install qrcode[pil]")
        return generate_qr_code(url)
    except Exception as e:
        print(f"❌ Could not generate QR code: {e}")
        return False

def main():
    # Configuration
    PORT = 8443  # HTTPS port
    HTTP_PORT = 8080  # HTTP fallback port
    
    # Get local IP
    local_ip = get_local_ip()
    
    print("🚀 Starting AR Aisle Assistant Server...")
    print("=" * 50)
    
    # Try HTTPS first (required for camera access on mobile)
    try:
        # Create SSL certificate if it doesn't exist
        if not os.path.exists("server.crt") or not os.path.exists("server.key"):
            print("🔐 Creating SSL certificate...")
            if not create_ssl_certificate():
                raise Exception("Could not create SSL certificate")
        
        # Start HTTPS server
        os.chdir(Path(__file__).parent)
        
        with socketserver.TCPServer((local_ip, PORT), CustomHTTPRequestHandler) as httpd:
            # Configure SSL
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain("server.crt", "server.key")
            httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
            
            https_url = f"https://{local_ip}:{PORT}/ar_aisle_assistant.html"
            
            print(f"✅ HTTPS Server running on: {https_url}")
            print(f"📱 Mobile Access: {https_url}")
            print()
            print("📋 QR Code for Mobile Access:")
            print("-" * 30)
            
            # Generate and display QR code
            if generate_qr_code(https_url):
                print("✅ QR code saved as 'ar_assistant_qr.png'")
                print("✅ QR code displayed above (scan with your phone)")
            
            print()
            print("📌 IMPORTANT NOTES:")
            print("• On mobile, you may see a 'Not Secure' warning")
            print("• Tap 'Advanced' → 'Proceed to site' to continue")
            print("• This is normal for self-signed certificates")
            print("• Camera access requires HTTPS")
            print()
            print("🛑 Press Ctrl+C to stop the server")
            print("=" * 50)
            
            # Try to open QR code image
            try:
                if os.path.exists("ar_assistant_qr.png"):
                    webbrowser.open("ar_assistant_qr.png")
            except:
                pass
            
            httpd.serve_forever()
            
    except Exception as e:
        print(f"❌ HTTPS server failed: {e}")
        print("🔄 Falling back to HTTP server...")
        
        # Fallback to HTTP server
        try:
            with socketserver.TCPServer((local_ip, HTTP_PORT), CustomHTTPRequestHandler) as httpd:
                http_url = f"http://{local_ip}:{HTTP_PORT}/ar_aisle_assistant.html"
                
                print(f"✅ HTTP Server running on: {http_url}")
                print(f"📱 Mobile Access: {http_url}")
                print()
                print("⚠️  WARNING: Camera may not work over HTTP on mobile devices")
                print("   Consider using HTTPS for full AR functionality")
                print()
                print("📋 QR Code for Mobile Access:")
                print("-" * 30)
                
                # Generate and display QR code
                if generate_qr_code(http_url):
                    print("✅ QR code saved as 'ar_assistant_qr.png'")
                    print("✅ QR code displayed above (scan with your phone)")
                
                print()
                print("🛑 Press Ctrl+C to stop the server")
                print("=" * 50)
                
                # Try to open QR code image
                try:
                    if os.path.exists("ar_assistant_qr.png"):
                        webbrowser.open("ar_assistant_qr.png")
                except:
                    pass
                
                httpd.serve_forever()
                
        except Exception as e:
            print(f"❌ HTTP server also failed: {e}")
            print("💡 Try running as administrator or check if ports are available")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        input("\nPress Enter to exit...")
