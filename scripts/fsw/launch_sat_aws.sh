#!/bin/bash
#
# AWS / headless satellite-side NOS3 launch (no GSW, no gnome-terminal).
# Publishes UDP/TCP ports on the host for split-host OpenC3 at GSW_IP.
#
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../env.sh"

D_AUTOSTART="${D_AUTOSTART:---restart unless-stopped}"
DCALL_RUN="$DCALL run -dit"

if [ ! -d "$USER_NOS3_DIR" ]; then
    echo "Need to run make prep first!"
    exit 1
fi
if [ ! -d "$BASE_DIR/cfg/build" ]; then
    echo "Need to run make config first!"
    exit 1
fi

echo "Make data folders..."
mkdir -p $FSW_DIR/data/{cam,evs,hk,inst}
touch $FSW_DIR/data/dummy.txt
echo "1234567890" > $FSW_DIR/data/dummy.txt
truncate -s 1M $FSW_DIR/data/dummy.txt 2>/dev/null || true
mkdir -p /tmp/nos3/{data/{cam,evs,hk,inst},uplink}
cp $BASE_DIR/fsw/build/exe/cpu1/cf/cfe_es_startup.scr /tmp/nos3/uplink/tmp0.so 2>/dev/null
cp $BASE_DIR/fsw/build/exe/cpu1/cf/sample.so /tmp/nos3/uplink/tmp1.so 2>/dev/null

echo "Create ground network nos3-core..."
$DNETWORK rm nos3-core 2>/dev/null || true
$DNETWORK create --driver=bridge --subnet=192.168.41.0/24 --gateway=192.168.41.1 nos3-core

export GND_CFG_FILE="-f nos3-simulator.xml"
$DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name nos-terminal --network=nos3-core \
    -w $SIM_BIN $DBOX ./nos3-single-simulator $GND_CFG_FILE stdio-terminal
$DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name nos-udp-terminal --network=nos3-core \
    -w $SIM_BIN $DBOX ./nos3-single-simulator $GND_CFG_FILE udp-terminal
$DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name nos-sim-bridge --network=nos3-core \
    -w $SIM_BIN $DBOX ./nos3-sim-cmdbus-bridge $GND_CFG_FILE

