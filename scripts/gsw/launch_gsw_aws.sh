#!/bin/bash
#
# AWS / headless GSW-only launch: OpenC3 stack (HTTPS :443 configured by make gsw).
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

if [ ! -d "$OPENC3_DIR" ]; then
    echo "Need to run make gsw first!"
    exit 1
fi

echo "Start OpenC3 (https://${GSW_IP:-10.10.20.10}/) ..."
cd "$OPENC3_DIR"
$OPENC3_PATH run
echo "OpenC3 GSW launch complete."
