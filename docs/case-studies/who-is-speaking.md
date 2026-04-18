# Who Is Speaking? — When AI Writes in Your Voice

> **Audience:** Engineers, writers, and anyone publishing AI-assisted content where readers will attribute the words to a human author.
> **Purpose:** Documents how a concern about AI-generated biographical content — professional titles, experience claims, personal opinions — led to a new validation type (`voice-approved`) integrated at every checkpoint in the project's workflow.

---

## The Concern

The project uses AI to draft essays, case studies, and documentation. The standard [AI disclosure](../../AI-DISCLOSURE.md) is transparent about this: most content was created with AI assistance and has not been fully reviewed by the author. Review tracking distinguishes between `read`, `fact-checked`, `tested`, and other validation types.

But during a review of existing essays, the author noticed a category of content that didn't fit any existing validation type: **content that speaks in the author's voice.**

Sentences like "an infrastructure engineer with no image processing background" or "the person running this session works in enterprise infrastructure and consulting" made claims about who the author is. These weren't factual claims about external topics — they were identity claims. Readers would attribute them directly to the author as autobiography.

The problem: the AI generates these statements freely. It picks up contextual cues (the workspace is about DevOps, the user mentions karate training) and weaves them into confident first-person prose. Some of these statements are accurate. Some embellish. Some are entirely fabricated from plausible inference. And from the outside, they all look the same.

---

## Why `read` Isn't Enough

The existing review system treats all content equally. Marking a file as `read` means the author has read through it. But reading a technical explanation and reading a sentence that claims to be your own biographical experience are different acts:

- **Technical content** — If the AI says "vLLM supports continuous batching," that's a factual claim you can verify against documentation. Getting it wrong is an error.
- **Biographical content** — If the AI says "in my years of practice, I've found that discipline enables freedom," that's a statement of personal belief attributed to you. Getting it wrong is putting words in your mouth.

The distinction matters because biographical content has a higher trust threshold. Readers treat "I believe" differently than "the documentation says." They take first-person claims as direct evidence of who the author is and what they've experienced.

A general `read` validation doesn't surface this distinction. You could read an entire essay, validate the technical content, and miss that a sentence in the philosophical section fabricated a training experience you never had.

---

## The Design: `voice-approved`

The fix was a new validation type — `voice-approved` — with elevated priority and integration at every checkpoint in the workflow.

### At generation time

The [review tracking rule](../../.cursor/rules/review-tracking.md) and the [project style guide](../../.planning/zen-karate/STYLE.md) now instruct the AI to:

- Avoid fabricating biographical details about the author
- Use general framing ("a practitioner might notice...") when personal voice is needed but the author hasn't provided the specific detail
- Flag biographical content explicitly when generated: "This draft contains biographical statements on lines N-M that need your `voice-approved` review"

This doesn't prevent biographical content — some essays require it. It shifts the default from "generate freely, hope the author catches it" to "generate cautiously, flag what needs attention."

### At commit time

The [`/review`](../../.cursor/commands/review.md) pre-commit command now includes a biographical/voice check (step 6) that scans changed `docs/` files for:

- Professional titles or role descriptions applied to the author
- First-person claims about experience, training, or career
- Personal opinions stated as fact
- Biographical details (training history, personal philosophy, specific life events)

Flagged lines appear in a dedicated "Biographical Content — Needs `voice-approved`" section of the review report, with file paths and line numbers. This is the highest-priority section — above issues, above cross-reference checks.

### At audit time

The [`/audit`](../../.cursor/commands/audit.md) content health check (Layer 5b) scans all `docs/` essays for biographical patterns and cross-references against `voice-approved` frontmatter. Files with biographical content but no `voice-approved` validation are the highest-priority review items.

### At validation time

The [`/validate`](../../.cursor/commands/validate.md) command recognizes `voice-approved` as a type. If an author validates a `docs/` file with `read` but the file contains biographical content, the command prompts: "This file contains biographical content. Consider also running `/validate <path> voice-approved` after reviewing those sections."

---

## What Triggered This

The immediate trigger was a sentence in [Using AI to Work Outside Your Expertise](../ai-engineering/ai-for-unfamiliar-domains.md): "The person running this session works in enterprise infrastructure and consulting, not image processing." The author's response was direct: remove it. The professional identity label wasn't relevant to the point, and it was a claim the AI had generated, not one the author chose to make.

That single edit surfaced the broader concern: how many other files contain identity claims the author didn't write and hasn't reviewed? The answer, across a repository with 16 essays, multiple case studies, and extensive planning documents using personal voice, is likely "many."

The `voice-approved` system doesn't require reviewing everything immediately. It makes the gap visible and gives the author a way to close it incrementally — the same organic, file-at-a-time approach the broader review tracking system uses.

---

## The Pattern

This follows the same [meta-development loop](../ai-engineering/the-meta-development-loop.md) as other case studies in this series:

1. **Gap** — AI writes biographical content freely; no system distinguishes it from technical content
2. **Tool** — New validation type (`voice-approved`) with detection patterns and workflow integration
3. **Application** — Applied immediately: the essay edits that triggered the concern were the first content reviewed under the new standard
4. **Feedback** — The system revealed that the broader concern (biographical fabrication) was a specific instance of the trust problem documented in [The Shift](../ai-engineering/the-shift.md): AI output carries uniform confidence regardless of whether it's accurate, and the only way to tell is to check

The novel element is that this gap isn't about *correctness* — it's about *identity*. The AI can fabricate a biographical claim that's technically true (the author does work in infrastructure) but still misrepresents the author's intent by making a claim they didn't choose to make. This is a trust problem that `fact-checked` can't catch.

---

## What the Human Brought

The concern was the author's — triggered by a single sentence that claimed a professional identity the author hadn't chosen to state. The author's response ("remove it") and the follow-on question ("how many other files contain identity claims I didn't write?") drove the `voice-approved` system. The distinction between reading content and approving content that speaks *as you* came from that author-specific concern. An AI reviewing biographical accuracy would check the facts; it would not ask the identity question.

## Artifacts

| Artifact | What it is |
|---|---|
| [review-tracking.md](../../.cursor/rules/review-tracking.md) | The rule defining `voice-approved` and biographical content patterns |
| [/review](../../.cursor/commands/review.md) | Pre-commit command with biographical/voice check (step 6) |
| [/audit](../../.cursor/commands/audit.md) | Content audit with Layer 5b biographical scan |
| [/validate](../../.cursor/commands/validate.md) | Validation command with `voice-approved` type and prompting |
| [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) | Disclosure policy documenting `voice-approved` significance |
| [STYLE.md](../../.planning/zen-karate/STYLE.md) | Style guide with biographical caution in personal voice section |
| [The Shift — section 6](../ai-engineering/the-shift.md) | The confidence uniformity problem this case study extends |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
