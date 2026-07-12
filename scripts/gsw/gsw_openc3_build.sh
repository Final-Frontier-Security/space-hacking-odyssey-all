#!/bin/bash
#
# Convenience script for NOS3 development
# Builds and deploys the OpenC3 NOS3 plugin with CFDP support
#
set -e

CFG_BUILD_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=$CFG_BUILD_DIR/../../scripts
source $SCRIPT_DIR/env.sh
export GSW="openc3-openc3-operator-1"

# Check that local NOS3 directory exists
if [ ! -d $USER_NOS3_DIR ]; then
    echo ""
    echo "ERROR: Need to run make prep first! ($USER_NOS3_DIR does not exist)"
    echo ""
    exit 1
fi

SAT_HOST="${SAT_IP:-10.10.10.10}"

echo "Prepare OpenC3 docker containers..."
cd $USER_NOS3_DIR
if [ ! -d "$OPENC3_DIR" ]; then
    git clone https://github.com/nasa-itc/openc3-nos3.git -b dev $USER_NOS3_DIR/openc3
fi

# Pin OpenC3 container release (class: 6.0.1 for vulnerability lab; 6.0.2+ is patched)
if [ -f "$BASE_DIR/cfg/gsw/openc3.env" ]; then
    echo "Applying NOS3 OpenC3 overlay from cfg/gsw/openc3.env ..."
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        key="${line%%=*}"
        if grep -q "^${key}=" "$OPENC3_DIR/.env" 2>/dev/null; then
            sed -i "s|^${key}=.*|${line}|" "$OPENC3_DIR/.env"
        else
            echo "$line" >> "$OPENC3_DIR/.env"
        fi
    done < "$BASE_DIR/cfg/gsw/openc3.env"
fi

$SCRIPT_DIR/gsw/gsw_openc3_configure_tls.sh

# Add CFDP file transfer volumes to compose.yaml (openc3-operator container)
echo "Configure CFDP file transfer volumes..."
mkdir -p "$OPENC3_DIR/send_files" "$OPENC3_DIR/received_files" "$OPENC3_DIR/microservice_logs"
COMPOSE_FILE="$OPENC3_DIR/compose.yaml"
if ! grep -q "send_files" "$COMPOSE_FILE" 2>/dev/null; then
    python3 -c "
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()
# Find openc3-operator volumes section and insert after the plugins volume line
in_operator = False
inserted = False
out = []
for i, line in enumerate(lines):
    out.append(line)
    if 'openc3-operator:' in line:
        in_operator = True
    if in_operator and not inserted and './plugins:/plugins' in line:
        indent = line[:len(line) - len(line.lstrip())]
        out.append(f'{indent}- \"./send_files:/send_files\"\n')
        out.append(f'{indent}- \"./received_files:/received_files\"\n')
        out.append(f'{indent}- \"./microservice_logs:/microservice_logs\"\n')
        inserted = True
    # Stop looking once we leave openc3-operator
    if in_operator and inserted and line.strip().startswith('openc3-') and ':' in line and 'operator' not in line:
        in_operator = False
with open(path, 'w') as f:
    f.writelines(out)
if inserted:
    print('  Added send_files, received_files, and microservice_logs volumes to compose.yaml')
else:
    print('  ERROR: Could not find insertion point in compose.yaml')
    sys.exit(1)
" "$COMPOSE_FILE"
    echo "  Verifying compose.yaml volumes..."
    grep -q "send_files" "$COMPOSE_FILE" || { echo "ERROR: send_files not in compose.yaml after patching"; exit 1; }
    grep -q "received_files" "$COMPOSE_FILE" || { echo "ERROR: received_files not in compose.yaml after patching"; exit 1; }
    grep -q "microservice_logs" "$COMPOSE_FILE" || { echo "ERROR: microservice_logs not in compose.yaml after patching"; exit 1; }
fi

$DOCKER_COMPOSE_COMMAND -f $OPENC3_DIR/compose.yaml pull
echo ""

# Check that openc3 directory exists
if [ ! -d $OPENC3_DIR ]; then
    echo ""
    echo "ERROR: OpenC3 Cloning Failed!"
    echo ""
    exit 1
fi

echo "Launch openc3 containers..."
cd $OPENC3_DIR
$OPENC3_PATH run
echo "Waiting for OpenC3 to initialize..."
sleep 20
echo ""

# Start by changing to a known location
cd $OPENC3_DIR

# Delete any previous plugin build artifacts
rm -rf openc3-cosmos-nos3
rm -rf build

# Generate the plugin scaffold
$OPENC3_CLI generate plugin nos3 --ruby
if [ ! -d "openc3-cosmos-nos3" ]; then
    echo ""
    echo "ERROR: cli generate plugin nos3 failed!"
    echo ""
    exit 1
fi

# Copy targets from components
mkdir -p openc3-cosmos-nos3/targets
cd openc3-cosmos-nos3/targets
targets=""
for i in $(find $BASE_DIR/components -name target.txt); do
    j=$(dirname $i)
    cp -r $j .
    targets="$targets $(basename $j)"
done

# Copy targets from GSW cosmos config (if directory exists)
if [ -d "$GSW_DIR/config/targets" ]; then
    for i in $(find $GSW_DIR/config/targets -name target.txt); do
        j=$(dirname $i)
        cp -r $j .
        targets="$targets $(basename $j)"
    done
fi

