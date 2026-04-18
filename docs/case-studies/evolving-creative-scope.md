# How AI Handles Evolving Creative Scope Across Sessions

> **Audience:** Anyone using AI for multi-session creative or intellectual projects where the human's understanding evolves during the work — not just the output, but the framing itself.
> **Purpose:** Documents how a project's scope broadened, narrowed, and self-corrected across multiple sessions as the user's thinking evolved, and what conventions helped or hindered the AI's ability to maintain coherence across documents.

---

## The Starting Scope

The project started as **"Zen and Karate"** — a series of essays connecting Zen Buddhism and the author's karate practice to productivity, teamwork, and happiness at work. The user had trained in Hayashi-ha Shito-ryu karate and was influenced by Shi Heng Yi's teachings. The initial brief, planning documents, and research workspace were all framed around this specific intersection.

The scope was clear: Zen + karate + applied philosophy. Everything was named accordingly — `zen-karate-philosophy/` research directory, `zen-karate/` planning directory, threads referencing karate-specific concepts.

---

## The First Expansion

During a conversation about ideation threads, the user said: "while my training has been in karate — i would like to perhaps widen it to be martial arts in general — i have been expanding my learnings beyond just japan/okinawa lately. just so happens my expertise in karate in particular."

This wasn't a reframing. It was the user's learning expanding in real time. They'd been exploring martial arts traditions beyond Japan and Okinawa, and the project scope needed to reflect that growth.

The change cascaded through multiple documents:

- **[BRIEF.md](../../.planning/zen-karate/BRIEF.md)** — title changed from "Zen, Karate, and the Way of Working" to "Martial Arts, Zen, and the Way of Working." One-liner and problem sections updated. The brief now explicitly states: "The scope is deliberately wider than one style or tradition."
- **[STYLE.md](../../.planning/zen-karate/STYLE.md)** — "Japanese Terminology" section renamed to "Terminology from Source Traditions" and expanded to include terms from other martial traditions.
- **[personal-notes.md](../../research/zen-karate-philosophy/personal-notes.md)** — Training history updated to note "Expanding beyond karate: Recently broadening study beyond Japan/Okinawa into martial arts more broadly."
- **[threads.md](../../.planning/zen-karate/threads.md)** — scope note added: "Martial arts broadly, with karate (Hayashi-ha Shito-ryu, Okinawan tradition) as the primary lens."

The directory names stayed as `zen-karate` — renaming would have broken links and git history for no semantic gain. The content inside the directories broadened while the container names stayed stable.

---

## The Correction

In the same conversation, the user made a distinction: "the style i trained in was hayashi-ha shito-ryu — which is more of okinawan than japanese i feel... compared to gichin and his japanesed karate it is."

This introduced an important nuance — the difference between Okinawan karate (closer to the original *te* and *tode*, Chinese influence, less formalized) and the karate that Gichin Funakoshi adapted for mainland Japan (Shotokan, the 3K format of kihon/kata/kumite, sport orientation).

But then the user self-corrected: "i do want to make it clear that funakoshi's japanesed karate is still karate."

This was the project's scope *learning*. The user's first instinct was to draw a sharp line — Okinawan is more authentic, Funakoshi adapted it. The second instinct was to soften that line — it's a different expression, not a lesser one. The personal-notes.md was updated to reflect this: "Funakoshi's Shotokan is a legitimate and influential tradition, but it adapted karate for the mainland Japanese context. Hayashi-ha Shito-ryu preserves closer ties to the Okinawan roots — different flavor, not better or worse."

---

## What Made This Work

### Documents updated as a set, not individually

When the scope changed, every relevant document was updated in the same session. The brief, style guide, personal notes, and threads document all reflected the new framing. A future session reading any of them would get the same scope — martial arts broadly, karate as primary lens, Okinawan roots acknowledged without romanticizing.

This matters because AI sessions read documents independently. If the brief said "martial arts broadly" but the style guide still said "Japanese terminology," the AI would get conflicting signals. Updating as a set eliminated the inconsistency.

### The cross-linking convention caught the cascade

The [cross-linking rule](../../.cursor/rules/cross-linking.md) includes a trigger: "Scope change to a directory — Check if its parent README description is still accurate." When the zen-karate project's scope broadened, this trigger prompted updates to the research README and the roadmap's descriptions.

Without the convention, the scope change might have been captured in one or two files while other documents drifted.

### Directory names stayed stable

The temptation when broadening from "karate" to "martial arts" was to rename `.planning/zen-karate/` to `.planning/martial-arts-zen/` and `research/zen-karate-philosophy/` to `research/martial-arts-philosophy/`. This would have been semantically accurate and operationally destructive — every link, every git history reference, every backlog entry pointing to those paths would have broken.

The decision to leave directory names stable and update the content inside them was pragmatic. The names are handles, not definitions.

### Nuance was captured, not flattened

The Okinawan-vs-Japanese distinction could have been resolved by picking a side or ignoring it. Instead, the personal-notes.md captured the nuance: "different flavor, not better or worse." A section on "Okinawan vs. Modern Karate" was added that acknowledges the spectrum without romanticizing one end.

