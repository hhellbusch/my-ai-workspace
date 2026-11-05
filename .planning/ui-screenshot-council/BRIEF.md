# UI Screenshot Council

> **Status:** Ready to launch
> **Started:** 2026-11-04
> **Owner:** Field Notes / agent-assisted

## Audience and Purpose

**Reader:** You, launching an agent on a **foreign** project that has a web UI.
**Enables:** Run a bounded screenshot hill climb there without treating an invented folder layout as Theo's published skill.

## Problem Statement

Theo's talk turns UI taste into a score that other models climb ([library](../../library/theo-agents-sucked-at-ui.md)). The published piece is [tstack `council`](https://github.com/t3dotgg/tstack/blob/main/skills/council/SKILL.md): three providers, read-only, score out of 10, one full pass is a round. The talk's useful extras — reference screenshots, graders who are not told the target, a fresh context per round — are not in that skill. A foreign agent needs those extras written down, and a stop before it spends a day chasing 10/10.

## Scope

**In:**
- Self-contained agent prompt for the foreign repo
- Provenance: tstack council vs the `design/ui-climb/` layout invented here
- Bounded run: scaffold, capture, up to 3 rounds, score log, stop before merge

**Out of scope:**
- Implementing the climb inside Field Notes (this repo has no product UI)
- Cloning his token budget (~$250–400, ~18 hours, then a 10/10 chase)
- Installing tstack's other skills (`full-send`, `babysit-pr`, and the rest)

## Success Criteria

- [ ] `AGENT-PROMPT.md` is paste-ready and does not require this repo
- [ ] The prompt says which parts are tstack and which parts were written here
- [ ] A run on the foreign repo leaves `design/ui-climb/scores.md` and does not merge

## Key Decisions

| Decision | Choice | Why |
|---|---|---|
| Where the idea lives | This planning dir, plus the library entry | The other workspace gets a paste. This repo keeps the source. |
| `design/ui-climb/` | Invented here | Not in the video's skill repo. Label it so a later agent does not cite it as tstack. |
| Default length | 3 rounds, then stop | His first hour produced a mergeable delta. The rest was the addiction. |
| Merge | Human | He almost YOLO-merged on stream. The prompt does not. |

## Related

- [library/theo-agents-sucked-at-ui.md](../../library/theo-agents-sucked-at-ui.md)
- [Transcript](../../research/theo-agents-sucked-at-ui/sources/agents-sucked-at-ui-until-today.md)
- [tstack council](https://github.com/t3dotgg/tstack/blob/main/skills/council/SKILL.md)
