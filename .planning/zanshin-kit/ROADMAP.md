# Zanshin Kit — ROADMAP

> Last updated: 2026-04-20

## Phase 1 — Write and test (current)

**Status:** In progress

**Goal:** Produce `zanshin-kit/WORKING-STYLE.md` and verify it actually activates the working disciplines in a Copilot Chat session.

**Deliverables:**
- `zanshin-kit/WORKING-STYLE.md` — the kit
- `zanshin-kit/README.md` — setup instructions

**Test protocol (do this before declaring Phase 1 done):**
1. Open a new Copilot Chat session in a project other than Field Notes
2. Reference: `#file:WORKING-STYLE.md`
3. Ask for a spar on something real
4. Evaluate: does the output include argument types? self-audit? attack the strongest claim?
5. Run a checkpoint: does it write `.planning/whats-next.md` locally?
6. Note what broke or felt off → feed back into the document

**Phase 1 is done when:** The spar output is indistinguishable (in discipline, not prose style) from a Field Notes `/spar` run, and checkpoints land locally.

---

## Phase 2 — Iterate (after first real use)

**Status:** Not started

**Goal:** Address what Phase 1 testing reveals. Expected candidates:
- Document too long → trim without losing mechanism
- Copilot drifts mid-session → add re-activation instructions or restructure for prominence
- Missing practice → add it
- Isolation contract violated → strengthen the instructions

**No predetermined deliverables.** Phase 2 is defined by what Phase 1 breaks.

---

## Possible Phase 3 — Extended delivery (if needed)

**Status:** Idea — evaluate after Phase 2

**Copilot keyword registration:** `.github/copilot-instructions.md` can register keyword behaviors — teaching Copilot to respond to `/spar`, `/checkpoint` etc. as invocation keywords that trigger the corresponding WORKING-STYLE.md practice. This partially addresses the document-drift-during-session problem (Argument 1 from the Phase 1 spar): explicit keyword invocation re-anchors the practice without relying on the full document staying active in the context window. Note: this won't create a true slash command UI (that requires a VS Code extension), but it does make the invocation more reliable.

**Cursor-native layer:** If a personal/home project environment needs it separately from Field Notes.

**Version tagging:** So drift between the snapshot and Field Notes is visible. A date in the filename or a `version:` field in WORKING-STYLE.md frontmatter.

**Only build if Phase 1-2 reveals a real need. Don't build speculatively.**
