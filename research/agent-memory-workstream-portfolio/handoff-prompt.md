# Handoff prompt — explore workstream / portfolio repo (other machine)

Copy into a session on the customer/portfolio machine where the journal idea already lives.

---

## Context

On Field Notes (`gemini-workspace`) we:

1. Pruned zanshin to six portable skills (shoshin, spar, craft, unslop, checkpoint, whats-next); dropped STANDALONE; Pi is optional.
2. Researched agent-memory products vs git portfolio ([assessment](assessment.md)). **Verdict:** git workstream portfolio stays SoR; do **not** spike Hindsight soon.
3. Sketched workstream conventions on branch `docs/workstream-portfolio-sketch` in Field Notes (may not be checked out here).

Primary harnesses: Codex, Copilot, Cursor. Style: describe goal → agent runs → collaborate as needed → frequent meaningful commits → journal for review/repeatability.

## Your job

1. Inventory what already exists in **this** portfolio/journal workspace (dirs, naming, what’s working / painful).
2. Compare to the Field Notes sketch (if available) or the assessment’s recommended shape:
   - Workstream = durable thread of intent (goal, constraints, journal, links, status)
   - Lab/product repos = evidence (commits, optional trial log)
   - Agents read files; no memory server required
3. Propose a minimal convention (JBGE) that fits **this** environment — do not import Hindsight or Mem0.
4. Optionally migrate or rename existing notes into that shape; ask before large moves.
5. End with: what’s decided, what’s still open, and a checkpoint-style handoff for the next session.

## Constraints

- Prefer markdown + git. No new infra.
- Don’t put customer secrets in commits.
- Shorter over longer; ask when context is incomplete.
- If Field Notes research isn’t cloned here, treat the assessment verdict above as sufficient.

## Done when

A short `README` or `CONVENTIONS` in the portfolio repo states the workstream model, one example workstream exists in the agreed shape, and open questions are listed for the next session.
