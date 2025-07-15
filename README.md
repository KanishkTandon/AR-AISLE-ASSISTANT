# AR Aisle Assistant Server

## 🚀 Quick Start

### For Windows:
1. Double-click `start_server.bat`
2. The server will start automatically
3. A QR code will be generated and displayed
4. Scan the QR code with your mobile device

### For macOS/Linux:
1. Open Terminal in this folder
2. Run: `chmod +x start_server.sh`
3. Run: `./start_server.sh`
4. Scan the generated QR code with your mobile device

### Manual Start:
```bash
python server.py
```

## 📱 Mobile Access

1. **Scan the QR Code** that appears in your terminal
2. **Accept Security Warning** (for HTTPS self-signed certificate)
3. **Allow Camera Permission** when prompted
4. **Start Shopping** with AR navigation!

## 🔧 Technical Details

- **HTTPS Port**: 8443 (for camera access)
- **HTTP Fallback**: 8080
- **QR Code**: Saved as `ar_assistant_qr.png`
- **SSL Certificate**: Auto-generated for HTTPS

## 📋 Requirements

- Python 3.6+
- qrcode[pil]
- cryptography

## 🛠️ Troubleshooting

### Camera Not Working?
- Use HTTPS (port 8443) not HTTP
- Accept the security certificate warning
- Grant camera permissions in browser

### Can't Connect?
- Check firewall settings
- Ensure devices are on same WiFi network
- Try the IP address directly

### Server Won't Start?
- Check if ports 8443/8080 are available
- Run as administrator (Windows) or with sudo (Linux/Mac)
- Install Python dependencies

## 🌐 URLs

After starting the server, access via:
- **HTTPS**: `https://YOUR_IP:8443/ar_aisle_assistant.html`
- **HTTP**: `http://YOUR_IP:8080/ar_aisle_assistant.html`

## 🔒 Security Note

The server uses a self-signed SSL certificate for HTTPS access. This is required for camera functionality on mobile devices. You'll see a security warning - this is normal and safe for local development.

## 📞 Support

If you encounter issues:
1. Check the console output for error messages
2. Ensure Python and dependencies are installed
3. Verify network connectivity
4. Check firewall settings
