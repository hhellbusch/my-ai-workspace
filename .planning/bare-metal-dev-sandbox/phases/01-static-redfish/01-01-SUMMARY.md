# Phase 01-01 Summary — Static Redfish Sandbox

**Status:** Complete  
**Date:** 2026-07-02

## Delivered

- `.planning/bare-metal-dev-sandbox/` — BRIEF, ROADMAP, phase plan
- `devops/bare-metal-dev-sandbox/` — runnable G1 per-developer sandbox
  - Hand-crafted DMTF-style mockup tree (iDRAC.Embedded.1 / VirtualMedia/CD)
  - `scripts/start-static.sh` / `stop-static.sh` (podman + sushy-static + auto TLS)
  - `playbooks/smoke-redfish.yml` — `community.general.redfish_info` smoke test

## Verification (run on this host)

```bash
cd devops/bare-metal-dev-sandbox
./scripts/start-static.sh
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/smoke-redfish.yml   # PASS
./scripts/stop-static.sh
```

## Discoveries

1. **sushy-static `-m` path** must point at the `v1` mockup root (directory containing `index.json` for `/redfish/v1/`), not the parent `redfish/` tree.
2. **`community.general.redfish_info` uses HTTPS only** — static sandbox needs TLS (`-c`/`-k`); plain HTTP fails with SSL wrong version.
3. **GetVirtualMedia return shape** is nested: `entries[0][1]` holds the media list — assertions must account for this.
4. **Host has podman but no libvirt socket** — Phase 3 (dynamic emulator) blocked here until libvirt is available.

## Emulation gaps confirmed

- Static mockups: GET only; no state change on InsertMedia/EjectMedia
- No Dell `idrac-virtualmedia://` scheme
- `dellemc.openmanage.*` modules not validated against sushy

## Next

Phase 2: characterization script to capture production BMC Redfish responses when hardware is available; diff against static fixtures.
