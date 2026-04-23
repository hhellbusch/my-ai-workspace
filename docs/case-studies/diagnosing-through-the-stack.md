---
review:
  status: unreviewed
---

# Diagnosing Through the Stack — Audio Routing and the WirePlumber Priority Queue

> **Audience:** Engineers using AI assistants for system-level debugging — OS issues, audio, networking, device management — where the problem lives in configuration state rather than code.
> **Purpose:** Documents a Fedora Linux audio routing failure where line-out stopped working when a Blue Yeti microphone was plugged in. The session illustrates how reading multiple system layers in sequence (ALSA → PipeWire → WirePlumber → state file) found a durable root cause rather than a surface-level workaround.

---

## The Symptom

On Fedora Linux, plugging in a Blue Yeti USB microphone caused the system's line-out audio to stop working. The symptom was reproducible and session-persistent: every time the Yeti was connected, audio was silently rerouted to the Yeti's headphone jack rather than the line-out port.

The naive fix — unplug the Yeti, audio returns — solves nothing. The goal was to understand why this happened and whether a change would make it durable.

---

## Reading the Stack

System audio on modern Fedora runs through three layers:

| Layer | Role |
|---|---|
| ALSA | Kernel-level hardware abstraction; enumerates physical sound cards |
| PipeWire / PulseAudio compatibility | Audio server; manages virtual sinks, sources, and stream routing |
| WirePlumber | Session manager; decides which device is the default when multiple are available |

The diagnosis worked top-down through these layers.

**ALSA enumeration** confirmed three sound cards were visible to the kernel: `HDA Intel PCH` (the line-out), `HDA ATI HDMI`, and `Yeti Stereo Microphone` (USB). All three were registering cleanly — no hardware or driver issue.

**PipeWire sink enumeration** via `pactl list sinks short` confirmed all three had corresponding PipeWire output nodes. The default sink was explicitly set to the Yeti's analog output: `alsa_output.usb-Blue_Microphones_Yeti_Stereo_Microphone_797_2020_07_14_10953-00.analog-stereo`. Audio was being routed to the Yeti's headphone jack, not lost.

**WirePlumber state file** at `~/.local/state/wireplumber/default-nodes` held the root cause:

```
default.configured.audio.sink=bluez_output.B0_38_E2_5A_2D_87.1
default.configured.audio.sink.0=alsa_output.usb-...Yeti...analog-stereo
default.configured.audio.sink.1=alsa_output.pci-0000_00_1f.3.iec958-stereo
default.configured.audio.sink.3=alsa_output.pci-0000_00_1f.3.analog-stereo
```

WirePlumber maintains a priority stack of previously-configured sinks. When selecting a default, it iterates the stack and adds `20001 - index` to each available device's priority. The Yeti was at index 0 (+20000 bonus), and the PCH analog out was at index 3 (+19997). Every time the Yeti was plugged in, it outbid the line-out in WirePlumber's selection algorithm — by design, because it was the most recently preferred sink.

---

## Why This Happened

The first time the Yeti was plugged in, PipeWire promoted it to the default sink (standard behavior for newly connected audio devices). The user's interaction with the Yeti-as-default was logged into the WirePlumber state file, placing it at the top of the preference stack. Every subsequent connection replayed that outcome: WirePlumber saw the Yeti in its history, gave it the highest priority boost, and selected it.

This is not a bug in WirePlumber. It is working as designed — restoring user preferences across sessions. The problem is that the preference it stored was not the one the user intended to persist.

---

## The Fix

```bash
pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo
```

This command does two things at once:

1. **Immediately** switches the active default sink to the PCH line-out.
2. **Triggers WirePlumber's `store-configured-default-nodes` hook**, which moves `alsa_output.pci-0000_00_1f.3.analog-stereo` to the top of the preference stack in the state file.

After running it, the state file reorders so the PCH analog out holds the highest priority boost on next selection. When the Yeti is plugged in again, WirePlumber sees PCH analog at position 0 (+20001) and the Yeti further down the stack — PCH wins.

No config files need editing. No services need restarting. The fix is durable because it works with WirePlumber's state mechanism rather than around it.

---

## What Made This Different from a Surface Fix

A surface fix would be: "try running `pactl set-default-sink` to restore audio." That happens to be the correct command, but without the layer below it, the reasoning is incomplete.

The question that changes the outcome: **will this persist when the Yeti is plugged in again?**

Without reading the WirePlumber state file and understanding the priority stack, the answer is uncertain. With it, the answer is yes — and the reasoning is verifiable. The state file will show the PCH sink has moved to position 0 after the command runs.

The distinction matters because surface fixes to recurrent problems generate recurrent fixes. A user who doesn't understand the mechanism will run the command again the next time it breaks, or will assume the fix failed if something later causes the Yeti to win again.

---

## The Diagnostic Pattern

The session followed a specific sequence:

1. **Enumerate the hardware** — confirm the physical devices are visible (`/proc/asound/cards`)
2. **Check the protocol layer** — confirm the audio server sees the right sinks (`pactl list sinks short`, `pactl get-default-sink`)
3. **Check the session manager** — confirm which sink is selected as default and why
4. **Read the state** — confirm whether that selection is persisted and in what form

Each layer answered a different question. ALSA answered "is the hardware present?" PipeWire answered "where is audio being routed?" WirePlumber answered "who decided that and why?" The state file answered "is the fix durable?"

Stopping at layer 2 (PipeWire) gives you the command. Stopping at layer 4 (state file) gives you confidence in the outcome.

---

## Connection to Related Patterns

The same layered-read approach applies to other system-level issues where the visible symptom and the actual state live at different depths:

| Domain | Symptom layer | State layer |
|---|---|---|
| Audio routing | Default sink (PipeWire) | Preference stack (WirePlumber state file) |
| Network routing | Traffic going to wrong interface | Routing table / policy priority |
| Package conflicts | Install failure | Dependency resolver state |
| SSH key selection | Wrong key used | `ssh-agent` loaded keys, `.ssh/config` priority |

In each case, the pattern is the same: the symptom is visible at one layer; the mechanism that produces it is one or two layers below; the fix is durable only when it targets the layer that stores the decision.

---

## Artifacts

| Artifact | What it is |
|---|---|
| `~/.local/state/wireplumber/default-nodes` | WirePlumber's persisted sink/source preference stack |
| `pactl set-default-sink <sink-name>` | The fix — updates both active routing and stored preference |
| `pactl list sinks short` | Enumerates available PipeWire output nodes |
| `pactl get-default-sink` | Confirms current default |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
