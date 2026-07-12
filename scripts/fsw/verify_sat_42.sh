#!/bin/bash
#
# Quick checks after make prep / make config / make start-sat-aws on the satellite.
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

SC="${1:-sc01}"
FAIL=0

echo "=== 42 patch sources (~/.nos3/42) ==="
if grep -q 'ServerListenerThread' "$USER_NOS3_DIR/42/Source/42ipc.c" 2>/dev/null; then
    echo "OK  NOS3 threaded IPC in 42ipc.c"
else
    echo "FAIL  missing ServerListenerThread (re-run make prep from updated repo)"
    FAIL=1
fi
if strings "$USER_NOS3_DIR/42/42" 2>/dev/null | grep -q 'ServerListenerThread'; then
    echo "OK  patched 42 binary"
else
    echo "FAIL  ~/.nos3/42/42 is not the patched build"
    FAIL=1
fi

echo ""
echo "=== Inp_IPC in cfg/build (standard nos3-main format) ==="
IPC="$BASE_DIR/cfg/build/InOut/Inp_IPC.txt"
if [ -f "$IPC" ]; then
    if grep -q 'AC.ID' "$IPC"; then
        echo "FAIL  $IPC still contains AC.ID lines — run make config from repo without inject"
        FAIL=1
    else
        echo "OK  no AC.ID lines in cfg/build/InOut/Inp_IPC.txt"
    fi
else
    echo "FAIL  missing $IPC (run make config)"
    FAIL=1
fi

echo ""
echo "=== launch script ==="
if grep -q 'network-alias=fortytwo' "$SCRIPT_DIR/launch_sat_aws.sh"; then
    echo "OK  launch_sat_aws.sh sets --network-alias=fortytwo"
else
    echo "FAIL  launch_sat_aws.sh missing network-alias=fortytwo"
    FAIL=1
fi

echo ""
echo "=== running containers ==="
if $DCALL inspect -f '{{.State.Running}}' "${SC}-fortytwo" 2>/dev/null | grep -q true; then
    echo "OK  ${SC}-fortytwo is running"
else
    echo "FAIL  ${SC}-fortytwo not running"
    FAIL=1
fi

echo ""
echo "=== Docker DNS (fortytwo on nos3-${SC}) ==="
NET="nos3-${SC}"
SIM="${SC}_generic-reactionwheel-sim0"
if $DCALL exec "$SIM" getent hosts fortytwo 2>/dev/null | grep -q .; then
    echo "OK  $SIM resolves fortytwo:"
    $DCALL exec "$SIM" getent hosts fortytwo
else
    echo "FAIL  $SIM cannot resolve fortytwo (alias missing or fortytwo not on $NET)"
    $DCALL network inspect "$NET" --format '{{range $k,$v := .Containers}}{{$v.Name}} {{end}}' 2>/dev/null || true
    FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "All checks passed."
else
    echo ""
    echo "One or more checks failed. See docker logs ${SC}-fortytwo"
    exit 1
fi
