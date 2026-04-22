# Style Guide

> Workspace-level defaults for all content in this repo. Project-specific supplements
> live in `.planning/{project}/STYLE.md` and extend or override these defaults for that track.
> Check this file first; check the project supplement when working on a specific project.

---

## Voice and tone

**Default register:** Practitioner voice — observation from practice, not prescription. "This is what I've found" rather than "you should do this." Second person or inclusive "we" for applied sections; first person only when the author has directly provided that content.

**Brevity:** Prefer shorter over longer. Cut before adding. One precise sentence beats three that circle.

**Claims:** Pair assertions with their limits. State what's unverified when it is. Avoid performed confidence — fluent prose is not evidence.

**Audience:** Peers who are skeptical of jargon and value precision. Write for someone landing on a single file via a direct link — not for someone navigating the full workspace. Relative links are preferred; they resolve on GitHub and let readers navigate the collection.

---

## Structure — docs/

All essays, case studies, and guides in `docs/` follow this structure:

- **Title:** `#` heading, optionally with an em-dash subtitle
- **Front matter:** Blockquote with bold **Audience:** and **Purpose:** lines
- **Section breaks:** Horizontal rules `---` between major thematic blocks
- **Hierarchy:** `##` for main sections, `###` for subtopics
- **AI Disclosure footer:** Every new file in `docs/` (excluding READMEs) includes the standard footer:
  *This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
  Adjust relative path based on file depth. If the author has reviewed: update to "has been reviewed by the author."

---

## Content tracks

Each track in `docs/` has a distinct purpose that determines framing:

- **`ai-engineering/`** — Practical patterns for AI-assisted engineering. Transferable, grounded in real work, honest about what doesn't work. Not tutorial content.
- **`philosophy/`** — Applied philosophy from practice to engineering culture. Practitioner-grounded, not academic. Insight must land with someone in a production meeting.
- **`case-studies/`** — Named patterns documented from real sessions. What happened, what it demonstrates, what it connects to. Specific over abstract.

**Cross-track priority:** AI engineering and case studies lead. Philosophy supports — it responds to what AI engineering diagnoses. When prioritizing across tracks, this order applies. For prioritization *within* the zen-karate essay series specifically, see `.planning/zen-karate/STYLE.md` (*Guiding Stars*).

---

## Biographical content

Any first-person claim a reader would attribute directly to the author requires `voice-approved` validation before it's considered reviewed:

- Professional titles or role descriptions
- Claims about personal experience ("in my years of practice...")
- Opinions presented as the author's
- Biographical details

When biographical content is needed and the author hasn't provided the specific detail, use general framing ("a practitioner might notice...") rather than fabricating a claim. Flag it at generation time: "This draft contains biographical statements on lines N–M that need voice-approved review."

---

## Cross-linking in prose

When mentioning a specific file, command, rule, or skill by name in prose, link it on first mention in that section. Do not repeat the link within the same section. The reader should be able to follow the reference without searching.

---

## Project-specific supplements

When a project needs style conventions beyond these defaults, add a `STYLE.md` to its `.planning/` directory. It extends or overrides the workspace defaults for that project only.

Current supplements:
- **`.planning/zen-karate/STYLE.md`** — voice, terminology, and essay-format specifics for the martial arts / philosophy series
