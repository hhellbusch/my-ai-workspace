# Agent prompt — PR Brakes Retro (Codex project)

**Use:** Paste into a Codex (or Codex-compatible) agent session whose working directory is the **foreign project** you want analyzed.

Fill Configuration, then run. Do **not** implement changes until the human accepts items from `RETRO-FINDINGS.md`.

This prompt is self-contained. You do not need any other repo.

---

## Configuration

```text
TARGET_WORKSPACE_NAME: <short name for the project>
HARNESS: OpenAI Codex (agent coding harness)
LOOKBACK: last 2 weeks of git history (or last 30 commits if quieter)
OUTPUT_PATH: RETRO-FINDINGS.md
```

---

## Objective

Run a **harness / review-system retrospective** on this Codex-driven project using Matt Pocock’s “Fixing the PR Bottleneck” framework (AI Engineer, 2026).

Produce prioritized proposals for how *this* repo’s Codex setup could add or strengthen **brakes** so agent acceleration does not become a slop cannon.

Outcome: one findings doc. Analyze only. No drive-by refactors, no commits unless asked.

---

## What “Codex harness” means here

Treat Codex as the factory accelerator. Look for how this project steers it:

| Area | Typical locations (adapt to what exists) |
|---|---|
| Global steering | `AGENTS.md`, `CLAUDE.md`, `.codex/`, `~`-equivalent project config, README agent sections |
| Skills / procedures | `.codex/skills/`, `skills/`, prompt files, custom commands |
| Checks | CI workflows (`.github/workflows/`, etc.), `package.json` scripts, Makefile, linters, tests, typecheck |
| Review | PR templates, bot comments, any review agent/skill, CODEOWNERS |
| Recent agent behavior | Recent commits/PRs, failing checks, repeated review comments |

If a path above is missing, note the absence — absence is a finding.

---

## Embedded rubric (Pocock)

For each lens: **current state**, **gap**, **proposal**, **effort** (S/M/L), **risk if ignored**.

### L1 — Acceleration vs brakes
- How does work start (human prompts in Codex, scripts, CI, hooks)?
- Is Codex pushing volume without matching quality brakes?
- Is “code is the agent’s environment” treated seriously (bad merges → worse next runs)?

### L2 — Three-layer cake
Map what exists for:
1. **Automated checks** — lint, test, types, format, policy (cheap, deterministic)
2. **Automated review** — a *separate* agent/skill pass against **repo-owned** standards (not “hope implement got it”)
3. **Human review** — who merges, PR norms, when humans actually look

### L3 — Checks that lie
Evidence from tests/CI/recent PRs of:
- Tautological tests (reasserting implementation)
- Structure-sensitive tests (source order / internals instead of behavior)
- Unfailable tests (over-mocking)
- Green CI treated as merge-ready with no further gate

Propose hardenings agents cannot easily game.

### L4 — Deep modules / agent-legible design
- Deep vs shallow modules?
- Do agents test internals instead of seams?
- Shared vocabulary for seams/locality — or conflicting architecture dialects?

Propose at most 1–3 high-leverage deepenings or naming conventions — not a rewrite.

### L5 — Implement overloaded vs review underloaded *(Codex-critical)*
- Where do coding standards live? Especially: are they dumped into `AGENTS.md` / always-on Codex context?
- Does the implement turn also carry explore + edit + debug + style rules?
- Is there a **separate review pass** (skill, second Codex turn, CI agent) that owns standards?

Propose: split **make it work** (implement) from **make it good** (review). Prefer a dedicated `coding-standards.md` (or equivalent) read by review only — not drowning always-on `AGENTS.md`.

### L6 — Reviewer should commit
- Do review tools only comment (creating more human work)?
- Fit for this repo: review pass applies agreed-standard fixes; human owns merge and skims the artifact.
- Comment only when uncertain.

### L7 — Human-friendly PRs / attention triage
- PR template: one-way vs two-way door, blast radius, merge danger?
- PR bodies scannable (short why + evidence) or text walls?
- Equal scrutiny on every PR (bad) vs risk-tiered (good)?

### L8 — Retro compounding
- Repeated human comments → updates to checks / standards / AGENTS pointers?
- Steering bloat in `AGENTS.md` or skills?
- Tool/context economy (always-on instructions that should be on-demand)?

Propose a lightweight loop: after a PR batch or Codex session → suggest check/standard/pointer updates.

---

## Method (in order)

1. **Orient** — Inventory harness files (`AGENTS.md`, `.codex/**`, CI, test runners, PR templates). Summarize current Codex harness in ≤15 lines.
2. **Sample** — `git log --oneline` for LOOKBACK; inspect 3–5 recent merges/PRs; note check failures and review comments if visible.
3. **Score L1–L8** — current / gap / proposal / effort / risk.
4. **Prioritize** — Top 5 only. Order by (impact on review bottleneck) × (feasibility). Tag each: `check` | `standard` | `skill/process` | `design` | `AGENTS.md`.
5. **Draft appendices (text only)** — optional sketches:
   - `coding-standards.md` (10–20 repo-specific bullets)
   - PR “Merge danger” block
   - Review-pass outline for Codex (inputs: diff; reads: coding-standards; default: apply fixes; comment when unsure; human merges)
6. **Write `OUTPUT_PATH`** using the template below.
7. **Stop.** Ask which proposals to implement. Do not commit unless asked.

---

## Output template (`RETRO-FINDINGS.md`)

```markdown
# PR Brakes Retro — <TARGET_WORKSPACE_NAME>

Date: <ISO date>
Harness: Codex
Lookback: <range>
Mode: analyze-only

## Harness snapshot
<≤15 lines — how Codex is steered here>

## Scorecard
| Lens | Grade (A–F) | One-line gap |
|---|---|---|
| L1 Acceleration vs brakes | | |
| L2 Three-layer cake | | |
| L3 Lying checks | | |
| L4 Deep modules | | |
| L5 Implement vs review context | | |
| L6 Reviewer commits | | |
| L7 PR attention triage | | |
| L8 Retro compounding | | |

## Top 5 proposals
### P1 — <title>
- Lens: L#
- Type: check | standard | skill/process | design | AGENTS.md
- Why:
- Proposal:
- Effort: S/M/L
- Acceptance test:
- Risks:

### P2 — ...

## Explicit non-goals (this pass)
-

## Appendix A — coding-standards.md sketch (optional)
## Appendix B — PR merge-danger block (optional)
## Appendix C — Codex review-pass outline (optional)

## Open questions for human
-
```

---

## Constraints

- Evidence from **this** repo only (files, CI, git). No generic Codex sermons.
- JBGE: one sitting, useful findings; no essay.
- Foreign workspace: do not assume Field Notes / Cursor / Pi conventions exist.
- Do not mark anything reviewed/approved.
- Do not push; do not rewrite history.
- If brakes are already strong, say so — few proposals is a valid outcome.
