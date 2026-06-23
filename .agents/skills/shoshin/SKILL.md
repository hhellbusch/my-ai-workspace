---
name: shoshin
description: Surface assumptions collaboratively before proceeding — beginner's mind, invoked depth
argument-hint: "[file path | topic | inline content from conversation]"
allowed-tools: Read Grep Glob Shell SemanticSearch
---

# Shoshin — Invoked (Workspace)

<objective>
Deliberately bring beginner's mind to the foreground for this workspace. Follow the portable core process, then apply workspace-specific artifact and frame-check conventions.
</objective>

## Core process

Read and follow **`submodules/zanshin-pi-extension/skills/shoshin/SKILL.md`** in full. That file is authoritative for the invoked workflow (collaborative assumption-surfacing, questions before building).

## Workspace artifacts

When gathering ground truth (Step 2 of the core process), check these in order of authority:

| Priority | Artifact | Role |
|---|---|---|
| 1 | `ABOUT.md` | Owner identity and priorities — precedes corpus inference |
| 2 | `.planning/<project>/BRIEF.md` | Authoritative scope (project = most recently modified BRIEF) |
| 3 | `BACKLOG.md` | Current work state (`> State:` line) |
| 4 | `.planning/<project>/whats-next.md` | Session handoff — verify against brief, don't inherit blindly |
| 5 | `STYLE.md` / `.planning/<project>/STYLE.md` | Writing conventions when content is involved |
| 6 | Recent `git log` | When handoff may be stale or work evolved since last session |

If brief and handoff conflict, **surface the conflict** and ask which framing to use.

## Frame-check (invoked)

When the target is a plan, epic, brief, or design doc, also ask:

> *Is this asking the right question — or a well-written answer to the wrong one?*

**Audience and purpose (TAGRI):** Who reads this? What decision does it enable? If unclear, ask before expanding.

Signals that warrant frame-check (from ambient `AGENTS.md`):

- External feedback shows fundamental confusion about what the document is trying to do
- A structural choice survives review but still feels off
- Author intent has evolved beyond what the brief can express
- Major transition: first external review, publish, handoff to new contributor

Name the ceiling honestly: shoshin verifies framing against documents; if the document embeds the wrong frame, user pushback or explicit reframing is the exit.

## Ordering with spar

Apply **shoshin before spar** when the problem may be mis-stated. Apply **spar after shoshin** when framing holds but the solution needs challenge.
