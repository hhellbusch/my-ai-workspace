---
title: "Agents Sucked At UI (Until Today)"
speaker: Theo (t3.gg)
channel: Theo - t3.gg
date: 2026-11-03
url: https://www.youtube.com/watch?v=xq0eB8vxeqk
wing: ai-engineering
tags: [ai-engineering, ui, hill-climb, council, screenshots, evals, multi-model, design]
review:
  status: unreviewed
  notes: "AI-generated summary from auto-captions. Model names in the captions are noisy. Needs a watch before citing scores or model IDs."
---

# Theo — Agents Sucked At UI (Until Today)

## Source

- **Speaker:** Theo (t3.gg)
- **URL:** https://www.youtube.com/watch?v=xq0eB8vxeqk
- **Published:** 2026-11-03
- **Duration:** 31:46
- **Transcript:** [cached](../research/theo-agents-sucked-at-ui/sources/agents-sucked-at-ui-until-today.md)

---

## About

31-minute walkthrough of polishing T3 Code's UI by turning taste into a hill climb. A parent agent iterates on real UI; a council of strong models from different providers scores screenshots out of 10, read-only, in rounds. Absolute scores inflated (a self-graded 9 collapsed to ~7.4 once Claude Code and Codex screenshots were in the comparison). Comparative scoring, fresh threads, staged reviewers, and a late human constraint ("too grayscale, put color back") produced a design he was willing to merge. He reports ~18 hours of parallel agent time and on the order of $250–400 in subscription usage. A sponsor segment (Magic Patterns) is not the method.

The second half applies the same shape to a programmatic hill: an eval of T3 Code MCP tool-use failures, then a second goal to cut tool-description tokens while holding a perfect score (~52–78% less context depending on tool search).

Caption noise: he names the council as Opus, "Muse Wonderful," and Codex ("GPT 6.1" / "5.1 Soul" in the captions), plus Gemini via Antigravity as a jester whose score is ignored.

The published skill is [tstack `council`](https://github.com/t3dotgg/tstack/blob/main/skills/council/SKILL.md): three providers, read-only, score out of 10, rounds, PR score table. It does not define a screenshot directory or a blind target. The paste-ready adaptation for another repo is [AGENT-PROMPT.md](../.planning/ui-screenshot-council/AGENT-PROMPT.md). The `design/ui-climb/` layout in that prompt is a Field Notes invention.

---

## Key ideas

### Turn the judgment into a score, then climb

He did not add a pile of design skills or have a designer stare at outputs. He gave the agent a stop condition: screenshots of the app, council agrees at least 9/10, new PR, keep going. The skill text is short — delegates, read-only, score out of 10, one full pass is a round, a review after fixes is a new round.

> "I'm just giving the LLM my mental model for how I would do this. I would look at the new screenshot. I would compare it to the other products and the old screenshot and then score it. And then do it again and again."

Programmatic scores are the better version of the same trick. UI was the case where he only had vibes.

### Absolute scores lie; comparisons discipline them

Round three of an isolated review hit 9/10 from everyone. Alt-tabbing to Claude Code and Codex convinced him it still was not good enough. The same PR, re-scored against those apps, moved about 7 → 7.4, not 6 → 9. Reference screenshots changed the hill. As T3's score rose, the reference apps' scores rose too, on unchanged screenshots — non-determinism, and a reason not to trust a single pass.

### Do not tell the graders the target

When the goal became 9.5 in every category, one model returned exactly 9.5 across the board, then another refused most of those 9.5s. He flags that the sub-agents knowing the target may have pulled scores toward it. Parent should hold the bar; graders should only see screenshots, the rubric, and the references.

### Stage the council; reset context; keep a human taste line

To save usage he ran the cheapest/fastest grader until it cleared, then added the next, and held Gemini back because it was slow and its score did not count. A fresh thread (and later a worktree) continued the climb so a mergeable improvement was not blocked by the chase to 10. The loop still drifted — grayscale, washed-out light mode — until he wrote the preference back in. Council-happy is not the same as something he wanted to look at.

Categories that showed up in the climb: iconography, typography, hierarchy, color, contrast, plus consistency of labels, radius, fonts, and indicators.

### Same shape, real eval

For MCP behavior he collected his own failure cases, scored models against them, required a perfect score, then inverted the goal: delete description text until context was about a third, without losing the perfect score. The score went down after one edit; that was the point of having the eval.

---

## What he would skip

- Gemini-as-jester. Entertainment. It delayed rounds and its score was discarded.
- `/goal` as magic. He still thinks a clear prompt does the same work.
- Chasing 10/10 on the first loop. The useful jump was "better than our current UI, and then better than the reference apps," with a human look between stages.
