# When AI Fabricates the Evidence for Its Own Argument

> **Audience:** Engineers using AI to produce documentation, research references, or any content with external citations.
> **Purpose:** Documents a specific incident where AI fabricated a plausible URL while defining a concept about AI's tendency to fabricate — and how the fix addressed both the immediate error and the systemic gap.

---

## The Setup

The essay [The Shift](../ai-engineering/the-shift.md) introduces sycophancy — the tendency of AI models to tell users what they want to hear — in its "Design thinking at scale" section. During a review pass, the author noticed the term was used without definition. The request was straightforward: define sycophancy inline on first use and link to supporting research.

---

## What Happened

The AI defined the term clearly and linked to `https://www.anthropic.com/research/understanding-sycophancy`. The URL looked right. Anthropic publishes research at that path pattern. The slug was plausible. The link was included in the essay and the change was presented as complete.

The author clicked the link. It returned a 404.

The actual URL is `https://www.anthropic.com/research/towards-understanding-sycophancy-in-language-models` — a longer, less intuitive slug that the AI had "simplified" into something that didn't exist.

---

## Why This Matters

The failure mode here is subtle and worth examining:

1. **The URL was structurally plausible.** It followed the correct domain, path convention, and topic. Nothing about it signaled "fabricated" on visual inspection.

2. **The surrounding content was correct.** The definition of sycophancy was accurate, the inline explanation was clear, and the placement in the essay was appropriate. The only wrong thing was the reference itself.

3. **It happened in the section about sycophancy.** The AI demonstrated a different but related failure mode — confident fabrication — while being asked to explain AI's tendency toward confident agreement. The irony is not incidental; it illustrates why verification is a skill that has to be applied to *every* output, not just the ones you're suspicious of.

4. **The failure was invisible without human action.** No linter, syntax checker, or automated review would have caught a well-formed URL returning 404. Someone had to click it.

This mirrors a pattern from [The Shift](../ai-engineering/the-shift.md) section 6: AI output is always well-structured and confident, and a wrong answer is indistinguishable in tone from a right one. The fabricated URL carried the same confidence as the correct definition around it.

---

## The Fix — Immediate and Systemic

### Immediate: verify and correct

A web search found the correct paper — Anthropic's ["Towards Understanding Sycophancy in Language Models"](https://www.anthropic.com/research/towards-understanding-sycophancy-in-language-models) (October 2023). The URL was corrected and verified by fetching the page.

### Systemic: external URL verification rule

The project already had a [`cross-linking.md`](../../.cursor/rules/cross-linking.md) rule for maintaining internal references. External links had no equivalent protection. Two changes:

1. **Always-applied rule** — Added an "External Links — Verify Before Committing" section to the cross-linking rule. The rule states plainly: AI models fabricate plausible-looking URLs. Every new external URL must be fetched before inclusion.

2. **Pre-commit check** — Added external URL verification to the [`/review`](../../.cursor/commands/review.md) command's cross-reference step. The report template now includes an "External URLs: N verified / M broken" line.

The systemic fix follows the same pattern as [debugging AI judgment](debugging-ai-judgment.md): remove the opportunity for the failure rather than relying on vigilance. A rule that says "check URLs" is less reliable than a workflow step that makes checking visible in the review output.

---

## The Meta-Development Pattern

This is the [meta-development loop](../ai-engineering/the-meta-development-loop.md) at its most compact:

1. **Gap** — AI fabricated a URL; no system caught it
2. **Tool** — Rule update (cross-linking.md) + workflow update (/review)
3. **Application** — Applied immediately to the commit that triggered the fix
4. **Feedback** — The incident itself becomes the case study explaining why the rule exists

The loop completed in a single session. The fix shipped in the same commit as the corrected URL, which means the commit message itself documents the lesson: "The previous URL was a 404 — AI fabricated a plausible-looking path."

---

## What This Connects To

The fabricated URL is a small instance of a larger theme in [The Shift](../ai-engineering/the-shift.md): when AI handles the implementation, verification becomes the primary skill. This applies to code, to architecture decisions, and — as this case shows — to the references AI cites in support of its own arguments.

The essay's section 6 discusses how AI output carries uniform confidence regardless of accuracy. The fabricated URL is the reference equivalent: a link that *looks* authoritative is not the same as a link that *is* authoritative. The only way to tell the difference is to check.

---

## Artifacts

| Artifact | What it is |
|---|---|
| [The Shift — Design thinking at scale](../ai-engineering/the-shift.md) | The essay section where the fabricated URL was introduced and corrected |
| [cross-linking.md](../../.cursor/rules/cross-linking.md) | The rule updated with external URL verification |
| [/review](../../.cursor/commands/review.md) | The pre-commit command with external URL checking added |
| [Debugging Your AI Assistant's Judgment](debugging-ai-judgment.md) | Sibling case study — same pattern (notice → name → fix structurally) applied to prioritization bias |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
