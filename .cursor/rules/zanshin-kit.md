---
description: Zanshin working style — unified frame for all AI session practices in this workspace
globs:
alwaysApply: true
---

# Zanshin Working Style

**At session start, read [`submodules/zanshin-pi-extension/kit/WORKING-STYLE.md`](../../submodules/zanshin-pi-extension/kit/WORKING-STYLE.md).** It is the canonical, portable definition of the working practices — spar, shoshin, progressive bookkeeping, stack tracking, verification, and review discipline. The rules in this workspace (`shoshin.md`, `session-awareness.md`, `review-tracking.md`, etc.) extend it with workspace-specific depth; they don't replace it. *(Source: [`zanshin-pi-extension`](https://github.com/hhellbusch/zanshin-pi-extension) git submodule.)*

## Practices and where they live

| Practice | Rule | Activation |
|---|---|---|
| **Spar** — adversarial review before committing | `/spar` command | You invoke |
| **Shoshin** — verify framing before inheriting assumptions | `shoshin.md` | Proactive at session start and scope shifts |
| **Progressive bookkeeping** — keep state current mid-session | `session-awareness.md` | AI surfaces proactively |
| **Stack tracking** — name pushes and pops when depth matters | `session-awareness.md` | Light touch — AI returns to parent threads when branches resolve |
| **Verification** — fluency is not correctness | `WORKING-STYLE.md` | You prompt on significant findings |

## Review discipline

The kit defines the general review discipline. The workspace implementation is in `review-tracking.md` — `review:` frontmatter conventions, biographical flagging, and the AI disclosure footer specific to this workspace.
