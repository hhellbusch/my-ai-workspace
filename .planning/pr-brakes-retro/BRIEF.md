# PR Brakes Retro

> **Status:** Ready to launch
> **Started:** 2026-09-25
> **Owner:** Field Notes / agent-assisted

## Audience and Purpose

**Reader:** You (launching) + a Codex agent on a **foreign** project  
**Enables:** Decide whether/how to apply Pocock’s PR-bottleneck “brakes” to that project’s Codex harness, checks, and review loop — without implementing until you accept proposals.

## Problem Statement

Agent throughput without designed brakes produces a review bottleneck and codebase entropy. Field Notes ingested Pocock’s framework ([library](../../library/matt-pocock-fixing-pr-bottleneck.md), [assessment](../../research/matt-pocock-fixing-pr-bottleneck/assessment.md)). Target is a **foreign Codex-harnessed project** (not Field Notes). Need a portable retro prompt you paste into Codex there.

## Scope

**In:**
- Self-contained Codex-oriented agent prompt (no Field Notes / sibling-repo dependency)
- Rubric: brakes, three-layer cake, lying checks, deep modules, implement vs review (esp. `AGENTS.md` overload), reviewer-commits, one-way doors, retro compounding
- Output: `RETRO-FINDINGS.md` + optional sketches (`coding-standards.md`, merge-danger PR block, Codex review-pass outline)
- Analyze-only by default

**Out of scope:**
- Implementing proposals in the foreign project (separate pass after accept)
- Teaching Codex itself; only this project’s harness config
- Building a Field Notes `/retro` skill (optional follow-up if the run is useful)

## Success Criteria

- [ ] `AGENT-PROMPT.md` is paste/boot ready with one fill-in: target workspace identity
- [ ] Agent produces `RETRO-FINDINGS.md` with prioritized proposals mapped to Pocock layers
- [ ] You can accept/reject each proposal before any code changes

## Key Decisions

| Decision | Choice | Why |
|---|---|---|
| Analyze vs implement | Analyze first | Retro without consent is a slop cannon of its own |
| Prompt location | This planning dir | Source of truth lives with the ingest; copy or paste into target |
| Self-contained rubric | Yes | Target workspace may not have Field Notes |

## Related

- [library/matt-pocock-fixing-pr-bottleneck.md](../../library/matt-pocock-fixing-pr-bottleneck.md)
- [research/.../assessment.md](../../research/matt-pocock-fixing-pr-bottleneck/assessment.md)
