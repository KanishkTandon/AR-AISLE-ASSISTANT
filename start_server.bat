@echo off
echo 🚀 Starting AR Aisle Assistant Server...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo 💡 Please install Python from https://python.org
    pause
    exit /b 1
)

REM Install required packages
echo 📦 Installing required packages...
pip install qrcode[pil] cryptography

REM Start the server
echo.
echo 🎯 Starting AR Aisle Assistant Server...
python server.py

pause
