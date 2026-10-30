# Meshtastic desktop client

> **Status:** Active
> **Started:** 2026-10-05
> **Owner:** Henry Hellbusch

## Problem Statement

LilyGO T-Echo nodes on US LongFast. CLI + ad-hoc listening works; need a durable desktop client for chat, history, traffic, and radio config — not only `meshtastic --listen`.

Station inventory (names, BLE MACs, site notes) stays in `private/meshtastic/` — not in public planning.

## Scope

**In scope:**

- `mesh-desk`: Linux stand-in for the Meshtastic phone app (chat, nodes, map, channels, radio config, modules, remote admin). Spec: [SPEC.md](SPEC.md).
- Generic ops notes under `devops/meshtastic/`
- Private-channel plan for offline use later (PSK not in git)

**Out of scope:**

- MQTT public map as the primary inbox
- Firmware flashing inside the app
- MeshApp or other third-party Java/Electron desktops
- Publishing station identifiers or home geography

## Success Criteria

- [x] Tried MeshApp Flatpak — **rejected**; removed
- [ ] Stable desktop/web client for chat + history (English, BlueZ-friendly)
- [ ] Private secondary channel documented offline (PSK not in git)
- [ ] Coverage briefing kept out of the public tree (private / local canvas only)

## Constraints

- LongFast is public — no sensitive content on that channel
- A second node may be out of BLE range from the desk; one radio is the usual tether
- BlueZ exclusive connects block the next client — disconnect before switching tools
