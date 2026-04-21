# Zanshin Kit — ROADMAP

> Last updated: 2026-04-20

## Phase 1 — Write and test

**Status:** Complete — 2026-04-20

**Goal:** Produce `zanshin-kit/WORKING-STYLE.md` and verify it actually activates the working disciplines in a Copilot Chat session.

**Deliverables:**
- `zanshin-kit/WORKING-STYLE.md` — the kit
- `zanshin-kit/README.md` — setup instructions

**Findings from real use (Copilot Chat):**

Spar mechanism loaded and produced typed, self-audited output — vocabulary and discipline transferred. Three structural gaps surfaced under real use:

1. **Handoff format over-engineered for quick capture.** Six required fields optimizes for rich recovery; doesn't serve "I have 30 seconds to close." Needs a lightweight quick-capture variant.

2. **Multi-context collision unaddressed.** One session, one file is the implicit assumption. Multiple windows writing to `.planning/whats-next.md` produced two rejected edits before "append with datestamp" emerged as the working solution. Needs explicit guidance.

3. **No close-out invocation path.** Document is written for load-at-start. When loaded at session end, spar/shoshin/stack are inapplicable. Needs a trigger that skips practices and goes straight to state capture.

**Meta-observation:** Copilot applied the working style's own discipline to produce the Phase 1 findings — honest, typed, no padding. That's a positive Phase 1 result.

---

## Phase 2 — Iterate (current)

**Status:** In progress

**Goal:** Address Phase 1 gaps. Three defined improvements:

1. **Quick capture variant** — two or three lines, no template, appends to `whats-next.md`
2. **Multi-context guidance** — append-with-datestamp as documented convention, not emergent workaround
3. **Close-out invocation** — trigger that activates bookkeeping only, skips practices

**Deliverable:** Updated `zanshin-kit/WORKING-STYLE.md` incorporating all three. Then re-test in a real session and note whether the gaps are closed.

---

## Possible Phase 3 — Extended delivery (if needed)

**Status:** Idea — evaluate after Phase 2

**Copilot keyword registration:** `.github/copilot-instructions.md` can register keyword behaviors — teaching Copilot to respond to `/spar`, `/checkpoint` etc. as invocation keywords that trigger the corresponding WORKING-STYLE.md practice. This partially addresses the document-drift-during-session problem (Argument 1 from the Phase 1 spar): explicit keyword invocation re-anchors the practice without relying on the full document staying active in the context window. Note: this won't create a true slash command UI (that requires a VS Code extension), but it does make the invocation more reliable.

**Cursor-native layer:** If a personal/home project environment needs it separately from Field Notes.

**Version tagging:** So drift between the snapshot and Field Notes is visible. A date in the filename or a `version:` field in WORKING-STYLE.md frontmatter.

**Only build if Phase 1-2 reveals a real need. Don't build speculatively.**
