#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Setup Flask server
echo "Setting up Flask server..."
cd "$SCRIPT_DIR/backend/app"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install Flask dependencies
pip install -r ../requirements.txt

# Grant raw socket capability for cloaking device (scapy)
PYTHON_BIN=$(readlink -f venv/bin/python3)
if ! getcap "$PYTHON_BIN" 2>/dev/null | grep -q cap_net_raw; then
    echo "Setting CAP_NET_RAW on $PYTHON_BIN (requires sudo)..."
    sudo setcap cap_net_raw+ep "$PYTHON_BIN"
fi

# Run Flask server
echo "Starting Flask server..."
FLASK_APP=run.py flask run -p 5001 &

# Setup Vue frontend
echo "Setting up Vue frontend..."
cd "$SCRIPT_DIR/frontend"

# Install Vue dependencies
npm install

# Run Vue development server
echo "Starting Vue development server..."
npm run serve &

echo "Both Flask and Vue servers are running."

# Wait for Flask and Vue servers to exit
wait
