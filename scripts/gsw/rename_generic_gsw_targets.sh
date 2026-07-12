#!/bin/bash
#
# Rename GENERIC_* GSW target names to drop the GENERIC_ prefix for student-facing displays.
# Run from the nos3 repository root: ./scripts/gsw/rename_generic_gsw_targets.sh
#
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BASE_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

cd "$BASE_DIR"

echo "Renaming GENERIC_* strings in GSW trees (longest match first)..."
REPLACEMENTS=(
    "GENERIC_REACTION_WHEEL:REACTION_WHEEL"
    "GENERIC_STAR_TRACKER:STAR_TRACKER"
    "GENERIC_THRUSTER:THRUSTER"
    "GENERIC_TORQUER:TORQUER"
    "GENERIC_ADCS:ADCS"
    "GENERIC_RADIO:RADIO"
    "GENERIC_CSS:CSS"
    "GENERIC_EPS:EPS"
    "GENERIC_FSS:FSS"
    "GENERIC_IMU:IMU"
    "GENERIC_MAG:MAG"
    "GENERIC_RW:RW"
)

SEARCH_DIRS=(
    "components/generic_adcs/gsw"
    "components/generic_css/gsw"
    "components/generic_eps/gsw"
    "components/generic_fss/gsw"
    "components/generic_imu/gsw"
    "components/generic_mag/gsw"
    "components/generic_radio/gsw"
    "components/generic_reaction_wheel/gsw"
    "components/generic_star_tracker/gsw"
    "components/generic_thruster/gsw"
    "components/generic_torquer/gsw"
    "gsw/cosmos"
)

for pair in "${REPLACEMENTS[@]}"; do
    old="${pair%%:*}"
    new="${pair##*:}"
    echo "  $old -> $new"
    for dir in "${SEARCH_DIRS[@]}"; do
        [ -d "$dir" ] || continue
        find "$dir" -type f \( -name '*.txt' -o -name '*.rb' -o -name '*.xtce' -o -name '*.yaml' \) -print0 \
            | xargs -0 sed -i "s/${old}/${new}/g" 2>/dev/null || true
    done
done

echo "Renaming GENERIC_* directories and files under component gsw/..."
declare -A DIR_MAP=(
    [GENERIC_ADCS]=ADCS
    [GENERIC_CSS]=CSS
    [GENERIC_EPS]=EPS
    [GENERIC_FSS]=FSS
    [GENERIC_IMU]=IMU
    [GENERIC_MAG]=MAG
    [GENERIC_RADIO]=RADIO
    [GENERIC_REACTION_WHEEL]=REACTION_WHEEL
    [GENERIC_STAR_TRACKER]=STAR_TRACKER
    [GENERIC_THRUSTER]=THRUSTER
    [GENERIC_TORQUER]=TORQUER
)

for old in "${!DIR_MAP[@]}"; do
    new="${DIR_MAP[$old]}"
    find components -type d -name "$old" -path '*/gsw/*' | sort -r | while read -r d; do
        parent=$(dirname "$d")
        if [ -d "$parent/$new" ]; then
            echo "WARN: $parent/$new already exists; skipping $d"
            continue
        fi
        git mv "$d" "$parent/$new" 2>/dev/null || mv "$d" "$parent/$new"
        echo "  dir: $d -> $parent/$new"
    done
done

# Rename files that still contain GENERIC_ in the filename
find components -path '*/gsw/*' \( -name 'GENERIC_*' -o -name '*GENERIC_*' \) | sort -r | while read -r f; do
    nf=$(echo "$f" | sed \
        -e 's/GENERIC_REACTION_WHEEL/REACTION_WHEEL/g' \
        -e 's/GENERIC_STAR_TRACKER/STAR_TRACKER/g' \
        -e 's/GENERIC_THRUSTER/THRUSTER/g' \
        -e 's/GENERIC_TORQUER/TORQUER/g' \
        -e 's/GENERIC_ADCS/ADCS/g' \
        -e 's/GENERIC_RADIO/RADIO/g' \
        -e 's/GENERIC_CSS/CSS/g' \
        -e 's/GENERIC_EPS/EPS/g' \
        -e 's/GENERIC_FSS/FSS/g' \
        -e 's/GENERIC_IMU/IMU/g' \
        -e 's/GENERIC_MAG/MAG/g' \
        -e 's/GENERIC_RW/RW/g')
    if [ "$f" != "$nf" ] && [ ! -e "$nf" ]; then
        git mv "$f" "$nf" 2>/dev/null || mv "$f" "$nf"
        echo "  file: $f -> $nf"
    fi
done

if [ -f gsw/cosmos/config/tools/tlm_grapher/generic_adcs.txt ]; then
    git mv gsw/cosmos/config/tools/tlm_grapher/generic_adcs.txt \
        gsw/cosmos/config/tools/tlm_grapher/adcs.txt 2>/dev/null \
        || mv gsw/cosmos/config/tools/tlm_grapher/generic_adcs.txt \
           gsw/cosmos/config/tools/tlm_grapher/adcs.txt
fi

echo "GSW GENERIC_* rename complete."
