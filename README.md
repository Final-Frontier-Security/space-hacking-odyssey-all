# Space Hacking Odyssey

A cybersecurity training environment built on NASA's NOS3 (NASA Operational Simulator for Small Satellites). The environment simulates a satellite, ground station, and operator station deployed across AWS EC2 instances.

## Architecture

| Component | IP Address | Instance Type | Purpose |
|-----------|-----------|---------------|---------|
| Satellite | 10.10.10.10 | c7i.xlarge | Runs cFS flight software, 42 simulator, and hardware sims |
| Ground Station | 10.10.20.10 | c7i-flex.xlarge | Runs OpenC3 COSMOS for command and telemetry |
| Operator Station | 10.10.20.20 | c7i-flex.xlarge | Student workstation with Holodeck UI and 42 viewer |

**Cost estimate (on-demand, Linux, us-east-2):**

| Instance Type | $/hr |
|---------------|------|
| c7i.xlarge | $0.1785 |
| c7i-flex.xlarge | $0.1696 |

Total for all three instances: **~$0.52/hr** (as of August 2026, [source](https://instances.vantage.sh/)).

> **Disclaimer:** We are not responsible for any AWS costs incurred by running these instances. Monitor your usage and destroy the stack when not in use.

## Prerequisites

- AWS account
- AMIs built for each role (see Makefile targets below)
- Docker installed on all instances

There are two deployment options:

1. **Option 1 — AWS Environment Setup (CloudFormation):** Deploys the full environment automatically using a CloudFormation template. Best for quickly standing up the lab.
2. **Option 2 — Manual Deployment:** SSH into pre-provisioned instances and run make targets yourself. Use this if you already have instances running or need more control.

## Option 1 — AWS Environment Setup (CloudFormation)

If you would like to spin up your own environment in AWS, you will need the following:

* An AWS account that is not limited to the free tier (running the flight software is quite CPU intensive)
* The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed locally
* [AWS credentials configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) locally
* [git installed](https://github.com/git-guides/install-git)


### Deploying the CloudFormation Stack

```bash
# The AMI images are only publicly available in us-east-2
export AWS_DEFAULT_REGION=us-east-2

aws cloudformation deploy \
  --stack-name space-class-stack \
  --template-file file://aws/SpaceHackingOdyssey_CloudFormation.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ProjectTag=<your-project-name>
```

### Connecting to Instances

The AMIs have the public key pre-installed. Use the private key included in the repo to SSH into the operator station (the only instance with a public IP):

```bash
ssh -i aws/space_class.pem ubuntu@<opstation-public-ip>
```

### Accessing the Operator Station Desktop

The operator station runs an Amazon DCV server for graphical desktop access. You can connect via:

**Web browser:**
```
https://<opstation-public-ip>:8443
```

**DCV native client:**
Download the [Amazon DCV client](https://docs.aws.amazon.com/dcv/latest/userguide/client.html), then connect to `<opstation-public-ip>` on port `8443`.

### Destroying the Environment

We are not responsible for AWS fees incurred by the deployment of this stack. When you are finished, destroy it with:

```bash
aws cloudformation delete-stack --stack-name space-class-stack
aws cloudformation wait stack-delete-complete --stack-name space-class-stack
```

## Option 2 — Manual Deployment

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
| `aws/` | CloudFormation template, SSH key, and AWS deployment docs |
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