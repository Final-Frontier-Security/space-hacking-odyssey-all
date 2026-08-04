# Space Hacking Odyssey

A cybersecurity training environment built on NASA's NOS3 (NASA Operational Simulator for Small Satellites). The environment simulates a satellite, ground station, and operator station deployed across AWS EC2 instances.

## Architecture

| Component | IP Address | Instance Type | Purpose |
|-----------|-----------|---------------|---------|
| Satellite | 10.10.10.10 | c5.2xlarge | Runs cFS flight software, 42 simulator, and hardware sims |
| Ground Station | 10.10.20.10 | c5.2xlarge | Runs OpenC3 COSMOS for command and telemetry |
| Operator Station | 10.10.20.20 | c5.2xlarge | Student workstation with Holodeck UI and 42 viewer |

## Prerequisites

- AWS account
- AMIs built for each role (see Makefile targets below)
- Docker installed on all instances
- CloudFormation template deployed

## Deployment

### Satellite

```bash
ssh ubuntu@<satellite-ip>
cd /opt/space-hacking-odyssey-all
git pull
make deploy-sat
```

This runs: `prep` → `config` → `fsw` → `sim` → `build_cryptolib` → `start-sat-aws`

### Ground Station

```bash
ssh ubuntu@<groundstation-ip>
cd /opt/space-hacking-odyssey-all
git pull
make deploy-gsw
```

This runs: `config` → `gsw_build.sh` (OpenC3 plugin) → `setup_ftp` → `start-gsw-aws`

To restart after code changes:
```bash
make stop
make deploy-gsw
```

### Operator Station

```bash
ssh ubuntu@<opstation-ip>
cd /opt/space-hacking-odyssey-all
git pull
make deploy-opstation
```

This runs: clones/builds 42 in Docker → `config` → `setup_42_opstation.sh` → `setup-holodeck.sh`

## Stopping

```bash
make stop
```

## Key Directories

| Path | Description |
|------|-------------|
| `components/` | cFS apps (ADCS, sensors, CFDP, IPS, IDS, backdoor, etc.) |
| `cfg/nos3_defs/` | Flight software configuration (startup script, tables, allowlists) |
| `scripts/` | Launch, setup, and utility scripts |
| `opstation/` | Holodeck frontend/backend, desktop assets, tools |
| `gsw/cosmos/` | OpenC3 ground software config and target definitions |
| `fsw/` | cFE core, cFS apps (to_lab, ci_lab, etc.) |
| `sims/` | Hardware simulators (connect to 42) |

## Custom Components

### IPS (Intrusion Prevention System)
Monitors the ES app table for unauthorized applications. Starts unloaded — load with:
```
CFE_ES START_APP: Name=IPS, EntryPoint=IPS_AppMain, Filename=/cf/ips.so, StackSize=16384, Priority=77
```

### IDS (Intrusion Detection System)
Monitors canary files in `data/` for access and modification. Starts unloaded — load with:
```
CFE_ES START_APP: Name=IDS, EntryPoint=IDS_AppMain, Filename=/cf/ids.so, StackSize=16384, Priority=78
```

Canary file list: `cfg/nos3_defs/files.txt`

### CFDP (File Transfer)
Custom file upload/download between ground and satellite. Microservice runs in OpenC3.

### Backdoor
Demonstration malicious app. Not compiled with the satellite — pre-built `.so` uploaded via CFDP during labs.

## Telemetry Flow

1. cFS apps publish telemetry to the software bus
2. TO_LAB subscribes and sends UDP packets to ground station
3. OpenC3 receives packets on configured interface ports
4. Students view telemetry in OpenC3 web UI

TO output must be enabled after boot:
```
TO_DEBUG ENABLE_OUTPUT with DEST_IP '<groundstation-ip>', DEST_PORT 5013
```

## Sensor Initialization

All sensors start disabled. Enable them after boot.