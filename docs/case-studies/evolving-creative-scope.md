# How AI Handles Evolving Creative Scope Across Sessions

> **Audience:** Anyone using AI for multi-session creative or intellectual projects where the human's understanding evolves during the work — not just the output, but the framing itself.
> **Purpose:** Documents how a project's scope broadened, narrowed, and self-corrected across multiple sessions as the user's thinking evolved, and what conventions helped or hindered the AI's ability to maintain coherence across documents.
> *Context:* This workspace includes an essay series connecting martial arts philosophy to AI-assisted engineering. The author trained in Hayashi-ha Shito-ryu karate (an Okinawan tradition) and the essay project initially focused on Zen and karate before broadening to martial arts more generally. This case study documents that scope evolution.

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

This introduced an important nuance — the difference between Okinawan karate (closer to the original *te* and *tode*, strong Chinese influence, more fluid and circular) and the karate that Gichin Funakoshi formalized for mainland Japan (Shotokan, the 3K structure of kihon/kata/kumite, longer stances, large-scale systematic teachability).

But then the user self-corrected: "i do want to make it clear that funakoshi's japanesed karate is still karate."

This was the project's scope *learning* — moving from a sharp line (Okinawan is more authentic, Funakoshi adapted it) toward something more honest. The personal-notes.md was updated to reflect this.

The framing that survived into the updated notes, however, still centered Okinawan as the reference point: "Hayashi-ha Shito-ryu preserves closer ties to the Okinawan roots — different flavor, not better or worse." A Shotokan practitioner reading that isn't being evaluated on their tradition's own terms — they're being granted clearance relative to a baseline that isn't theirs. Funakoshi's decisions were deliberate: the 3K structure was a specific answer to making karate teachable at scale across mainland Japan. That's not dilution; it's a different design choice solving a different problem.

The more honest framing: describe what each tradition *solved* rather than how much each preserved or diverged from a common source. Hayashi-ha Shito-ryu carries strong Okinawan and Chinese influence and a particular relationship to kata forms. Shotokan answered a specific context — mass teachability, mainland Japan, a coherent theory of the body. Neither is a reference point for the other.

This reframing matters for the essays. "Different flavor, not better or worse" is diplomatic. But the essay series is reaching toward something closer to Jesse Enkamp's *no-style* — the idea that the principles transcend any tradition, and every tradition is one embodied path toward them. That aspiration requires a frame where traditions are *parallel paths*, not a primary tradition plus acknowledged others.

---

## What Made This Work

### Documents updated as a set, not individually

When the scope changed, every relevant document was updated in the same session. The brief, style guide, personal notes, and threads document all reflected the new framing. A future session reading any of them would get the same scope — martial arts broadly, karate as primary lens, Okinawan roots acknowledged without romanticizing.

This matters because AI sessions read documents independently. If the brief said "martial arts broadly" but the style guide still said "Japanese terminology," the AI would get conflicting signals. Updating as a set eliminated the inconsistency.

### The cross-linking convention caught the cascade

The [cross-linking rule](../../.cursor/rules/cross-linking.md) (workspace convention: when a directory's scope changes, update its parent README and related descriptions) includes a trigger: "Scope change to a directory — Check if its parent README description is still accurate." When the zen-karate project's scope broadened, this trigger prompted updates to the research README and the roadmap's descriptions.

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

### Coverage expanded; the frame didn't dissolve

There are two distinct kinds of scope evolution:

**Coverage expansion** — adding more traditions, more examples, more territory to what the project includes. The AI can do this: update the brief, broaden the style guide, add scope notes to threads.

**Frame dissolution** — questioning whether the organizing principle itself is right. The AI cannot do this: it reads the brief as authoritative and works within the frame the brief establishes.

This case study documents the first but not the second. The scope expanded from "Zen and Karate" to "martial arts broadly" — that's coverage expansion. But the organizing frame — *karate as the primary lens through which everything else is seen* — didn't change. The brief still says: "Karate is the primary lens because that's where the author's decades of practice live." The AI carried that frame forward, improved content within it, and treated it as the authoritative structure.

If the essays are reaching toward no-style — toward the principles as the lens, with every tradition as an equally valid path — then the brief's "primary lens" language is the frame that needs dissolving, not just the coverage that needs expanding. That requires the author to explicitly name the exit condition, as with the Approach A/B removal in a technical project: only deliberate pressure from outside the frame creates the opening.

**The recursive note:** this document, which is about scope evolution, is itself an example of coverage expanding without the frame dissolving. It was updated when the scope broadened; it hasn't been updated to question whether "karate as primary lens" is the right organizing structure for essays that aspire to no-style. That gap is being named here rather than left implicit.

### The project's name is now inaccurate

The planning directory is still called `zen-karate/`. The research directory is `zen-karate-philosophy/`. These names made sense when the scope was Zen and karate. Now they're handles that reference a narrower frame than the project actually has. This is a minor friction — anyone reading the files inside will see the broadened scope — but it's a concrete example of how creative evolution creates technical debt in an AI-managed workspace.

---

## The Shoshin Connection

The project's scope evolution is itself an example of *shoshin* (beginner's mind — approaching a familiar subject as if seeing it for the first time) — one of the Zen concepts the essays explore. The user approached their own expertise with openness: "I've trained in karate for decades, but I'm expanding beyond that now." The project's framing had to match that openness rather than crystallizing around the initial scope.

