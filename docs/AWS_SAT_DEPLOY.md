# AWS satellite deployment

Headless NOS3 on **10.10.10.10** with Docker **published ports** for split-host OpenC3 at **10.10.20.10**.

## Prerequisites

- Docker
- `git`, `make`
- Outbound internet (`make prep` clones 42; `docker pull` for `ivvitc/nos3-64:20251107`)
- Security groups: allow **inbound UDP/TCP** from GSW (`10.10.20.10`) on **5012, 5013, 6010, 6011, 5110, 5111**; **TCP 10001** from opstation (`10.10.20.20`) for 42 graphics (not 9999—that port is internal to `truth42sim`)

Use **one Linux user** for the full lifecycle on this host (`root` at `/root/nos3` is fine; do not mix `root` and another user—`~/.nos3` differs).

## One-time setup

```bash
cd /root/nos3   # path to this repository

mkdir -p ~/.nos3
docker pull ivvitc/nos3-64:20251107

make prep
make config
```

`make config` with `<deploy>aws</deploy>` and `<gsw-ip>` in `cfg/nos3-mission.xml` sets `truth42sim` **cosmos-hostname** to the GSW IP so SIM_42_TRUTH UDP reaches OpenC3.

## Build (satellite)

Do **not** use bare `make build-cryptolib` on the host unless you have installed `libgcrypt20-dev` and other build deps yourself. NOS3 expects CryptoLib to be built **inside** the `ivvitc/nos3-64` container:

```bash
make fsw
make sim
./scripts/gsw/build_cryptolib.sh
```

Verify the standalone binary (required by `launch_sat_aws.sh`):

```bash
ls -la gsw/build/support/standalone
```

| Target | Purpose |
|--------|---------|
| `make fsw` | cFS flight software (in Docker via normal NOS3 build) |
| `make sim` | Simulator binaries |
| `./scripts/gsw/build_cryptolib.sh` | CryptoLib **standalone** for UDP ports 6010/6011 (Docker) |

You do **not** need `make gsw` or `make prep-gsw` on the satellite.

## Launch

```bash
make start-sat-aws
```

Published on the satellite host:

| Port | Service |
|------|---------|
| 5012/5013 UDP | FSW debug |
| 6010/6011 UDP | CryptoLib (RADIO path to GSW) |
| 5110/5111 UDP | 42 truth sim → GSW `SIM_42_TRUTH_INT` |
| 10001 TCP | 42 state stream for opstation graphics (`truth42sim` uses 9999 inside Docker only) |

## Verify

```bash
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E 'sc01|nos-'
```

Expect containers such as `sc01-nos-fsw`, `sc01-cryptolib`, `sc01-fortytwo`, `sc01-truth42sim`, and simulators. CryptoLib should show `0.0.0.0:6010-6011->.../udp`.

From the GSW, OpenC3 **RADIO** and **SIM_42_TRUTH_INT** interfaces should connect once this stack is up and routing/SG rules allow UDP.

## Stop / clean relaunch

```bash
make stop
docker ps -a   # confirm NOS3 containers gone
make start-sat-aws
```

## CryptoLib build errors

**`gcrypt.h: No such file or directory`** — you ran `make build-cryptolib` on the host without dev packages. Use:

```bash
./scripts/gsw/build_cryptolib.sh
```

Or install host packages: `sudo apt-get install -y libgcrypt20-dev build-essential cmake`, then `make build-cryptolib`.

## 42 IPC startup (fortytwo stuck on a port)

NOS3 uses a **patched 42** (`patches/42-nos3-ipc`) so all SERVER sockets in `Inp_IPC.txt` listen at once instead of blocking init on one `accept()` per port. Stock 42 can miss simulators that connect in parallel and exhaust TCP retries.

After updating this repo:

```bash
make prep    # rebuild ~/.nos3/42/42 with IPC patch
make config  # regenerates Inp_IPC with AC.ID lines + AWS port 10001 graphics block
make start-sat-aws
```

`launch_sat_aws.sh` starts **nos-engine-server** before **fortytwo**, then **generic-reactionwheel-sim0** before other sims (port **4278** is the first SERVER entry in `Inp_IPC.txt`).

If sim logs show **`Temporary failure in name resolution` for host `fortytwo`**:

- The fortytwo container must be on `nos3-sc01` with **`--network-alias=fortytwo`** (see `launch_sat_aws.sh`). `-h fortytwo` alone is not enough for Docker DNS.
- Confirm 42 is still running: `docker ps | grep fortytwo` (if it exited on `Bogus input`, fix `Inp_IPC` / rebuild patched 42 first).

```bash
docker exec sc01_generic-reactionwheel-sim0 getent hosts fortytwo
```

If `docker logs sc01-fortytwo` shows **Server is listening on port N** but never accepts:

| Port (examples) | Check container |
|-----------------|-----------------|
| 4278 | `sc01_generic-reactionwheel-sim0` |
| 4245 | `sc01_gps` |
| 4234 | `sc01_generic-mag-sim` |
| 10001 | Opstation graphics client (AWS only) |

Details: [42_IPC_PATCH_REVIEW.md](./42_IPC_PATCH_REVIEW.md).

## Related

- GSW: [AWS_GSW_DEPLOY.md](./AWS_GSW_DEPLOY.md)
- Opstation 42 GUI: [AWS_OPS_DEPLOY.md](./AWS_OPS_DEPLOY.md)
