@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Walmart AR Aisle Assistant Setup
echo ========================================
echo.

:: Set Python path
set PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python311\python.exe
set PIP_PATH=%LOCALAPPDATA%\Programs\Python\Python311\Scripts\pip.exe

:: Check if Python is installed
echo [1/5] Checking Python installation...
if exist "%PYTHON_PATH%" (
    "%PYTHON_PATH%" --version
    echo ✓ Python found at %PYTHON_PATH%
) else (
    echo ❌ Python not found at expected location
    echo Please install Python from https://python.org or run: winget install Python.Python.3.11
    pause
    exit /b 1
)

:: Check pip
echo.
echo [2/5] Checking pip installation...
if exist "%PIP_PATH%" (
    echo ✓ pip found
) else (
    echo Installing pip...
    "%PYTHON_PATH%" -m ensurepip --upgrade
)

:: Install required packages
echo.
echo [3/5] Installing required packages...
"%PIP_PATH%" install qrcode[pil] cryptography requests
if %errorlevel% neq 0 (
    echo Warning: Some packages may have failed to install
    echo Trying alternative installation...
    "%PYTHON_PATH%" -m pip install qrcode[pil] cryptography requests
)

:: Check if HTML file exists
echo.
echo [4/5] Checking AR Aisle Assistant files...
if not exist "ar_aisle_assistant.html" (
    echo ❌ ar_aisle_assistant.html not found!
    echo Please make sure the HTML file is in the same directory.
    pause
    exit /b 1
) else (
    echo ✓ ar_aisle_assistant.html found
)

if not exist "server.py" (
    echo ❌ server.py not found!
    echo Please make sure the server.py file is in the same directory.
    pause
    exit /b 1
) else (
    echo ✓ server.py found
)

:: Start the server
echo.
echo [5/5] Starting AR Aisle Assistant...
echo.
echo ========================================
echo   🚀 LAUNCHING AR AISLE ASSISTANT 🚀
echo ========================================
echo.
echo 📱 Instructions:
echo   1. Server will start and show QR code
echo   2. Make sure your phone is on same WiFi
echo   3. Scan QR code with phone camera
echo   4. Allow camera permissions when prompted
echo   5. Enjoy AR navigation!
echo.
echo 🛑 Press Ctrl+C to stop the server
echo ========================================
echo.

:: Run the server
"%PYTHON_PATH%" server.py

echo.
echo ========================================
echo    Thanks for using AR Aisle Assistant!
echo ========================================
pause