This is harder than it sounds. Planning documents want to be definitive. Roadmaps want to be stable. Style guides want to be authoritative. Having all of them say "this is our scope, and our scope is still learning" requires a kind of institutional humility that planning documents aren't designed for.

The project brief handles this with: "The scope is deliberately wider than one style or tradition. The philosophical threads — how you train, how you teach, how you carry yourself — run through martial arts worldwide. Karate is the primary lens because that's where the author's decades of practice live, but the ideas aren't confined to it." That framing allows the scope to keep evolving without requiring another cascade of document updates.

But shoshin applied to the brief itself surfaces a tension. The brief says "karate is the primary lens" — honest, autobiographical, grounded in decades of practice. And the essay series is reaching toward *no-style* as articulated by Jesse Enkamp: the idea that the principles — timing, zanshin, mushin, adaptability — transcend any tradition, and every tradition is one embodied path toward them. No-style isn't "my style plus awareness of others." It's specifically the removal of style-as-lens: the principles become the frame, and the tradition you trained in becomes evidence, not the organizing viewpoint.

Those two positions — "karate as primary lens" and "principles as lens, karate as one path" — produce different essays. In the first, essays translate karate concepts into work contexts; a Shotokan practitioner receives a translation through a different tradition's vocabulary. In the second, essays surface principles that show up in all traditions, and any practitioner recognizes their own training in what's described.

The brief is honest about what it is. The question it hasn't answered is whether "karate as primary lens" is what the essays are actually reaching toward — or whether that's the frame the brief established early and the project has since grown past.

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
| No cross-session scope-drift detection | The [`/audit`](../../.cursor/commands/audit.md) (periodic content health check) command checks links and registries but not tonal consistency |
| No mechanism for propagating subtle nuance | Structural changes cascade; tonal shifts don't |
| No trigger for frame dissolution vs. coverage expansion | AI can update documents when scope coverage broadens — it cannot question whether the organizing frame is right. That requires deliberate external pressure (peer feedback, explicit user pushback, milestone shoshin). The distinction isn't named anywhere in the convention set — so it doesn't get applied. |

---

## What the Human Brought

Every scope change in this case study originated from the user: the broadening from karate to martial arts, the Okinawan-vs-Japanese distinction, and the self-correction that "Funakoshi's japanesed karate is still karate." The AI updated documents; the user's evolving understanding drove what they said. The nuanced framing — "different flavor, not better or worse" — came from the author's decades of training and their willingness to revise their own instincts in real time.

## When This Applies — and When It Doesn't

**Good fit:**
- Multi-session creative or intellectual projects where the human's understanding is still developing — the scope evolves because the person does
- Projects with directory-based organization where scope changes cascade through naming, framing, and cross-references
- Work where multiple documents share an implicit scope definition that could drift silently if one document updates and others don't

**Not needed for:**
- Technical projects with fixed requirements where scope is established before work begins
- Short projects where scope evolution isn't a risk — the overhead of "update documents as a set" isn't justified for a single-session task
- Projects where the AI's role is implementation rather than framing — scope evolution matters most when the AI is writing prose that carries implicit claims about what the project covers

## Artifacts

| Artifact | What it is |
|---|---|
| [BRIEF.md](../../.planning/zen-karate/BRIEF.md) | Project brief — broadened from "Zen and Karate" to "Martial Arts, Zen, and the Way of Working" |
| [STYLE.md](../../.planning/zen-karate/STYLE.md) | Voice and style guide — "Terminology from Source Traditions" (was "Japanese Terminology") |
| [personal-notes.md](../../research/zen-karate-philosophy/personal-notes.md) | Personal knowledge base — training history, Okinawan vs. modern karate distinction |
| [threads.md](../../.planning/zen-karate/threads.md) | Ideation threads — scope note added, 14 threads spanning the broadened scope |
| [cross-linking rule](../../.cursor/rules/cross-linking.md) | Convention that caught the cascade of scope changes |

## What Happened Next

The gaps identified in "What Conventions Are Missing" above led directly to the [shoshin meta-system integration](../../.cursor/rules/shoshin.md) — a new always-applied rule, fresh-eyes checks in [`/start`](../../.cursor/commands/start.md) (session orientation command), assumptions tracking in [`/whats-next`](../../.cursor/commands/whats-next.md) (session handoff command), brief-alignment drift detection in [`/review`](../../.cursor/commands/review.md) (pre-commit quality gate), and the [CHANGELOG.md](../../.planning/zen-karate/CHANGELOG.md) convention for planning projects. The full story of how this case study produced the system improvements it was documenting the absence of is in [When Case Studies Generate System Improvements](case-studies-as-discovery.md) (the companion case study on how writing this scope-evolution piece surfaced gaps and drove workspace rule changes).

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
