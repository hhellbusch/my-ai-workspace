# Zanshin Kit — ROADMAP

> Last updated: 2026-04-20

## Phase 1 — Write and test

**Status:** Complete — 2026-04-20

**Goal:** Produce `zanshin-kit/WORKING-STYLE.md` and verify it actually activates the working disciplines in a Copilot Chat session.

**Deliverables:**
- `zanshin-kit/WORKING-STYLE.md` — the kit
- `zanshin-kit/README.md` — setup instructions

**Findings from real use (Copilot Chat):**

Spar mechanism loaded and produced typed, self-audited output — vocabulary and discipline transferred. Three structural gaps surfaced:

1. **Handoff format over-engineered for quick capture.** Six required fields doesn't serve "I have 30 seconds to close."
2. **Multi-context collision unaddressed.** (Later revised — see Phase 2 note.)
3. **No close-out invocation path.** Document is written for load-at-start. When loaded at session end, practices are inapplicable.

**Meta-observation:** Copilot applied the working style's own discipline to produce these findings — honest, typed, no padding. Positive signal for mechanism transfer.

---

## Phase 2 — Iterate

**Status:** Complete — 2026-04-20

**What was done:**

Three changes applied to `WORKING-STYLE.md`:

1. **Quick capture added** — two or three lines, no template, appends to `whats-next.md`. Marked as fallback not default (tension with progressive bookkeeping named explicitly).
2. **Multi-context collision guidance added, then removed.** Initially added as "append with datestamp." Spar and user clarification revealed the reported symptom was context drift within a single session, not actual simultaneous sessions. The guidance was misdiagnosis-derived. Simplified: append-with-datestamp rule folded as a one-liner inside close-out mode, where it's actually needed.
3. **Close-out mode added** — confirmed real use case (user loaded document at session end to close out a drifted session). Trigger: "close-out" / "write a handoff."

**Secondary finding:** The kit's own discipline wasn't applied during Phase 2 iteration — shoshin should have been run on the Copilot feedback before implementing changes. This is a process observation, not a document flaw. Noted for Phase 3 practice.

**Pending:** Re-test in a real Copilot session to confirm quick capture and close-out mode behave as specified. Close-out mode in particular — suppression instructions are harder to verify than activation instructions.

---

---

## Possible Phase 3 — Extended delivery (if needed)

**Status:** Idea — evaluate after Phase 2

**Copilot keyword registration:** `.github/copilot-instructions.md` can register keyword behaviors — teaching Copilot to respond to `/spar`, `/checkpoint` etc. as invocation keywords that trigger the corresponding WORKING-STYLE.md practice. This partially addresses the document-drift-during-session problem (Argument 1 from the Phase 1 spar): explicit keyword invocation re-anchors the practice without relying on the full document staying active in the context window. Note: this won't create a true slash command UI (that requires a VS Code extension), but it does make the invocation more reliable.

**Cursor-native layer:** If a personal/home project environment needs it separately from Field Notes.

**Version tagging:** So drift between the snapshot and Field Notes is visible. A date in the filename or a `version:` field in WORKING-STYLE.md frontmatter.

**Only build if Phase 1-2 reveals a real need. Don't build speculatively.**
