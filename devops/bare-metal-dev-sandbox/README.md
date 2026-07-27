# Bare Metal Dev Sandbox

Local **Tier G1** sandbox for developing ACM bare-metal / BMC (Redfish) automation without
dedicated hardware per developer. Uses [sushy-static](https://docs.openstack.org/sushy-tools/latest/user/index.html)
to serve Redfish mockups over **HTTPS** on `localhost`.

Planning: [`.planning/bare-metal-dev-sandbox/`](../../.planning/bare-metal-dev-sandbox/BRIEF.md)

**New here?** Start with **[WORKSHOP.md](WORKSHOP.md)** — hands-on labs and a peer teaching outline.

## Fidelity tiers

| Gate | What it validates | This PoC |
|------|-------------------|----------|
| G0 | Playbook syntax | `ansible-playbook --syntax-check` |
| G1 | Redfish client against emulated BMC | **Implemented** |
| G2 | ACM CR apply on shared dev hub | Not in PoC v1 |
| G3 | Discovery ISO → `Agent` registered | Future spike |
| G4 | Full bare-metal install | Shared hardware pool |

Inspired by [Ambler's development sandboxes](https://agiledata.org/essays/sandboxes.html) —
logical BMC endpoints per developer, shared physical hosts at promote time.

## Prerequisites

- `podman`
- `ansible` + `community.general` collection
- Optional later: `libvirt` for dynamic sushy-emulator

## Quick start

```bash
cd devops/bare-metal-dev-sandbox

# One-time
ansible-galaxy collection install -r requirements.yml
chmod +x scripts/*.sh scripts/*.py

# Start static Redfish BMC on https://127.0.0.1:8000 (self-signed cert auto-generated)
./scripts/start-static.sh

# Smoke test
ansible-playbook playbooks/smoke-redfish.yml

# Preflight harness — regression scenarios (see HARNESS.md)
./scripts/check.sh

# Live preflight against real hub/BMC/network (bastion or laptop with oc + BMC access)
export BMC_USERNAME=root BMC_PASSWORD=...
./scripts/run-live.sh examples/live-preflight-vars.example.json

# Teardown
./scripts/stop-static.sh
```

Override endpoint:

```bash
BMC_HOST=127.0.0.1 BMC_PORT=8000 ansible-playbook playbooks/smoke-redfish.yml
```

## Layout

```
bare-metal-dev-sandbox/
├── catalog/checks.yaml            # stable preflight check IDs
├── scenarios/*.yaml               # harness scenarios (inputs + expected findings)
├── roles/preflight_validate/      # validation gate implementation
├── fixtures/static-redfish/       # DMTF-style Redfish mockup tree
├── playbooks/
├── scripts/
│   ├── run-scenario.sh          # harness/hybrid scenarios
│   ├── run-live.sh              # live mode against real infrastructure
│   └── check.sh                 # G0 syntax + full scenario regression
├── examples/                    # live config templates (no secrets)
└── WORKSHOP.md                  # hands-on labs + peer teaching guide
```

## Known emulation gaps (vs production Dell iDRAC)

1. **No `idrac-virtualmedia://` URI scheme** — sushy serves standard Redfish; Dell-specific boot URL schemes are not emulated.
2. **Static mockups are read-only** — `InsertMedia` / `EjectMedia` POST/PATCH do not change state; use dynamic sushy-emulator for mutable ops.
3. **No Dell OpenManage module fidelity** — prefer `community.general.redfish_*` for sandbox work.
4. **Firmware-specific response shapes** — production BMCs may differ; extend fixtures from characterized captures.
5. **No HTTP auth enforcement on sushy-static** — wrong credentials still return 200; use `auth_ok: false` in harness scenarios or test auth against real BMC in `live` mode.
6. **No network/install-path simulation in static sushy alone** — use harness `state` or hybrid `mock_listener` for TCP checks.

## Roadmap

See [`.planning/bare-metal-dev-sandbox/ROADMAP.md`](../../.planning/bare-metal-dev-sandbox/ROADMAP.md).

## Related

- [004_validate_virtual_media_ejection](../ansible/examples/004_validate_virtual_media_ejection/) — Redfish Ansible patterns
- [agent-install-preflight.md](../rhacm/notes/agent-install-preflight.md) — ACM preflight orchestration map
