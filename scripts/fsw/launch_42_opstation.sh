#!/bin/bash
#
# Operator station: 42 graphics client (Rx) → satellite 42 engine (Tx on TCP 10001).
# Run from a DCV desktop session on the opstation host with DISPLAY set.
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

SAT_HOST="${SAT_IP:-10.10.10.10}"
GFX_PORT="${FORTY_TWO_GFX_PORT:-10001}"
INOUT_DIR="$USER_NOS3_DIR/42/NOS3InOutGfx"

if [ -z "${DISPLAY:-}" ]; then
    echo "DISPLAY is not set. Connect via DCV (or X11) before launching 42 graphics."
    exit 1
fi
if [ ! -d "$BASE_DIR/cfg/build/InOut" ]; then
    echo "Need to run 'make config' in the NOS3 repo first."
    exit 1
fi
if [ ! -x "$USER_NOS3_DIR/42/42" ]; then
    echo "Need to run 'make prep' first (builds 42 under ~/.nos3/42)."
    exit 1
fi

echo "Prepare 42 graphics client InOut (Rx → ${SAT_HOST}:${GFX_PORT}) ..."
rm -rf "$INOUT_DIR"
cp -r "$BASE_DIR/cfg/build/InOut" "$INOUT_DIR"

# Remote display client: graphics on
sed -i 's/FALSE.*Graphics Front End/TRUE                            !  Graphics Front End/' \
    "$INOUT_DIR/Inp_Sim.txt" 2>/dev/null || true

# IPC: single RX CLIENT socket pointing at satellite
sed "s/__SAT_IP__/${SAT_HOST}/g" "$BASE_DIR/cfg/InOut/opstation/Inp_IPC.txt" > "$INOUT_DIR/Inp_IPC.txt"

# NOS3 time config: point at satellite's NOS Engine server
sed "s/__SAT_IP__/${SAT_HOST}/g" "$BASE_DIR/cfg/InOut/opstation/Inp_NOS3.txt" > "$INOUT_DIR/Inp_NOS3.txt"

echo "Launch 42 graphics (close the window to exit) ..."
cd "$USER_NOS3_DIR/42"
xhost +local: 2>/dev/null || true
docker run --rm \
    -e DISPLAY="$DISPLAY" \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -u "$(id -u):$(id -g)" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v "$USER_NOS3_DIR:$USER_NOS3_DIR" \
    -w "$USER_NOS3_DIR/42" \
    --name nos3-42-opstation-gfx \
    -t "$DBOX" \
    "$USER_NOS3_DIR/42/42" NOS3InOutGfx
