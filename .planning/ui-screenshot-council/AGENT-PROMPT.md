# Agent prompt — UI screenshot council

**Use:** Paste into an agent session whose working directory is the **foreign project** whose web UI you want improved.

Fill Configuration, then run. Stop before merge.

This prompt is self-contained. You do not need any other repo.

---

## Provenance (do not conflate these)

Two sources, kept separate on purpose:

1. **Published skill.** [tstack `council`](https://github.com/t3dotgg/tstack/blob/main/skills/council/SKILL.md) by Theo (t3.gg). Three strong models from different providers, read-only, score out of 10, each full pass is a round, a review after fixes is a new round, scores go in the PR description, do not let reviews widen scope. If you cannot reach three providers, say so. Do not invent a substitute and pretend it is the third.
2. **This prompt.** A Field Notes adaptation of his 2026-11-03 talk "Agents Sucked At UI (Until Today)". The `design/ui-climb/` directory, the rubric file, reference screenshots, and "do not tell graders the target number" are **not** in tstack. Do not cite them as his skill.

His personal council in the talk also differs from the published skill: Gemini was a jester whose score he ignored. Do not add a jester. Use models you can actually call. Latest flagship per provider is enough. Caption names in the talk (Opus "5.5", "GPT 6.1", "Muse Wonderful") are unreliable; ignore them.

The Magic Patterns segment of the talk is a sponsor read. Ignore it.

---

## Configuration

```text
TARGET_WORKSPACE_NAME: <short name>
HARNESS: <Cursor | Claude Code | Codex | other>
SCREENS: <3–6 routes or states. Include one dense and one empty. Light and dark if both ship.>
REFERENCES: <1–2 products this UI should beat. Or "propose".>
VIEWPORT: 1440x900
ROUND_BUDGET: 3
TASTE: <optional hard constraints, e.g. "keep color; do not collapse to gray">
OUTPUT_DIR: design/ui-climb
```

---

## Objective

Improve this project's web UI by hill-climbing on **screenshots**, not on the implementer's opinion of its own CSS.

A parent turn edits. Separate grader turns score images. The parent holds the stop condition. Graders never see it.

Outcome after at most `ROUND_BUDGET` rounds: captures, a score log, and a branch of visual changes. No merge.

---

## Method

1. **Confirm it is a web UI.** Find how it runs. If you cannot render it, stop and say what is missing. Do not grade a description of the DOM.
2. **Pick screens.** Use `SCREENS`. If `REFERENCES` is `propose`, name 1–2 peer products in the score log before capturing them, so the human can reject the choice.
3. **Scaffold `OUTPUT_DIR/`** (this layout was invented for this prompt; create it):
   - `rubric.md` — categories: hierarchy, typography, iconography, color, contrast, consistency (labels, radius, type, indicators). Describe a weak score and a strong score in words. **No target number in this file.**
   - `references/` — screenshots of the reference products, same viewport, same kinds of screens.
   - `captures/` — this app, named by route + theme + state. Recapture after every round. Keep the previous round.
   - `scores.md` — append-only. Parent reads it. Graders do not.
4. **Capture pixels.** Playwright if the repo already has it. Otherwise the harness browser. Same viewport every time.
5. **Add one deterministic check** if the stack already supports it (axe, Playwright accessibility scan, or an existing contrast test) on the same routes. Council scores are for hierarchy, density, and whether it looks like one product. Contrast ratios should not be a vibe.
6. **Round loop**, up to `ROUND_BUDGET`:
   - Implementer: rubric, current captures, references, `scores.md`, and `TASTE`. Change the lowest categories. Keep behavior the same. Do not grade yourself.
   - Recapture.
   - Graders, **fresh context, read-only**, one per provider you can actually reach. Give them only: rubric, reference images, current captures. Ask for a 1–10 per category, one sentence each, and the three changes that would move the lowest category. Do not include the stop condition, the target number, the round budget, or your rationale.
   - Append a table to `scores.md`: round, model, category scores, one-line disagreement.
   - Stage cost: run the first grader to completion. Bring the next provider in when the first is no longer naming easy inconsistencies. A second provider is the useful council. A third is optional.
   - If a grader's advice fights `TASTE` or widens scope (new features, new IA, a rewrite), reject it in the log and do not apply it.
7. **Branch, don't merge.** Commit on a feature branch if the human asked you to commit. Do not push unless asked. Do not merge. If the app already has a design flag, put the visual change behind it. Do not invent a flag framework for this.
8. **Stop.** Summarize before/after paths, the score table, what you refused, and whether a human should look before any further rounds. Chasing 9.5 or 10 is a separate decision. His long run moved reference scores on unchanged screenshots and drifted gray until a human wrote "put color back."

Parent-only stop condition (never copy this into a grader prompt or into `rubric.md`):

> Stop early if two providers both score this UI above the reference screenshots on hierarchy, contrast, and consistency. Otherwise stop at `ROUND_BUDGET` and hand back.

---

## `scores.md` shape

```markdown
# UI climb — <TARGET_WORKSPACE_NAME>

References: <what you captured and why>
Screens: <list>
Viewport: 1440x900
Taste constraints: <TASTE or none>

## Round 1
| Delegate | Hierarchy | Type | Icons | Color | Contrast | Consistency | Note |
|---|---|---|---|---|---|---|---|
| <model> | | | | | | | |

Refused this round:
- 

## Round 2
```

---

## Constraints

- Evidence from **this** repo's running UI. No generic design sermon.
- Graders do not edit files.
- Do not tell graders the target score. He watched a model return exactly 9.5 in every category after the prompt said 9.5.
- An isolated "this is a 9" is a weak signal. The talk's self-graded 9 fell to about 7.4 once other products' screenshots were in the comparison.
- Foreign workspace: do not assume Field Notes paths, Cursor rules, or Pi skills exist.
- Do not mark anything reviewed or approved.
- Do not rewrite git history.
- If the UI is already tighter than the references, say so and stop. Few edits is a valid outcome.