export SATNUM=1
for (( i=1; i<=$SATNUM; i++ )); do
    export SC_NUM="sc0"$i
    export SC_NETNAME="nos3-"$SC_NUM
    export SC_CFG_FILE="-f nos3-simulator.xml"

    $DNETWORK rm $SC_NETNAME 2>/dev/null || true
    $DNETWORK create $SC_NETNAME

    echo "$SC_NUM - NOS engine (time bus before sims / 42 IPC)..."
    cd $SIM_BIN
    $DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name ${SC_NUM}-nos-engine-server \
        -h nos-engine-server --network=$SC_NETNAME \
        -p 12001:12001/tcp \
        -w $SIM_BIN $DBOX \
        /usr/bin/nos_engine_server_standalone -f $SIM_BIN/nos_engine_server_config.json

    echo "$SC_NUM - 42 (headless engine; TCP 10001 published for opstation graphics)..."
    rm -rf $USER_NOS3_DIR/42/NOS3InOut
    cp -r $BASE_DIR/cfg/build/InOut $USER_NOS3_DIR/42/NOS3InOut
    sed -i 's/TRUE.*Graphics Front End/FALSE                            !  Graphics Front End/' \
        $USER_NOS3_DIR/42/NOS3InOut/Inp_Sim.txt 2>/dev/null || true
    $DCALL_RUN $D_AUTOSTART -v $USER_NOS3_DIR:$USER_NOS3_DIR --name ${SC_NUM}-fortytwo -h fortytwo \
        --network=$SC_NETNAME --network-alias=fortytwo \
        --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
        -p ${FORTY_TWO_GFX_PORT:-10001}:10001/tcp -w $USER_NOS3_DIR/42 -t $DBOX \
        $USER_NOS3_DIR/42/42 NOS3InOut
    echo "$SC_NUM - waiting for fortytwo container..."
    for _w in $(seq 1 30); do
        if $DCALL inspect -f '{{.State.Running}}' ${SC_NUM}-fortytwo 2>/dev/null | grep -q true; then
            break
        fi
        sleep 1
    done
    if ! $DCALL inspect -f '{{.State.Running}}' ${SC_NUM}-fortytwo 2>/dev/null | grep -q true; then
        echo "ERROR: ${SC_NUM}-fortytwo is not running. Check: docker logs ${SC_NUM}-fortytwo"
        exit 1
    fi

    echo "$SC_NUM - Flight Software..."
    $DCALL_RUN $D_AUTOSTART -v $BASE_DIR:$BASE_DIR --name ${SC_NUM}-nos-fsw -h nos-fsw \
        --network=$SC_NETNAME -w $FSW_DIR -p 5012:5012/udp -p 5013:5013/udp \
        --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice \
        $DBOX $SCRIPT_DIR/fsw/fsw_respawn.sh

    echo "$SC_NUM - CryptoLib..."
    $DCALL_RUN $D_AUTOSTART -v $BASE_DIR:$BASE_DIR --name ${SC_NUM}-cryptolib \
        --network=$SC_NETNAME --network-alias=cryptolib \
        -p 6010:6010/udp -p 6011:6011/udp \
        -w $BASE_DIR/gsw/build $DBOX ./support/standalone

    echo "$SC_NUM - Simulators..."
    cd $SIM_BIN

    $DCALL_RUN -v $SIM_DIR:$SIM_DIR --name ${SC_NUM}-truth42sim -h truth42sim \
        --network=$SC_NETNAME -p 5110:5110/udp -p 5111:5111/udp \
        -w $SIM_BIN $DBOX ./nos3-single-simulator $SC_CFG_FILE truth42sim

    $DNETWORK connect $SC_NETNAME nos-terminal
    $DNETWORK connect $SC_NETNAME nos-udp-terminal
    $DNETWORK connect $SC_NETNAME nos-sim-bridge

    echo "$SC_NUM - reaction wheel 0 (first SERVER port 4278 in Inp_IPC)..."
    $DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name ${SC_NUM}_generic-reactionwheel-sim0 \
        --network=$SC_NETNAME -w $SIM_BIN $DBOX \
        ./nos3-single-simulator $SC_CFG_FILE generic-reactionwheel-sim0

    for sim in \
        camsim generic-css-sim generic-eps-sim generic-fss-sim \
        gps generic-imu-sim generic-mag-sim \
        generic-reactionwheel-sim1 generic-reactionwheel-sim2 \
        generic-radio-sim sample-sim generic-star-tracker-sim generic-thruster-sim generic-torquer-sim; do
        if [[ "$sim" == "generic-radio-sim" ]]; then
            $DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name ${SC_NUM}-${sim} \
                -h radio-sim --network-alias=radio-sim --network=$SC_NETNAME \
                -w $SIM_BIN $DBOX ./nos3-single-simulator $SC_CFG_FILE $sim
        elif [[ "$sim" == generic-reactionwheel-sim0 ]]; then
            continue
        else
            $DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name ${SC_NUM}_${sim} \
                --network=$SC_NETNAME -w $SIM_BIN $DBOX \
                ./nos3-single-simulator $SC_CFG_FILE $sim
        fi
    done
done

echo "NOS Time Driver..."
sleep 5
$DCALL_RUN $D_AUTOSTART -v $SIM_DIR:$SIM_DIR --name nos-time-driver --network=nos3-core \
    -w $SIM_BIN $DBOX ./nos3-single-simulator $GND_CFG_FILE time
for (( i=1; i<=$SATNUM; i++ )); do
    export SC_NETNAME="nos3-sc0"$i
    $DNETWORK connect --alias nos-time-driver $SC_NETNAME nos-time-driver
done

echo "AWS satellite launch complete (published: 5012/5013, 6010/6011, 5110/5111, 42-gfx 10001)."
