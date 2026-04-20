---
review:
  status: unreviewed
---

# When the Meta-Document Tries to Be the Catalog

> **Audience:** Engineers managing documentation-heavy projects with structured registries, indexes, or meta-files that describe the project's own contents.
> **Purpose:** Documents how a workspace meta-file (`.cursorrules`) accumulated stale inventory by duplicating what other documents authoritatively tracked — and how recognizing the root cause led to a structural fix that eliminated the drift source rather than demanding better update discipline.
> *Context:* This workspace uses `.cursorrules` as a high-level orientation file for the AI assistant (Cursor with Claude). It describes the repository's purpose, structure, and active tracks. The workspace also maintains three content tracks (`docs/ai-engineering/`, `docs/philosophy/`, `docs/case-studies/`) each with their own `README.md` as the authoritative index for that track.

---

## The Symptom

During a meta-system review, the AI referenced "fifteen documented meta-development patterns" when describing the case studies track. The actual count was twenty-five. The AI was operating from `.cursorrules`, which contained inline title lists and hardcoded counts for all three documentation tracks.

The drift had accumulated gradually:
- New documents were added (with the track README updated correctly)
- `.cursorrules` was not updated
- The AI's orientation file described an older version of the corpus
- No session had been jarring enough to notice — the counts and titles were wrong by degrees, not obviously

It surfaced during a session specifically focused on asking "why does the AI sometimes describe stale inventory?"

---

## The Root Cause

`.cursorrules` had been serving two purposes:

1. **Orientation** — describing the workspace's purpose, philosophy, and active tracks (appropriate)
2. **Inventory** — enumerating document titles, counting case studies, listing essay names by position (inappropriate — this duplicates what the track READMEs authoritatively track)

The duplication created a maintenance trap: any document added to a track required updating *both* the track README (the canonical index) and `.cursorrules` (the meta-description). In practice, the track README always got updated — the cross-linking rule requires it, and it's the place you naturally go when adding a document. But `.cursorrules` was updated only when someone noticed it was wrong.

The track READMEs were the source of truth. `.cursorrules` was a stale copy of them.

---

## Why This Pattern Recurs

Meta-documents that describe other documents have a natural pull toward specificity. When the AI reads `.cursorrules` to orient itself, more detail feels more useful. Titles and counts feel informative. The first time the information is accurate, it *is* more informative.

The problem is the maintenance obligation that comes with it. Specificity requires synchronization. The more detailed `.cursorrules` is about content, the more updates it needs when content changes. And content changes more frequently than anyone updates the description of the content.

This is a general documentation anti-pattern: **any document that describes another document's contents will drift toward staleness, at a rate proportional to how specific the description is.**

The correct relationship is indirection:
- `.cursorrules` should say: "the case studies track is in `docs/case-studies/` — see the README for the full catalog"
- Not: "there are fifteen case studies, including adversarial review, fabricated references, debugging AI judgment..."

---

## The Fix

**1. Remove inventory from `.cursorrules`**

Removed all inline title lists and hardcoded counts from the three documentation track descriptions. Replaced with: one sentence describing the track's purpose, and a pointer to the track README as the authoritative index.

Before:
```
docs/case-studies/ — Fifteen documented meta-development patterns including: Adversarial
Review as a Meta-Development Pattern, When AI Fabricates the Evidence for Its Own
Argument, [13 more titles]...
```

After:
```
docs/case-studies/ — Documented meta-development patterns capturing real instances of
how AI-assisted workflows succeed, fail, and generate their own tooling. See
docs/case-studies/README.md for the full catalog.
```

The track README is where the catalog lives. `.cursorrules` now points there rather than duplicating it.

**2. Encode the principle in cross-linking conventions**

Added a section to `.cursor/rules/cross-linking.md`: "`.cursorrules` is orientation, not inventory." This makes the design intent explicit for future sessions — the agent can read the rule and understand why `.cursorrules` should not enumerate document lists.

---

## What the Human Brought

The observation that triggered the fix was direct: "this list often gets stale and doesn't get updated; let's consider this session and determine if anything should be changed so you operate better."

The agent had been operating on stale inventory without flagging it. The user noticed the pattern across sessions (staleness recurring) and named the mechanism (the inline list in `.cursorrules`). The fix — removing inventory from the orientation file — required understanding that the solution was structural, not behavioral. A behavioral fix (add "update `.cursorrules` whenever you update track READMEs" to the cross-linking rule) would address the symptom; removing the inventory addresses the cause.

---

## Broader Pattern

**Duplication creates drift.** When two documents track the same information, the less-authoritative one will fall behind. The fix isn't better synchronization discipline — it's eliminating the duplication.

| Source | Summary document | Pattern |
|---|---|---|
| track `README.md` (authoritative) | `.cursorrules` (orientation) | The orientation file duplicated the registry |
| Code (authoritative) | README listing function names | The README drifts as functions are renamed |
| Constants file (authoritative) | Config file copy | The config falls behind constants |

In each case, the temptation is to add synchronization reminders: "remember to update both." The durable fix is single-source authority: one document is canonical, the other points to it.

---

## Connection to Related Case Studies

| Case Study | Relationship |
|---|---|
| [Stale Context in Long Sessions](stale-context-in-long-sessions.md) | AI operating on stale *conversation* context; this is AI operating on stale *repo meta-data* |
| [When Case Studies Generate System Improvements](case-studies-as-discovery.md) | Same session pattern: meta-system review as discovery mechanism |
| [When the Source Says the Opposite of the Claim](context-stripped-citations.md) | Different root; shared theme of trusting a summary over the primary source |

---

## Artifacts

| Artifact | What it is |
|---|---|
| [`.cursorrules`](../../.cursorrules) | Orientation file — now description-only, no inventory |
| [`.cursor/rules/cross-linking.md`](../../.cursor/rules/cross-linking.md) | Added "orientation, not inventory" principle |
| [`docs/case-studies/README.md`](README.md) | Authoritative catalog — canonical index, not `.cursorrules` |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