# Remove built-in CFDP_TEST target (conflicts with ours; our CFDP from components takes priority)
rm -rf CFDP_TEST 2>/dev/null || true

# Re-copy our CFDP target to overwrite any built-in one from $GSW_DIR
if [ -d "$BASE_DIR/components/cfdp/gsw/CFDP" ]; then
    cp -r "$BASE_DIR/components/cfdp/gsw/CFDP" .
fi

# Replace ERB template variables in target definitions
for i in $(find . -name "*.txt"); do
    sed -i -e 's/<%= CosmosCfsConfig::PROCESSOR_ENDIAN %>/LITTLE_ENDIAN/; s/<%=CF_INCOMING_PDU_MID%>/0x1800/; s/<%=CF_SPACE_TO_GND_PDU_MID%>/0x0800/;' "$i"
done
cd ..

# Copy lib (if exists)
if [ -d "$GSW_DIR/lib" ]; then
    cp -r $GSW_DIR/lib .
fi

# Create plugin.txt
echo "Create plugin..."
rm -f plugin.txt

# Rebuild the targets variable without CFDP_TEST, and deduplicate
filtered_targets=""
seen_targets=""
for i in $targets; do
    if [ "$i" != "CFDP_TEST" ]; then
        if ! echo "$seen_targets" | grep -qw "$i"; then
            filtered_targets="$filtered_targets $i"
            seen_targets="$seen_targets $i"
        fi
    fi
done
targets="$filtered_targets"

for i in $targets; do
    if [ "$i" != "SIM_42_TRUTH" -a "$i" != "SYSTEM" -a "$i" != "TO_DEBUG" -a "$i" != "CFDP" ]; then
        direct=$i
        radio=$i"_RADIO"
        echo "TARGET $i $direct" >> plugin.txt
        echo "TARGET $i $radio" >> plugin.txt
    elif [ "$i" = "CFDP" -o "$i" = "SIM_42_TRUTH" -o "$i" = "SYSTEM" -o "$i" = "TO_DEBUG" ]; then
        echo "TARGET $i $i" >> plugin.txt
    fi
done
echo "" >> plugin.txt

echo "INTERFACE DIRECT udp_interface.rb $SAT_HOST 5012 5013 nil nil 128 10.0 nil" >> plugin.txt
for i in $targets; do
    if [ "$i" != "SIM_42_TRUTH" -a "$i" != "SYSTEM" -a "$i" != "TO_DEBUG" -a "$i" != "CFDP" ]; then
        direct=$i
        echo "   MAP_TARGET $direct" >> plugin.txt
    fi
done
echo "   MAP_TARGET TO_DEBUG" >> plugin.txt
echo "   MAP_TARGET CFDP" >> plugin.txt
echo "" >> plugin.txt

echo "INTERFACE RADIO udp_interface.rb $SAT_HOST 6010 6011 nil nil 128 10.0 nil" >> plugin.txt
for i in $targets; do
    if [ "$i" != "SIM_42_TRUTH" -a "$i" != "SYSTEM" -a "$i" != "TO_DEBUG" -a "$i" != "CFDP" ]; then
        radio=$i"_RADIO"
        echo "   MAP_TARGET $radio" >> plugin.txt
    fi
done
echo "" >> plugin.txt

echo "INTERFACE SIM_42_TRUTH_INT udp_interface.rb $SAT_HOST 5110 5111 nil nil 128 10.0 nil" >> plugin.txt
echo "   MAP_TARGET SIM_42_TRUTH" >> plugin.txt

# CFDP microservice
if echo "$targets" | grep -q "CFDP"; then
    mkdir -p microservices/CFDP
    cp "$BASE_DIR/components/cfdp/gsw/CFDP/microservices/CFDP/cfdp.py" microservices/CFDP/cfdp.py
    echo "  Copied cfdp.py to microservices/CFDP/"
    echo "" >> plugin.txt
    echo "MICROSERVICE CFDP cfdp-microservice" >> plugin.txt
    echo "  CMD python cfdp.py" >> plugin.txt
    echo "  TARGET_NAME CFDP" >> plugin.txt
else
    echo "WARNING: CFDP target not found in components. Microservice will not be included."
fi

# Capture date created
echo "" >> plugin.txt
echo "# Created on $DATE" >> plugin.txt
echo ""

echo "Generated plugin.txt:"
cat plugin.txt
echo ""

# Build plugin
echo "Build plugin..."
$OPENC3_CLI rake build VERSION=1.0.$DATE
if [ ! -f "openc3-cosmos-nos3-1.0.$DATE.gem" ]; then
    echo ""
    echo "ERROR: cli rake build failed! Gem file not found."
    echo ""
    exit 1
fi
echo ""

# Load plugin
echo "Load plugin..."
cd $OPENC3_DIR/openc3-cosmos-nos3

$OPENC3_CLI load ./openc3-cosmos-nos3-1.0.$DATE.gem
INSTALL_STATUS=$?

if [ $INSTALL_STATUS -eq 0 ]; then
    echo "Plugin load successful"
else
    echo "ERROR: Plugin load failed with exit code: $INSTALL_STATUS"
    exit 1
fi
echo ""

echo "OpenC3 build script complete."
echo "Note that while this script is complete, OpenC3 is likely still processing behind the scenes!"
sleep 15
echo "Done sleeping, but check cpu use prior to proceeding!"
echo ""
