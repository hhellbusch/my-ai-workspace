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

**Second real session findings (Copilot CLI, real working session):**

Shoshin fired unprompted — named a specific assumption ("I'm assuming the first copy of the MFG doc is canonical — is that still true?"), not a generic list. Mechanism confirmed working.

Progressive bookkeeping held for commits. Loading and acknowledgment format clean.

Three gaps surfaced:
1. **Checkpoint before risky op didn't fire** — 440-line delete executed without a pre-checkpoint. Root cause: "anything that could fail mid-way" is too abstract for real-time recognition. Fixed: added concrete threshold (~50 lines, file moves, multi-file refactors) and decision heuristic.
2. **Verification miss caught by compaction, not by slowing down** — AI stated a finding with fluency of a verified result. Structural limitation: AI can't apply verification discipline to its own output in real time. Fixed: added explicit note that this practice requires human prompting on significant findings.
3. **Stack tracking not named** — parallel work stayed organized but push/pop was never invoked. Fixed: added note that this practice requires explicit naming, not silent activation.

**Structural observation:** `whats-next.md` and tool-native session state (e.g., `.copilot/session-state/`) coexist and serve different scopes. Addressed in README.

**Architecture work (spar-driven, same session):**

Spar on scalability identified four concerns:
1. Document growth vs. context window — bottom-half practices showing weaker real-session activation. Watching; no structural fix yet.
2. Activation model invisible at load time — fixed with compact table at top of Practices: spar/shoshin (invoke), bookkeeping (proactive), stack/verification (human-prompted).
3. Case study seeds substituting for case studies — one converted: `docs/case-studies/ai-self-diagnosis-symptom-report.md`.
4. Feedback loop is manual — structurally constrained by privacy; no fix beyond structured self-eval prompt.

Concrete example checkpoint added to `WORKING-STYLE.md` — abstract templates produce generic handoffs.

**Pending:** Close-out mode with real accumulated session context still untested. Quick capture untested under time pressure. Both require load-at-start → real work → trigger. Document growth concern needs a few more real sessions to determine whether restructuring is warranted.

---

## Phase 3 — Output format anchoring and scope definition

**Status:** In progress — 2026-04-21

**Finding that triggered this phase:**

Spar output in Copilot Chat (Claude model, `#file:` loading) differed in pattern from spar output in Cursor (Claude, system-prompt-level rules). Same model, different execution environment. Diagnosis: the WORKING-STYLE.md spar section described the *process* in prose but provided no output template — Claude had to infer the format and produced something looser.

**Fix applied (2026-04-21):**

Added explicit output templates to the spar section:
- Argument block template: `Type:`, `The argument:`, `Why it matters:`, `Strength:` as labeled fields
- `**Self-Audit**` section template: Strongest, Weakest, What I might be missing — as explicit fields
- Argument types moved to reference block after the templates (process steps flow cleanly, types available for reference)

**Root cause principle:** When a structured process produces inconsistent output across tools, the fix is usually a format template, not a longer description. The model needs to know what to *produce*, not just what to *think about*.

**Deferred to possible Phase 4:**

**Copilot keyword registration:** `.github/copilot-instructions.md` can register keyword behaviors — teaching Copilot to respond to `/spar`, `/checkpoint` etc. as invocation keywords that trigger the corresponding WORKING-STYLE.md practice. This partially addresses the document-drift-during-session problem (Argument 1 from the Phase 1 spar): explicit keyword invocation re-anchors the practice without relying on the full document staying active in the context window. Note: this won't create a true slash command UI (that requires a VS Code extension), but it does make the invocation more reliable. **Deferred — defer until there's a real need.**

**Cursor-native layer:** If a personal/home project environment needs it separately from Field Notes.

**Version tagging:** So drift between the snapshot and Field Notes is visible. A date in the filename or a `version:` field in WORKING-STYLE.md frontmatter.

**Cross-linking (portable form) and backlog capture:** See BACKLOG item "Zanshin Kit — Phase 3 scope definition." Scope and always-on vs. invoke-only not yet settled.

**Only build if real need is demonstrated. Don't build speculatively.**
