---
review:
  status: unreviewed
  notes: "Public ops note. Station inventory (names, BLE MACs) lives in private/meshtastic/. MeshApp tried and removed 2026-10-05."
---

# Meshtastic

Notes for running LilyGO T-Echo (or similar) stations with the official Meshtastic CLI and a local desktop client — **US LongFast** as the public mesh preset.

Station-specific names and BLE addresses are **not** in this repo. Keep them in the private workspace layer (`private/meshtastic/` when using this Field Notes layout).

## Current tooling

- **CLI:** `meshtastic --ble <ble-name> --nodes` / `--listen` / `--sendtext`
- Wake the radio (hardware button) before connecting.
- BlueZ allows one BLE client at a time — `bluetoothctl disconnect <addr>` before switching tools.

## Abandoned

- **MeshApp** Flatpak — connect failed in testing; UI localization unsuitable. Removed. Not the house path.

## Desktop client

Client code: public repo [hhellbusch/mesh-desk](https://github.com/hhellbusch/mesh-desk), local checkout under `git-projects/mesh-desk` (gitignored). Product framing: [`.planning/meshtastic/SPEC.md`](../../.planning/meshtastic/SPEC.md).

The public `mesh-desk` source should not embed station names, addresses, or home coordinates. Remembered radios belong in local app config after connect.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
