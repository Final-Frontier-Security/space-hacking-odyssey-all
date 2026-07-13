#!/bin/bash
#
# Setup Holodeck - installs dependencies and configures for launch
# Run once during deploy-opstation. Requires sudo for CAP_NET_RAW.
#
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

echo "Setting up Holodeck..."

# --- Backend ---
echo "  Installing Python backend dependencies..."
cd "$SCRIPT_DIR/backend/app"

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install -q -r ../requirements.txt

# Grant raw socket capability for cloaking device (scapy)
PYTHON_BIN=$(readlink -f venv/bin/python3)
if ! getcap "$PYTHON_BIN" 2>/dev/null | grep -q cap_net_raw; then
    echo "  Setting CAP_NET_RAW on Python (requires sudo)..."
    sudo setcap cap_net_raw+ep "$PYTHON_BIN"
fi

# Initialize the database
python3 setup-db.py

deactivate

# --- Frontend ---
echo "  Installing Node.js frontend dependencies..."
cd "$SCRIPT_DIR/frontend"
npm install --silent

# --- Desktop launcher ---
echo "  Installing Holodeck desktop launcher..."
DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/holodeck.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Holodeck
Comment=Space Vehicle Attack Simulation Tool
Exec=$SCRIPT_DIR/start-holodeck.sh
Icon=$BASE_DIR/opstation/assets/holodeck.png
Terminal=false
Categories=Development;Education;
EOF
chmod +x "$DESKTOP_DIR/holodeck.desktop"
gio set "$DESKTOP_DIR/holodeck.desktop" metadata::trusted true 2>/dev/null || true

echo "Holodeck setup complete."
echo "  Launch: click 'Holodeck' on desktop or run $SCRIPT_DIR/start-holodeck.sh"
