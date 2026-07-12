#!/bin/bash

known_ports="
8080
5001"

for port in $known_ports;
do
    port_pid=`lsof -i :$port | sed '1d' | awk '{print $2}'`
    if [ -n "${port_pid}" ];
    then
        echo "[*] Stopping PID: ${port_pid} => :${port}"
        kill $port_pid
    fi
done
