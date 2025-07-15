#!/bin/bash

echo "🚀 Starting AR Aisle Assistant Server..."
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    echo "💡 Please install Python 3 first"
    exit 1
fi

# Install required packages
echo "📦 Installing required packages..."
pip3 install qrcode[pil] cryptography

# Start the server
echo
echo "🎯 Starting AR Aisle Assistant Server..."
python3 server.py
