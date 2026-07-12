# AWS operator station (42 visualization)

DCV desktop on **10.10.20.20** runs a **42 graphics client** that displays state streamed from the **42 engine** on the satellite (**10.10.10.10**).

This uses the upstream **Tx/Rx** pattern from [nasa-itc/42](https://github.com/nasa-itc/42) (`nos3-main`): the satellite engine transmits on a dedicated socket; the opstation receives and renders with the graphics front end enabled.

| Role | IP | 42 role |
|------|-----|---------|
| Satellite | `10.10.10.10` | **Tx** — simulation engine, graphics off, TCP **10001** published |
| Operator | `10.10.20.20` | **Rx** — graphics on, TCP **client** to `10.10.10.10:10001` |

Port **9999** remains **inside** the satellite Docker network for `truth42sim` (OpenC3 SIM_42_TRUTH). It is not used for the opstation GUI.

## Prerequisites

- NOS3 repo on the opstation (same commit as satellite is recommended)
- **DCV** (or other) session with a working `DISPLAY`
- Docker; outbound pull for `ivvitc/nos3-64:20251107`
- Security group: **opstation → satellite TCP 10001**
- Satellite stack running (`make start-sat-aws` on `10.10.10.10`) after `make config` with `<deploy>aws</deploy>`

## One-time setup on opstation

```bash
cd /root/nos3   # path to this repository

mkdir -p ~/.nos3
docker pull ivvitc/nos3-64:20251107

make prep
make config
export SAT_IP=10.10.10.10
```

`make config` is required so `cfg/build/InOut` matches the mission (orbits, spacecraft, graphics file). You do **not** need `make fsw`, `make sim`, or CryptoLib on the opstation.

## Launch visualization

From a **DCV desktop terminal** (verify `echo $DISPLAY` is set):

```bash
cd /root/nos3
export SAT_IP=10.10.10.10
./scripts/fsw/launch_42_opstation.sh
```

You should see the usual 42 map/camera windows updating as the satellite simulation runs.

## Verify connectivity

On the opstation:

```bash
nc -zv 10.10.10.10 10001
```

On the satellite:

```bash
docker ps | grep fortytwo
ss -lntp | grep 10001
```

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `DISPLAY is not set` | Not in DCV/X11 session |
| Connection refused on 10001 | Satellite not up, SG blocks TCP 10001, or `make config` without `deploy=aws` (no graphics IPC block) |
| Black / frozen display | 42 engine not stepping (satellite sims down); restart satellite stack |
| Display worked, then died after closing client | Stock 42 accepts **one** client per IPC port; restart `sc01-fortytwo` on the satellite, then relaunch the opstation client |

## Stop

Exit the 42 GUI or `docker stop nos3-42-opstation-gfx`. To free the satellite graphics socket, restart the fortytwo container on the satellite:

```bash
docker restart sc01-fortytwo
```

## Related

- Satellite: [AWS_SAT_DEPLOY.md](./AWS_SAT_DEPLOY.md)
- Ground station: [AWS_GSW_DEPLOY.md](./AWS_GSW_DEPLOY.md)
