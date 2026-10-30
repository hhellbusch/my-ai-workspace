# Meshtastic — whats-next (public)

Site-specific session detail (node names, MACs, coverage pins, geography) is archived under `private/.planning/meshtastic-stations/`. This file stays JBGE for public continuity.

## Current

- Spec approved; code in `git-projects/mesh-desk` (gitignored checkout) / public repo [hhellbusch/mesh-desk](https://github.com/hhellbusch/mesh-desk).
- Phase 1 in use: BLE connect, nodes, chat, SQLite history.
- Radio, map, hop histogram, packet log, traceroute, favorites, waypoints, TCP connect shipped in later cuts.
- Remote admin of a second node: in scope — read before write. Firmware flash stays with Meshtastic project.
- Maturity: `git-projects/mesh-desk/AGENTS.md` hazard list; `pytest` + Actions for races/keys/history; BLE connect and real Save stay manual.
- Public source must not embed station names, addresses, or home coordinates. Radios remembered only in local app config after connect.

## Next

- Persist useful local connect defaults without committing inventory to git.
- Keep private inventory and coverage notes updated in `private/meshtastic/` when stations change.
