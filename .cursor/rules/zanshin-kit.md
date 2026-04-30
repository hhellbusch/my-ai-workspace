---
description: Zanshin working style — unified frame for all AI session practices in this workspace
globs:
alwaysApply: true
---

# Zanshin Working Style

This workspace uses the **Zanshin** working style. All five practices are active by default. The canonical source document is [`zanshin-kit/WORKING-STYLE.md`](../../zanshin-kit/WORKING-STYLE.md).

## Practices and where they live

| Practice | Rule | Activation |
|---|---|---|
| **Spar** — adversarial review before committing | `/spar` command | You invoke |
| **Shoshin** — verify framing before inheriting assumptions | `shoshin.md` | Proactive at session start and scope shifts |
| **Progressive bookkeeping** — keep state current mid-session | `session-awareness.md` | AI surfaces proactively |
| **Stack tracking** — name pushes and pops when depth matters | `session-awareness.md` | Light touch — AI returns to parent threads when branches resolve |
| **Verification** — fluency is not correctness | This rule | You prompt on significant findings |

## Verification — the practice not covered elsewhere

AI output that sounds confident may still be wrong. Fluent prose covers both assertion and evidence — the two are indistinguishable from the texture of the output alone.

**Before treating any AI-generated finding as settled:**
- Is this an assertion or evidence? What's the source?
- For technical claims: what's the primary source? Paraphrase chains degrade quickly.
- For code: test it — don't read and assume it works.
- For plans: "If this is wrong, how would I know?" — if there's no answer, it hasn't been verified.

**The practical test:** Can you point to the thing that would prove this wrong? If not, you're trusting fluency.

This practice is human-prompted: "verify that before we proceed." The AI cannot apply verification discipline to its own output in real time — it states findings with the same fluency whether verified or not.

## Spar and shoshin together

Apply **shoshin before spar** when the problem itself may be mis-stated. Apply **spar after shoshin** when the problem is clear but the solution needs challenge. Spar challenges a solution; shoshin challenges the framing underneath it.

## Source document

[`zanshin-kit/WORKING-STYLE.md`](../../zanshin-kit/WORKING-STYLE.md) — version-dated snapshot. If practices feel off or outdated, re-copy from the source workspace.
