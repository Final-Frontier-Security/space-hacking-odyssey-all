#!/bin/bash
#
# Student-facing 42 client launcher (called by desktop icon).
# Retries connection if the satellite server isn't up yet.
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

SAT_HOST="${SAT_IP:-10.10.10.10}"
GFX_PORT="${FORTY_TWO_GFX_PORT:-10001}"
INOUT_DIR="$USER_NOS3_DIR/42/NOS3InOutGfx"
LOGFILE="$USER_NOS3_DIR/42/42_client.log"
RETRY_DELAY=5
MAX_RETRIES=60

export DISPLAY="${DISPLAY:-:0}"

# Logging
exec > "$LOGFILE" 2>&1
echo "===== 42 client launch started at $(date) ====="
echo "Server: ${SAT_HOST}:${GFX_PORT}"

# Ensure X11 access
xhost +local: 2>/dev/null || true

# Remove stale container if exists
docker rm -f nos3-42-opstation-gfx 2>/dev/null || true

# Check configs exist
if [ ! -d "$INOUT_DIR" ]; then
    echo "ERROR: $INOUT_DIR not found. Run 'make deploy-opstation' first."
    notify-send "42 Error" "Configuration not found. Run 'make deploy-opstation' first." 2>/dev/null
    exit 1
fi

# Wait for satellite server to be reachable
echo "Waiting for satellite at ${SAT_HOST}:${GFX_PORT}..."
ATTEMPT=0
while ! timeout 2 bash -c "echo >/dev/tcp/${SAT_HOST}/${GFX_PORT}" 2>/dev/null; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -ge $MAX_RETRIES ]; then
        echo "ERROR: Could not reach ${SAT_HOST}:${GFX_PORT} after ${MAX_RETRIES} attempts."
        notify-send "42 Error" "Cannot reach satellite at ${SAT_HOST}:${GFX_PORT}" 2>/dev/null
        exit 1
    fi
    echo "  Attempt $ATTEMPT: server not ready, retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
done
echo "Server reachable. Launching 42..."

# Launch 42 in container
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

EXIT_CODE=$?
echo "===== 42 exited with code $EXIT_CODE at $(date) ====="

if [ $EXIT_CODE -ne 0 ]; then
    notify-send "42 Disconnected" "42 exited (code $EXIT_CODE). Click the icon to reconnect." 2>/dev/null
fi
