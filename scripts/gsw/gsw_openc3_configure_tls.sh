#!/bin/bash
#
# Configure cloned OpenC3 stack for HTTPS on port 443 with a self-signed certificate.
# Run from gsw_openc3_build.sh after openc3-nos3 is cloned to OPENC3_DIR.
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

GSW_IP="${GSW_IP:-10.10.20.10}"
TRAEFIK_DIR="$OPENC3_DIR/openc3-traefik"
COMPOSE_FILE="$OPENC3_DIR/compose.yaml"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "ERROR: $COMPOSE_FILE not found; clone openc3-nos3 first (make gsw)."
    exit 1
fi

mkdir -p "$TRAEFIK_DIR"
cd "$TRAEFIK_DIR"

if [ ! -f cert.crt ] || [ ! -f cert.key ]; then
    echo "Generating self-signed certificate for $GSW_IP ..."
    openssl req -x509 -newkey rsa:2048 -keyout cert.key -out cert.crt -days 365 -nodes \
        -subj "/CN=$GSW_IP" -addext "subjectAltName=IP:$GSW_IP" 2>/dev/null \
        || openssl req -x509 -newkey rsa:2048 -keyout cert.key -out cert.crt -days 365 -nodes \
        -subj "/CN=$GSW_IP"
fi

if [ -f "$OPENC3_DIR/cacert.pem" ]; then
    if ! grep -qF "$(openssl x509 -in cert.crt 2>/dev/null)" "$OPENC3_DIR/cacert.pem" 2>/dev/null; then
        echo "Appending self-signed cert to cacert.pem ..."
        cat cert.crt >> "$OPENC3_DIR/cacert.pem"
    fi
fi

if [ -f traefik-ssl.yaml ]; then
    sed -i "s/mydomain.com/$GSW_IP/g" traefik-ssl.yaml 2>/dev/null || true
    # Fix cable WebSocket ports for OpenC3 6.0.1 (cable runs on same port as API)
    sed -i 's|http://openc3-cosmos-cmd-tlm-api:3901|http://openc3-cosmos-cmd-tlm-api:2901|g' traefik-ssl.yaml
    sed -i 's|http://openc3-cosmos-script-runner-api:3902|http://openc3-cosmos-script-runner-api:2902|g' traefik-ssl.yaml
fi

echo "Patching compose.yaml for TLS on 443 (openc3-nos3 layout) ..."
python3 - "$COMPOSE_FILE" <<'PY'
import re
import sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().splitlines(keepends=True)
service = None
out = []
has_https_port = False

def comment_line(line: str) -> str:
    stripped = line.lstrip()
    if stripped.startswith("#"):
        return line
    indent = line[: len(line) - len(stripped)]
    return f"{indent}# {stripped}"

def uncomment_line(line: str) -> str:
    m = re.match(r"^(\s*)#\s*-?\s*(.*)$", line)
    if m:
        return f"{m.group(1)}- {m.group(2)}\n"
    return line

for line in lines:
    sm = re.match(r"^  ([\w-]+):\s*$", line)
    if sm:
        service = sm.group(1)

    if service == "openc3-operator":
        line = line.replace("127.0.0.1:5013:5013", "0.0.0.0:5013:5013")
        line = line.replace("127.0.0.1:6011:6011", "0.0.0.0:6011:6011")
        line = line.replace("127.0.0.1:5111:5111", "0.0.0.0:5111:5111")

    if service == "openc3-traefik":
        if "./openc3-traefik/traefik.yaml:/etc/traefik/traefik.yaml" in line and not line.lstrip().startswith("#"):
            line = comment_line(line)
        if "./openc3-traefik/traefik-ssl.yaml:/etc/traefik/traefik.yaml" in line:
            if line.lstrip().startswith("#"):
                line = uncomment_line(line)
        if "./openc3-traefik/cert.key:/etc/traefik/cert.key" in line:
            if line.lstrip().startswith("#"):
                line = uncomment_line(line)
        if "./openc3-traefik/cert.crt:/etc/traefik/cert.crt" in line:
            if line.lstrip().startswith("#"):
                line = uncomment_line(line)

        if re.search(r"127\.0\.0\.1:2900:2900", line) and not line.lstrip().startswith("#"):
            line = comment_line(line)
        if re.search(r"127\.0\.0\.1:2943:2943", line) and not line.lstrip().startswith("#"):
            line = comment_line(line)

        if re.search(r"0\.0\.0\.0:443:2943", line) and not line.lstrip().startswith("#"):
            has_https_port = True
        if re.search(r'#\s*-\s*"?443:2943"?', line):
            indent = re.match(r"^(\s*)", line).group(1)
            line = f'{indent}- "0.0.0.0:443:2943"\n'
            has_https_port = True

    out.append(line)

if not has_https_port:
    patched = []
    service = None
    inserted = False
    for line in out:
        sm = re.match(r"^  ([\w-]+):\s*$", line)
        if sm:
            service = sm.group(1)
        if not inserted and service == "openc3-traefik" and re.match(r"^\s*ports:\s*$", line):
            patched.append(line)
            indent = re.match(r"^(\s*)", line).group(1) + "  "
            patched.append(f'{indent}- "0.0.0.0:443:2943"\n')
            inserted = True
            has_https_port = True
            continue
        patched.append(line)
    out = patched

text = "".join(out)
open(path, "w").write(text)

if "0.0.0.0:443:2943" not in text:
    print("ERROR: failed to add 0.0.0.0:443:2943 to openc3-traefik ports", file=sys.stderr)
    sys.exit(1)
if "./openc3-traefik/traefik-ssl.yaml:/etc/traefik/traefik.yaml" not in text.replace("#", ""):
    print("ERROR: traefik-ssl.yaml not enabled in compose.yaml", file=sys.stderr)
    sys.exit(1)
if "0.0.0.0:5013:5013" not in text:
    print("ERROR: openc3-operator UDP ports not set to 0.0.0.0", file=sys.stderr)
    sys.exit(1)
PY

if ! grep -qE '0\.0\.0\.0:443:2943' "$COMPOSE_FILE"; then
    echo "ERROR: compose.yaml missing HTTPS port binding after patch."
    exit 1
fi
if grep -qE '^\s+- "127\.0\.0\.1:2943:2943"' "$COMPOSE_FILE"; then
    echo "ERROR: compose.yaml still exposes 127.0.0.1:2943 (patch incomplete)."
    exit 1
fi

echo "OpenC3 TLS configuration complete (https://$GSW_IP/)."
echo "  Verified: 0.0.0.0:443:2943, traefik-ssl.yaml, operator UDP on 0.0.0.0"
