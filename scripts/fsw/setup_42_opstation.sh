#!/bin/bash
#
# Prepare the 42 opstation client configs without launching.
# Call this from 'make deploy-opstation' or manually before the student clicks the icon.
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

SAT_HOST="${SAT_IP:-10.10.10.10}"
GFX_PORT="${FORTY_TWO_GFX_PORT:-10001}"
INOUT_DIR="$USER_NOS3_DIR/42/NOS3InOutGfx"

if [ ! -d "$BASE_DIR/cfg/build/InOut" ]; then
    echo "ERROR: Need to run 'make config' first."
    exit 1
fi
if [ ! -x "$USER_NOS3_DIR/42/42" ]; then
    echo "ERROR: Need to run 'make prep' first (builds 42 under ~/.nos3/42)."
    exit 1
fi

echo "Preparing 42 opstation client configs (Rx → ${SAT_HOST}:${GFX_PORT}) ..."
rm -rf "$INOUT_DIR"
cp -r "$BASE_DIR/cfg/build/InOut" "$INOUT_DIR"

# Graphics on
sed -i 's/FALSE.*Graphics Front End/TRUE                            !  Graphics Front End/' \
    "$INOUT_DIR/Inp_Sim.txt" 2>/dev/null || true

# IPC: single RX CLIENT socket pointing at satellite
sed "s/__SAT_IP__/${SAT_HOST}/g" "$BASE_DIR/cfg/InOut/opstation/Inp_IPC.txt" > "$INOUT_DIR/Inp_IPC.txt"

# NOS3 time config
sed "s/__SAT_IP__/${SAT_HOST}/g" "$BASE_DIR/cfg/InOut/opstation/Inp_NOS3.txt" > "$INOUT_DIR/Inp_NOS3.txt"

# Install desktop launcher from repo asset
DESKTOP_DIR="$HOME/Desktop"
LAUNCHER="$DESKTOP_DIR/42.desktop"

mkdir -p "$DESKTOP_DIR"
sed "s|__BASE_DIR__|${BASE_DIR}|g" "$BASE_DIR/opstation/assets/42.desktop" > "$LAUNCHER"
chmod +x "$LAUNCHER" 2>/dev/null || true
# Make GNOME trust the launcher (Ubuntu/DCV)
gio set "$LAUNCHER" metadata::trusted true 2>/dev/null || true

# Install utility scripts as desktop shortcuts and to application menu
echo "Installing utility desktop shortcuts..."

APP_DIR="$HOME/.local/share/applications"
mkdir -p "$APP_DIR"

for script in hack_groundstation unhack_groundstation restart-satellite stop_42; do
    NICE_NAME=$(echo $script | tr '_-' '  ' | sed 's/\b\(.\)/\u\1/g')
    DESKTOP_FILE="nos3-${script}.desktop"

    cat > "$APP_DIR/$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=$NICE_NAME
Exec=$BASE_DIR/opstation/scripts/${script}.sh
Icon=$BASE_DIR/opstation/assets/${script}.png
Terminal=true
Categories=Utility;
EOF

    # Also copy to Desktop
    cp "$APP_DIR/$DESKTOP_FILE" "$DESKTOP_DIR/$DESKTOP_FILE"
    chmod +x "$DESKTOP_DIR/$DESKTOP_FILE"
    gio set "$DESKTOP_DIR/$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
done

# Pin to GNOME dock/favorites
echo "Pinning apps to dock..."

# Copy 42 and Holodeck desktop files to applications dir for dock access
cp "$DESKTOP_DIR/42.desktop" "$APP_DIR/nos3-42.desktop" 2>/dev/null || true
cp "$DESKTOP_DIR/holodeck.desktop" "$APP_DIR/nos3-holodeck.desktop" 2>/dev/null || true

gsettings set org.gnome.shell favorite-apps \
    "['nos3-42.desktop', 'nos3-holodeck.desktop', 'nos3-hack_groundstation.desktop', 'nos3-unhack_groundstation.desktop', 'nos3-restart-satellite.desktop', 'nos3-stop_42.desktop']" 2>/dev/null || true

# Set desktop wallpaper
WALLPAPER="$BASE_DIR/opstation/assets/background.png"
if [ -f "$WALLPAPER" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-options 'stretched' 2>/dev/null || true
fi

# Install SSH config
echo "Installing SSH config..."
mkdir -p "$HOME/.ssh"
cat > "$HOME/.ssh/config" << 'EOF'
Host groundstation
    User ubuntu
    Hostname 10.10.20.10

Host satellite
    User ubuntu
    Hostname 10.10.10.10
EOF
chmod 600 "$HOME/.ssh/config"

# Deploy tools directory to Desktop
echo "Installing attack tools to Desktop..."
rm -rf "$DESKTOP_DIR/tools"
cp -r "$BASE_DIR/opstation/tools" "$DESKTOP_DIR/tools"

echo "Setup complete."
echo "  Config:    $INOUT_DIR"
echo "  Launcher:  $LAUNCHER"
echo "  Students can click '42 Satellite Viewer' on the desktop or run:"
echo "    make start-42-opstation"
