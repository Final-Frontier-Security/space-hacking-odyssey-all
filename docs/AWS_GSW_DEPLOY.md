# AWS ground station (OpenC3) deployment

Headless OpenC3 on **10.10.20.10** with HTTPS **443** and UDP interfaces bound for split-host NOS3.

Satellite host (**10.10.10.10**): see [AWS_SAT_DEPLOY.md](./AWS_SAT_DEPLOY.md).  
Operator station (**10.10.20.20**, 42 graphics): see [AWS_OPS_DEPLOY.md](./AWS_OPS_DEPLOY.md).

## Prerequisites

- Docker and Docker Compose
- `git`, `make`, `openssl`
- Outbound internet (clone `openc3-nos3`, pull images)
- Security group: inbound **TCP 443**; later outbound **UDP** to satellite `10.10.10.10`

## One-time setup on GSW host

```bash
cd /root/nos3   # path to this repository

mkdir -p ~/.nos3
docker pull ivvitc/nos3-64:20251107

make config
export GSW_IP=10.10.20.10
export SAT_IP=10.10.10.10
```

## Build and run

```bash
make gsw
```

Expect output from `gsw_openc3_configure_tls.sh`:

```text
Verified: 0.0.0.0:443:2943, traefik-ssl.yaml, operator UDP on 0.0.0.0
```

Start (if containers are not already up from `make gsw`):

```bash
make start-gsw-aws
```

## Verify

```bash
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E 'traefik|operator'
curl -k -I https://10.10.20.10/
cd ~/.nos3/openc3 && ./openc3.sh cli list
```

- Traefik: `0.0.0.0:443->2943/tcp`
- Operator: `0.0.0.0:5013/udp`, `6011/udp`, `5111/udp`
- Browser: **https://10.10.20.10/** (accept self-signed certificate)
- Admin → **Plugins**: `openc3-cosmos-nos3-1.0.*` listed (not an empty tab)

## Plugins tab empty after `make gsw`

Older NOS3 builds used `openc3.sh cli geminstall`, which only installs a Ruby gem package—it does **not** register or deploy the COSMOS plugin (targets/interfaces). Use **`cli load`** instead.

**Quick fix** (stack already running; gem already built):

```bash
cd ~/.nos3/openc3/openc3-cosmos-nos3
GEM=$(ls -1 openc3-cosmos-nos3-1.0.*.gem | tail -1)
cd ~/.nos3/openc3 && ./openc3.sh cli load "openc3-cosmos-nos3/${GEM}"
./openc3.sh cli list
```

Refresh the Admin → Plugins page. You should see `openc3-cosmos-nos3` with NOS3 targets (ADCS, EPS, CFS, etc.).

**Full rebuild** (after updating the repo and `make config`):

```bash
cd /root/nos3
export GSW_IP=10.10.20.10 SAT_IP=10.10.10.10
make gsw
```

## Replacing an old OpenC3 install

```bash
cd ~/.nos3/openc3 && ./openc3.sh stop && docker compose down
rm -rf ~/.nos3/openc3   # optional fresh clone
```

Then repeat **One-time setup** and **Build and run** with an updated NOS3 tree.

## Stop

```bash
make stop-gsw
# or: cd ~/.nos3/openc3 && ./openc3.sh stop
```
