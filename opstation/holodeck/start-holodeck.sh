#!/bin/bash
#
# Holodeck launcher - starts backend and frontend, opens Firefox
# No terminal display during setup; uses zenity popups for status.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BACKEND="$SCRIPT_DIR/backend/app"
FRONTEND="$SCRIPT_DIR/frontend"
VENV="$BACKEND/venv"

# Check if backend or frontend is already running
FLASK_PID=$(lsof -ti :5001 2>/dev/null)
VUE_PID=$(lsof -ti :8080 2>/dev/null)

if [ -n "$FLASK_PID" ] || [ -n "$VUE_PID" ]; then
    zenity --question \
        --title="Holodeck is already running" \
        --text="Holodeck is currently running.\nDo you want to restart it?" 2>/dev/null

    if [ $? -ne 0 ]; then
        exit 0
    fi

    # Kill existing processes
    [ -n "$FLASK_PID" ] && kill -9 $FLASK_PID 2>/dev/null
    [ -n "$VUE_PID" ] && kill -9 $VUE_PID 2>/dev/null
    pkill -f "npm run serve" 2>/dev/null
    pkill -f "node.*serve" 2>/dev/null
    sleep 1
fi

# Show loading popup (non-blocking, auto-closes)
zenity --info \
    --title="Launching Holodeck" \
    --text="Setting up Holodeck...\nThe application will open shortly." \
    --timeout=5 2>/dev/null &
ZENITY_PID=$!

# --- Backend ---
cd "$BACKEND"

if [ ! -d "$VENV" ]; then
    python3 -m venv "$VENV"
fi

source "$VENV/bin/activate"
pip install -q -r ../requirements.txt > /dev/null 2>&1

# Grant raw socket capability if needed
PYTHON_BIN=$(readlink -f "$VENV/bin/python3")
if ! getcap "$PYTHON_BIN" 2>/dev/null | grep -q cap_net_raw; then
    sudo setcap cap_net_raw+ep "$PYTHON_BIN" 2>/dev/null
fi

# Database setup
export FLASK_APP=run.py
python3 "$BACKEND/setup-db.py" > /dev/null 2>&1

# Start Flask
FLASK_APP=run.py nohup flask run -p 5001 > /tmp/holodeck_flask.log 2>&1 &

deactivate

# --- Frontend ---
cd "$FRONTEND"
npm install --silent > /dev/null 2>&1
nohup npm run serve > /tmp/holodeck_vue.log 2>&1 &

# Wait for Vue to be ready
sleep 8

# Kill the zenity popup if still open
kill $ZENITY_PID 2>/dev/null

# Open Firefox
firefox http://localhost:8080 &

exit 0
