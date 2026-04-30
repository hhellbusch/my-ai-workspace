# How AI Handles Evolving Creative Scope Across Sessions

> **Audience:** Anyone using AI for multi-session creative or intellectual projects where the human's understanding evolves during the work — not just the output, but the framing itself.
> **Purpose:** Documents how a project's scope broadened and self-corrected across multiple sessions, and names two distinct kinds of scope evolution that require different moves.
> *Context:* This workspace includes an essay series connecting martial arts philosophy to AI-assisted engineering. The author trained in Hayashi-ha Shito-ryu karate (an Okinawan tradition). This case study documents how the project scope evolved as the author's thinking grew.

---

## The Core Problem

AI treats documents as ground truth. When a project's scope changes, the AI updates documents to match — but only what you tell it to change. This creates two risks that look the same from the outside but require different fixes.

**Coverage expansion** is when the project needs to include more territory: more traditions, more examples, more themes. The AI can handle this — update the brief, broaden the style guide, cascade the change across related documents as a set.

**Frame dissolution** is when the organizing principle itself is wrong — when the question the brief is answering isn't the question the project is actually trying to answer. The AI cannot do this. It reads the brief as authoritative and optimizes within its frame. Only deliberate pressure from outside that frame — a peer who doesn't understand the document, an explicit user decision, a milestone moment — creates the opening to question the structure itself.

Most scope evolution starts as coverage expansion and gets treated as resolved. The frame question doesn't surface until something from outside the project hits it.

---

## The Case

The project started as **"Zen and Karate"** — a series of essays connecting Zen Buddhism and karate practice to productivity, teamwork, and ways of working. The brief, planning documents, and research workspace were all framed around this specific intersection.

**Coverage expanded.** During a conversation about ideation threads, the author said they'd been exploring martial arts traditions beyond Japan and Okinawa and wanted the project to reflect that. The brief was updated ("Martial Arts, Zen, and the Way of Working"), the style guide broadened its terminology section, and personal notes and thread documents were updated in the same session. Every document said the same thing: martial arts broadly, karate as the primary lens. The directory names stayed as `zen-karate/` — renaming would have broken links and git history for no semantic gain.

**A nuance was captured, incompletely.** The author made a distinction between Okinawan karate (closer to the original *te* and *tode*, strong Chinese influence, more fluid and circular) and the karate Gichin Funakoshi formalized for mainland Japan (Shotokan, the 3K structure of kihon/kata/kumite, large-scale systematic teachability). Then self-corrected: Funakoshi's karate is still karate. The personal notes were updated to reflect this — but the framing that survived still centered Okinawan as the reference point ("different flavor, not better or worse"). The more accurate framing: each tradition solved a different problem. Hayashi-ha Shito-ryu carries Okinawan and Chinese influence and a particular relationship to kata. Shotokan answered mass teachability at scale. Neither is a reference point for the other.

**The frame question didn't follow.** The brief now reads: "Karate is the primary lens because that's where the author's decades of practice live." Coverage expanded from "karate" to "martial arts broadly." The organizing frame — karate as the lens through which everything else is seen — didn't change. If the essays are reaching toward something closer to *no-style* (the principles transcend any tradition; every tradition is one path toward them), that's a frame question, not a coverage question. And the AI continued treating "karate as primary lens" as the authoritative structure, because the brief said so.

---

## What Made This Work

**Update documents as a set.** When the scope changed, every relevant document was updated in the same session. The brief, style guide, personal notes, and threads all said the same thing. A future session reading any one of them got the same scope. AI sessions read documents independently — conflicting signals between files produce inconsistent output.

**The cross-linking rule caught the cascade.** The workspace convention ("when a directory's scope changes, check its parent README") prompted updates to the research README and roadmap descriptions that wouldn't have been obvious from inside the conversation.

**Directory names stayed stable.** Renaming `.planning/zen-karate/` to reflect the broadened scope would have been semantically accurate and operationally destructive. Names are handles, not definitions.

---

## What Made This Hard

**The AI treats current documents as ground truth — not their history.** It can't tell a future session "this project started narrower and broadened because the user's learning expanded." It can only present the current state. The git history captures the evolution; AI sessions don't read git history. This case study is one attempt to make the evolution legible.

