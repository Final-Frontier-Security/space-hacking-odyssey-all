# 42 IPC patch — NOS3 integration (nasa-itc/42 nos3-main)

## Reference vs implementation

Your **`42-modified`** tree showed the right *idea*: threaded `accept()` per SERVER port so NOS3 sims can connect in parallel. That tree also used a **different `Inp_IPC.txt` format** (extra AC.ID lines) and other fork-specific pieces that do **not** match current `nasa-itc/42` `nos3-main`.

The vendored overlay in [`patches/42-nos3-ipc/`](../patches/42-nos3-ipc/) is a **clean port** to nos3-main:

- **Stock** `Inp_IPC.txt` parsing (from nasa-itc `42ipc.c`)
- **Threading** from your reference (listen thread per config slot)
- **Reconnect**: release `IPC[i].Socket` on hangup; accept thread assigns next client to the same slot
- **Stock** `iokit.c` base (PpmToPsf, `h_addr_list`, etc.)

## Checklist

| # | Criterion | Result |
|---|-----------|--------|
| 1 | Init vs runtime | Init spawns listen threads; runtime uses stock `InterProcessComm` + disconnect release |
| 2 | Listen vs connected fd | Separate `listen_fd` in thread; `IPC[ConfigIipc].Socket` is the client |
| 3 | Port ordering | All SERVER ports listen before init returns; sims may connect in any order |
| 4 | Main loop before all clients | Yes — no blocking `accept()` in init loop |
| 5 | Reconnect | Yes — `IpcReleaseConnectedSocket` + accept when `Socket == 0` |
| 6 | NOS3 build | `make prep` in `ivvitc/nos3-64` |
| 7 | AWS port 10001 | Same as any other SERVER TX entry in `Inp_IPC` |
| 8 | Config format | **Must not** inject AC.ID lines; use [`cfg/InOut/Inp_IPC.txt`](../cfg/InOut/Inp_IPC.txt) |

## Recommendation

**Use this overlay** for NOS3 AWS/class deploy. Do not copy `42-modified` wholesale into `make prep`.

Optional NOS3 launch hardening (already in repo): `network-alias=fortytwo`, engine before 42, `verify_sat_42.sh`.

## Satellite deploy

```bash
cd /opt/nos3/nos3
make stop
rm -rf ~/.nos3/42
make prep
make config    # strips legacy AC.ID lines only
grep AC.ID cfg/build/InOut/Inp_IPC.txt   # must be empty
make start-sat-aws
./scripts/fsw/verify_sat_42.sh
```

## Troubleshooting

| Symptom | Cause |
|---------|--------|
| `Bogus input "State.42"` or `"0"` | `Inp_IPC.txt` still has **AC.ID** lines with stock parser — run `make config` from this repo |
| `Temporary failure in name resolution` for `fortytwo` | fortytwo not running or missing `--network-alias=fortytwo` |
| Stuck on one listen port (stock 42) | Patched binary not deployed — re-run `make prep` |
