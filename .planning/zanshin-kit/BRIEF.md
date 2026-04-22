# Zanshin Kit — BRIEF

> Last updated: 2026-04-20

## One-liner

A single document that travels into any AI-assisted environment and activates consistent working discipline — regardless of what tool is available.

## The problem

The Field Notes working style (spar, shoshin, progressive bookkeeping, verification discipline, session handoffs) lives inside a Cursor-specific framework: rules, commands, skills. That framework doesn't travel. In a customer environment with approved tooling (currently Copilot Chat), none of the command machinery is available.

But the *discipline* is portable. The question is whether it can be encoded in a document well enough that any conversational AI can follow it.

## The hypothesis being tested

**A single well-crafted `WORKING-STYLE.md` is sufficient.** Drop it into a project, reference it at session start (`#file:WORKING-STYLE.md` in Copilot Chat), and the core disciplines activate. No `.cursor/` directory. No command invocation. Just a document and a reference.

This was deliberately simplified through two rounds of spar and shoshin:
- First pass: 4-phase extraction project (audit all rules, build Cursor-native layer, build agnostic layer, validate)
- Spar caught: Copilot isn't an agent; trimmed skills lose mechanism; over-engineered for one document
- Shoshin caught: the kit is document-shaped, not infrastructure-shaped
- Simplified to: write the document, try it, see what breaks

## Known risks going in

**The mechanism question:** The spar command works because of its structure — argument type taxonomy, steel-man requirement, self-audit protocol. A document version either carries that structure (in which case it's long) or loses it (in which case it's a slogan). The document tries to carry the mechanism. Watch for: AI produces generic pushback and calls it a spar.

**Copilot compliance:** Copilot Chat follows instructions to varying degrees depending on how it's loaded. `#file:` references work but may not carry the same weight as a system prompt. The AI may drift from the document's instructions mid-session. Watch for: Copilot ignoring the practices after a few exchanges.

**Drift over time:** This document is a snapshot. When Field Notes' working style evolves, this snapshot falls behind. No sync mechanism exists. Mitigation: note the snapshot date; re-copy when behaviors change significantly.

**Isolation compliance:** The isolation contract (all artifacts stay local) depends on the AI not suggesting writes to external paths. Watch for: any suggestion to update Field Notes, reference external files, or assume workspace-level context that doesn't exist here.

## Success criteria

- Can trigger adversarial review with natural language ("spar this approach") and get output that matches the structured spar discipline — argument types, self-audit, attacking strongest claims
- Checkpoint writes a correctly-formatted `.planning/whats-next.md` locally
- Session ends cleanly — artifacts in the local project, nothing external
- Stack tracking works: pushed subtopic returns to parent on resolution

## What failure looks like

- Spar produces generic "here are some concerns" without argument classification or self-audit
- Copilot ignores the document after the first exchange
- Checkpoints don't get written, or get written in the wrong place
- The document is too long to be practical as context

## Scope

**In scope (v1):** `WORKING-STYLE.md` + `README.md`. Try it. Iterate.

**Out of scope (v1):**
- Cursor-native layer extraction (Field Notes already provides this for personal environments)
- `.github/copilot-instructions.md` variant (add if `#file:` reference proves insufficient)
- Skills portability beyond what's in the document
- Publishing externally

## The name

"Zanshin" (残心) — the sustained, relaxed awareness that persists after action. The working style this document encodes: not rushing, staying present, completing things properly, maintaining awareness of context. The name is from the zen-karate philosophy work in Field Notes and fits better than "portable kit" or "working style framework."

---

## Scope evolution — Phase 3 (2026-04-21)

The v1 scope above was accurate at the time. Phase 3 expanded it based on real use findings:

**Added to the kit:**
- Spar output templates (argument block: Type / The argument / Why it matters / Strength; Self-Audit block) — fixes format inconsistency across tools when loaded via `#file:` vs. system prompt
- Collaboration style section (brevity, cut before adding, sharp questions over long drafts) — lifted from workspace `.cursorrules`
- Shoshin operational precision — proactive triggers at session start and scope shifts, scope shift logging, style guide check, "what this is not" clarification
- `STYLE.md` — opinionated style defaults (voice, structure, ADRs, technical resources, biographical content, code style, cross-linking)
- `STYLE.template.md` — blank template for teams building their own conventions

**Root cause of scope expansion:** Same model (Claude), different output quality in Copilot Chat vs. Cursor — diagnosed as missing output templates and missing behavioral defaults that the workspace carries in always-on rules. The kit needed to encode these explicitly since it can't rely on the rule system.

**One-liner updated:** A kit that travels into any AI-assisted environment and activates consistent working discipline — including style and output format — regardless of what tool is available.
