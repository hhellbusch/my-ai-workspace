# mesh-desk — spec (for review)

> **Reader:** you, before any code.
> **Decision this enables:** approve this as the Linux stand-in for the phone app, including the build order.
> **Status:** building in `git-projects/mesh-desk`. Phase 1 is in use. Radio, map, log, traceroute, and waypoints are in the window. Remote admin of a second node is not — writing a node we have not read would wipe it.
> **Host:** Fedora, Cinnamon, X11. Station names and BLE addresses: `private/meshtastic/stations.md` (not seeded here).

## Product

A full local Meshtastic client for this desktop: connect, message, see the mesh, and **configure the radio** the way the [Android app](https://meshtastic.org/docs/software/android/user/) does. English UI. One node connected at a time (BlueZ only allows one BLE session).

Not a rewrite of the firmware protocol. The official Python `meshtastic` library already gets and sets the same protobuf config the phone uses (`--get` / `--set`, channels, modules, `sendText`). The app is a GTK front end on that library, plus a local message store.

## House stack

| Layer | Choice | Why |
|-------|--------|-----|
| Language | Python 3.14 | Same interpreter as the working CLI |
| Radio API | PyPI `meshtastic` (`BLEInterface`, `SerialInterface`, `TCPInterface`) | Official client; config and chat already work from here |
| UI | GTK4 + libadwaita (PyGObject) | Already installed; Cinnamon is GTK |
| History | SQLite in `$XDG_DATA_HOME/mesh-desk/` | The radio does not keep a full inbox |
| Secrets | Channel PSKs and admin keys stay on the node; UI may display them only while connected. No keys in git. Optional later: libsecret for “remember this BLE PIN” | |
| Code | `git-projects/mesh-desk` | Workspace projects folder (gitignored by the notes repo). App state stays in `$XDG_DATA_HOME/mesh-desk/` |
| Packaging | `./run` + `.desktop` file first | Flatpak only after the app is worth sandboxing |

Rejected: Electron, Java, a second BLE stack, hand-rolled protobuf.

## What “like the phone app” includes

### Connection

- BLE (primary), USB serial, TCP (for a future Wi-Fi node; T-Echo has no Wi-Fi).
- Saved radios: name + address, remembered **locally after connect** — not checked into this workspace or the public app repo.
- Before BLE connect, disconnect that address in BlueZ so a leftover CLI session cannot block us.
- Status: disconnected / connecting / connected / error, English, 20s connect timeout.
- Wake hint when the T-Echo is asleep: press a button.

### Nodes

- List: long name, short name, id, hops, role, battery, last heard, SNR if present.
- Detail: position, public key, hardware, channel util, favorite toggle (writes the radio favorite bit, same as the phone).
- Filter by last-heard window. Hop histogram (count of nodes at each hop).

### Messages

- Primary and secondary **channels** the radio has, plus **direct** threads.
- Composer, live receive (`TEXT_MESSAGE_APP`), send (`sendText`).
- SQLite history across reconnects.
- Channel 0 labeled public when it still uses the default PSK.
- Canned messages: read and edit the canned-message module text.

### Channels

Same editor as Settings → Channels on Android:

- Index, name, PSK (generate / default / enter), uplink, downlink, mute, position precision.
- Add and delete secondary channels.
- Save sends a channel config and waits for the reboot/ack the radio requires.

### Radio configuration

Forms over the device’s local config, grouped like the phone. Save per section (the radio reboots after many writes; batch one section per save).

| Section | Covers |
|---------|--------|
| User | Long name, short name, licensed operator if present |
| Device | Role, rebroadcast mode, node-info interval |
| LoRa | Region, modem preset, hop limit, TX power, TX enabled, MQTT ignore flags that live on LoRa |
| Position | Broadcast interval, smart position, fixed position, GPS mode |
| Power | Shutdown/sleep settings the firmware exposes (T-Echo is often left on; still editable) |
| Bluetooth | Enabled, pairing mode, fixed PIN |
| Display | Screen settings relevant to T-Echo / InkHUD fields the protobuf actually has |
| Network | Wi-Fi/Ethernet fields present but inert on T-Echo |
| Security | Public key (read-only), admin keys, managed mode, protection level when firmware supports it |

Labels in English. Widgets from the protobuf field types (enum → dropdown, bool → switch, int → spin). Do not maintain a parallel copy of every default; show the value read from the node.

### Modules

One screen per module the connected firmware reports, same idea as Android Settings → Modules: MQTT, telemetry, neighbor info, serial, external notification, store-and-forward, range test, detection, and any other module in `localConfig` / `moduleConfig`. Enable toggle plus the fields that module exposes. Unavailable modules hidden, not grayed-out fiction.

MQTT on a T-Echo is usually “not this hardware.” The page still exists so a later Wi-Fi node is not a rewrite.

### Map

Nodes with GPS on a map (libshumate or a WebKit leaflet view — pick libshumate if it is packaged on Fedora; otherwise a small WebKit map). Connected and heard nodes, last-heard styling, click → node detail. No offline tile hoarding. No site-planner / KML in the first map cut. Do not hardcode home coordinates in source.

### Remote admin

If this node has an admin key for another node: pick that node and run the same config screens over the mesh admin channel. The desk radio stays the Bluetooth session; admin messages go out over LoRa. Read that node's config before offering Save. A write of a config we have not read can wipe the node. Save is explicit, one section at a time. Failure is visible (no route, no key, timeout), not a silent no-op. The Python library's `our_exit` paths must not be used; a failed admin call cannot kill the app.

### Also in the product, after the above works

- Traceroute to a node
- Waypoints (read/create)
- Packet log (filterable), for when the mesh misbehaves

## Threading

BLE and serial callbacks are not on the GTK thread. All widget updates go through `GLib.idle_add`. The main loop must not block on scan or connect.

## Build order

The product is the full app. The order is how we get there without another MeshApp (big UI, connect never worked).

| Phase | Ships | Done when |
|-------|--------|-----------|
| 1 | Connect + nodes + channel/DM chat + SQLite history | BLE to the desk radio, send/receive, history after restart, BlueZ free after quit |
| 2 | User, Device, LoRa, Position, Bluetooth, Channels | Change hop limit or a channel name on the radio and read it back after reboot |
| 3 | Remaining radio sections + module pages | MQTT/telemetry/etc. round-trip on a module the device actually has |
| 4 | Map + favorites already on the node list + hop histogram | GPS nodes from the last session plot |
| 5 | Remote admin, traceroute, packet log, waypoints | Admin a second node from the desk radio when both are up, or traceroute a heard node |

Phase 1 is the gate. If BLE connect is flaky, we stop and fix that before config forms.

## Non-goals

- Firmware flashing. That stays with the Meshtastic project (CLI / web flasher).
- Android Auto, discovery beacons, geofence site planner
- Multi-radio dashboard: several radios with their own live connections at once. Remote admin of a node heard over the mesh is in scope and is not this.
- Replacing the public-mesh threat model (LongFast stays labeled public)
- Checking channel PSKs, station names, BLE MACs, or home geography into this workspace or the public app repo

## Done (whole product)

Day-to-day use of the T-Echos without the phone: see who is heard, talk, edit channels and LoRa/role/name, administer a second node through the desk radio, and open a map, from Cinnamon.

## Review note

An earlier draft scoped only chat. This revision matches “phone app on Linux.” Phases are delivery, not a smaller product. Config screens follow firmware fields instead of a hand-copied catalog of every module knob, so a firmware bump does not require a new form language.