This matters for AI coherence. If the notes had said "Okinawan is better," the AI would have written essays with that bias. If they'd said nothing, the AI would have treated karate as monolithic. The nuanced framing gives the AI a more honest position to write from.

---

## What Made This Hard

### The AI treats current documents as ground truth

When the scope was "Zen and Karate," the AI wrote planning documents with that frame. When the scope changed to "Martial Arts, Zen, and the Way of Working," the AI updated documents with the new frame and treated them as equally authoritative. It doesn't model the *evolution* — it only knows what the documents say now.

This means the AI can't tell a future session: "This project started narrower and broadened because the user's learning expanded." It can only present the current state. The git history captures the evolution, but AI sessions don't typically read git history for context. The case study you're reading right now is one attempt to make the evolution legible.

### Scope changes compound across sessions

Each session inherits the previous session's framing through the documents it reads. If session 3 broadened the scope and session 4 didn't notice (because it read different documents), session 4 might produce content with the old narrow framing. The cross-linking convention mitigates this by updating documents as a set, but it depends on the scope change being recognized as a scope change.

Subtle shifts — like the "different flavor, not better or worse" nuance — are the hardest to propagate. They're not structural changes that show up in file lists or link audits. They're tonal shifts that only matter when the AI writes prose.

### The project's name is now inaccurate

The planning directory is still called `zen-karate/`. The research directory is `zen-karate-philosophy/`. These names made sense when the scope was Zen and karate. Now they're handles that reference a narrower frame than the project actually has. This is a minor friction — anyone reading the files inside will see the broadened scope — but it's a concrete example of how creative evolution creates technical debt in an AI-managed workspace.

---

## The Shoshin Connection

The project's scope evolution is itself an example of *shoshin* (beginner's mind) — one of the Zen concepts the essays explore. The user approached their own expertise with openness: "I've trained in karate for decades, but I'm expanding beyond that now." The project's framing had to match that openness rather than crystallizing around the initial scope.

This is harder than it sounds. Planning documents want to be definitive. Roadmaps want to be stable. Style guides want to be authoritative. Having all of them say "this is our scope, and our scope is still learning" requires a kind of institutional humility that planning documents aren't designed for.

The project brief handles this with: "The scope is deliberately wider than one style or tradition. The philosophical threads — how you train, how you teach, how you carry yourself — run through martial arts worldwide. Karate is the primary lens because that's where the author's decades of practice live, but the ideas aren't confined to it." That framing allows the scope to keep evolving without requiring another cascade of document updates.

---

## What Conventions Help

| Convention | How it helps with evolving scope |
|---|---|
| Update documents as a set | Eliminates conflicting signals across files |
| Cross-linking scope-change trigger | Catches cascade effects from broadening/narrowing |
| Stable directory names | Avoids link breakage when content evolves |
| Nuanced framing over binary positions | Gives AI an honest position to write from |
| Personal notes as living document | Captures the author's current understanding, not a fixed persona |
| Explicit "primary lens" language | Allows breadth without losing the author's anchor |

## What Conventions Are Missing

| Gap | Why it matters |
|---|---|
| No "project evolution" log | Git history captures changes but not *why* the scope shifted |
| No cross-session scope-drift detection | The [`/audit`](../../.cursor/commands/audit.md) command checks links and registries but not tonal consistency |
| No mechanism for propagating subtle nuance | Structural changes cascade; tonal shifts don't |

---

## Artifacts

| Artifact | What it is |
|---|---|
| [BRIEF.md](../../.planning/zen-karate/BRIEF.md) | Project brief — broadened from "Zen and Karate" to "Martial Arts, Zen, and the Way of Working" |
| [STYLE.md](../../.planning/zen-karate/STYLE.md) | Voice and style guide — "Terminology from Source Traditions" (was "Japanese Terminology") |
| [personal-notes.md](../../research/zen-karate-philosophy/personal-notes.md) | Personal knowledge base — training history, Okinawan vs. modern karate distinction |
| [threads.md](../../.planning/zen-karate/threads.md) | Ideation threads — scope note added, 14 threads spanning the broadened scope |
| [cross-linking rule](../../.cursor/rules/cross-linking.md) | Convention that caught the cascade of scope changes |

## What Happened Next

The gaps identified in "What Conventions Are Missing" above led directly to the [shoshin meta-system integration](../../.cursor/rules/shoshin.md) — a new always-applied rule, fresh-eyes checks in [`/start`](../../.cursor/commands/start.md), assumptions tracking in [`/whats-next`](../../.cursor/commands/whats-next.md), brief-alignment drift detection in [`/review`](../../.cursor/commands/review.md), and the [CHANGELOG.md](../../.planning/zen-karate/CHANGELOG.md) convention for planning projects. The full story of how this case study produced the system improvements it was documenting the absence of is in [When Case Studies Generate System Improvements](case-studies-as-discovery.md).

---

*This document was written with AI assistance (Cursor). See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for full context on AI-generated content in this workspace.*