**Coverage expanded; the frame didn't dissolve.** The scope is now "martial arts broadly." The frame is still "karate as primary lens." Those are consistent — but if the essays are reaching toward no-style, they aren't aligned. The AI can't surface that gap because both statements are true and consistent inside the documents. The frame question requires someone outside the project (or the author stepping outside it) to see.

**Subtle shifts don't propagate.** The "what each tradition solved" reframing is a tonal shift, not a structural one. It doesn't show up in file lists or link audits. It only matters when prose is being written. No convention in the current set catches tonal drift.

---

## What Conventions Help

| Convention | How it helps |
|---|---|
| Update documents as a set | Eliminates conflicting signals across files |
| Cross-linking scope-change trigger | Catches cascade effects from broadening or narrowing |
| Stable directory names | Avoids link breakage when content evolves |
| Nuanced framing over binary positions | Gives the AI an honest position to write from |
| Personal notes as a living document | Captures the author's current understanding, not a fixed persona |

## What Conventions Are Missing

| Gap | Status | Why it matters |
|---|---|---|
| No distinction between coverage expansion and frame dissolution | **Addressed** — [`shoshin.md`](../../.cursor/rules/shoshin.md) "When the Document Itself May Be Wrong" names the triggers and the diagnostic question | Without the distinction named, AI treats all scope changes as coverage changes and misses the frame question entirely |
| No "project evolution" log | **Already existed** — [`.planning/zen-karate/CHANGELOG.md`](../../.planning/zen-karate/CHANGELOG.md) captures *why* scope shifted, not just what changed | Git history has the diffs; the reasoning doesn't survive without an explicit log |
| No cross-session tonal drift detection | **Still missing** — `/audit` checks links, registries, and biographical content but not whether prose framing has drifted from the author's current understanding | Structural changes cascade; tonal shifts don't — they only surface when the AI writes prose and the author reads it feeling slightly off |

---

## What the Human Brought

Every scope change in this case study originated from the author: the broadening from karate to martial arts, the Okinawan-vs-Japanese distinction, and the self-correction that Funakoshi's karate is still karate. The AI updated documents; the author's evolving understanding drove what they said. The frame question — whether "karate as primary lens" is still the right organizing principle — is also the author's to answer, not the AI's.

## When This Applies — and When It Doesn't

**Good fit:**
- Multi-session creative or intellectual projects where the human's understanding is still developing
- Projects with directory-based organization where scope changes cascade through naming, framing, and cross-references
- Work where multiple documents share an implicit scope definition that could drift silently

**Not needed for:**
- Technical projects with fixed requirements where scope is established before work begins
- Short single-session tasks where scope evolution isn't a risk
- Projects where the AI's role is implementation rather than framing — scope evolution matters most when the AI is writing prose that carries implicit claims about what the project covers

---

## Artifacts

| Artifact | What it is |
|---|---|
| [BRIEF.md](../../.planning/zen-karate/BRIEF.md) | Project brief — broadened from "Zen and Karate" to "Martial Arts, Zen, and the Way of Working" |
| [STYLE.md](../../.planning/zen-karate/STYLE.md) | Voice and style guide — "Terminology from Source Traditions" (was "Japanese Terminology") |
| [personal-notes.md](../../research/zen-karate-philosophy/personal-notes.md) | Personal knowledge base — training history, tradition distinctions |
| [threads.md](../../.planning/zen-karate/threads.md) | Ideation threads — scope note added, 14 threads spanning the broadened scope |
| [cross-linking rule](../../.cursor/rules/cross-linking.md) | Convention that caught the cascade of scope changes |

## What Happened Next

The gaps identified in "What Conventions Are Missing" above led directly to the [shoshin meta-system integration](../../.cursor/rules/shoshin.md) — an always-applied rule, fresh-eyes checks in [`/start`](../../.cursor/commands/start.md), assumptions tracking in [`/whats-next`](../../.cursor/commands/whats-next.md), and brief-alignment drift detection in [`/review`](../../.cursor/commands/review.md). The full story of how this case study produced the system improvements it was documenting the absence of is in [When Case Studies Generate System Improvements](case-studies-as-discovery.md).

The coverage-vs-frame distinction surfaced later — documented in the [shoshin rule update](../../.cursor/rules/shoshin.md) under "When the Document Itself May Be Wrong."

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
