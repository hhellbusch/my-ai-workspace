# Voice and Style Guide — Martial Arts, Zen, and the Way of Working

Reference document for maintaining consistent voice across the essay series. Every meta-prompt in the drafting pipeline should reference this file.

---

## The Blended Voice

This series uses two registers that alternate based on content:

### Personal Voice (philosophical and experiential sections)
- First person ("I," "my practice," "when I trained")
- Reflective, unhurried — the reader should feel the writer thinking, not performing
- Specific over abstract: name the dojo, the kata, the moment — not "one time in training"
- Comfortable with uncertainty and paradox (Zen is not a system of answers)
- Does not explain away the ineffable; acknowledges what can only be experienced
- **Biographical caution**: Every sentence that claims something about the author's identity, experience, or background will be attributed to them by readers. AI must not fabricate or embellish biographical details. When the author has not provided specific personal input for a section, use general or hypothetical framing ("a practitioner might notice...") rather than fabricating first-person claims. Content containing biographical statements requires `voice-approved` validation before the author considers it reviewed — see `AI-DISCLOSURE.md`.

### Practitioner Voice (applied and analytical sections)
- Second person or inclusive "we" where it helps ("you notice this in teams," "we carry this into work")
- Direct and grounded, matching the existing `docs/ai-engineering/` tone
- Claims paired with honest limits — what transfers and what doesn't
- Avoids motivational speaker energy; this is observation, not prescription

### Transitions Between Registers

The shift between personal and practitioner voice should feel natural, not jarring. Common patterns:
- Personal anecdote → generalized principle → applied observation
- Philosophical concept → how it's experienced in practice → where it appears outside the dojo
- Avoid abrupt register changes mid-paragraph

---

## Structural Conventions

Match the existing essay format (see `docs/ai-engineering/` and `docs/philosophy/`):

- **Title**: `#` heading, optionally with an em-dash subtitle
- **Front matter**: Blockquote with bold **Audience:** and **Purpose:** lines
- **Section breaks**: Horizontal rules `---` between major thematic blocks
- **Hierarchy**: `##` for main sections, `###` for subtopics
- **Sources and References**: Table linking to the specific research material, cached sources, threads, and library entries that informed the essay. Every claim that draws from a source should be traceable through this section. Use relative paths so links work from the essay's track directory (e.g., `docs/philosophy/`).
- **Open Review**: If the essay has been through adversarial review (`/spar` or manual sparring), link to the sparring notes and summarize the key unresolved counterarguments in 1-2 sentences. This signals to future sessions (and human readers) that the essay has known open threads.
- **Related Reading**: Table at the end linking to other essays in the series and to the existing AI-focused docs where natural
- **AI Disclosure**: Standard italic footer: *This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.* (path is `../../` because essays live two levels below repo root). If the author has personally reviewed and validated the content, the footer should say so explicitly: *"...and has been reviewed by the author."*

---

## Terminology from Source Traditions

The primary lens is karate (Hayashi-ha Shito-ryu, Okinawan tradition), but the series draws from martial arts broadly. Terminology follows the source tradition.

### When to Use Original Terms
- Use the Japanese, Chinese, or other term when it carries meaning that the English translation loses (mushin is not just "no-mind")
- Italicize on first use with a brief parenthetical: *mushin* (no-mind)
- After first use in an essay, use the term without explanation
- The [glossary](glossary.md) (once created) provides the canonical definitions; individual essays don't need to replicate them
- When discussing Okinawan karate specifically, acknowledge the distinction from mainland Japanese karate where it matters

### When to Use English
- For concepts where the English is sufficient and the original term would feel like unnecessary exoticization
- For terms the reader needs to understand immediately in an applied context
- When a concept is shared across traditions (e.g., "sparring" rather than insisting on *kumite* when the context isn't specifically karate)

### Avoid
- Overloading paragraphs with untranslated terms (more than 2-3 per paragraph signals the writing needs to breathe)
- Using terms from any tradition as decoration or to signal authenticity — use them because they're precise
- Treating "karate" as monolithic — the Okinawan roots and the modern sport are different things

---

## What This Series Is Not

These guardrails prevent common failure modes:

- **Not a martial arts textbook.** Don't explain techniques, ranks, or organizational politics unless they serve a philosophical point.
- **Not a Zen Buddhism primer.** Assume the reader is curious and intelligent but not a practitioner. Teach through experience, not doctrine.
- **Not motivational content.** No "ancient warriors knew the secret to success" framing. The philosophy is valuable because it's true, not because it's exotic.
- **Not memoir.** Personal experience serves the ideas, not the other way around. The reader should remember the insight, not the autobiography.
- **Not prescriptive.** "This is what I've found" rather than "you should do this." The dojo teaches that the path is individual.

---

## Project Framing — Open, Not Promised

The essays distill meaningful principles — they don't just tell a personal story. The roadmap and threads are explorations, not commitments.

### How to Reference Upcoming Work
- **This, not that:** "More essays are being explored — see the [roadmap](ROADMAP.md) and [threads](threads.md) for what's in progress" — NOT "here's what's coming next in the series"
- Threads are ideas being developed, not announcements. They may merge, evolve, or get killed. This is the nature of the work.
- Language should signal openness: "being explored," "in progress," "under development" — not "planned," "upcoming," or "next in the series"
- The project itself practices non-attachment to outcomes. A thread that gets killed after honest sparring is a success, not a failure.

### Nothing Is Sacred — Published Work Can Be Revised
- Published essays are not finished — they're the current best version. They can be pulled back in, rewritten, merged, split, or retired as the project evolves.
- "Published" means "committed to the repo and readable," not "final." The git history preserves every version.
- When new threads, research, or personal experience changes the picture, existing essays should be updated to reflect the improved understanding — not preserved as monuments to a previous session's thinking.
- This applies to the `docs/` essays, the planning docs, the style guide itself, and every other artifact. The project practices what it preaches about non-attachment.

### Guiding Stars
The project has a primary purpose and supporting interests. When prioritizing, the guiding star wins.

- **Primary: AI-engineering and case studies.** Sharing practical insights with peers about AI-assisted development, workflows, and the meta-development patterns emerging from this work. This is what the `docs/ai-engineering/` and `docs/case-studies/` tracks exist for. The philosophy track supports this — it doesn't overshadow it.
- **Supporting: Applied philosophy for work.** The `docs/philosophy/` track takes principles from karate and Buddhist/Zen teachings and applies them to work — broadly in technology (software, hardware, semiconductor manufacturing). The primary lens is martial arts philosophy, but it draws from any source that reinforces or challenges the principles: agile methodologies, books like *The Goal* and *The Phoenix Project*, productivity research (Doris, Newport), organizational theory, and direct experience. The audience is peers, not philosophy students. If an insight can't land with someone in a fab, a code review, or a production meeting, it hasn't been distilled enough.
- **Personal interest (not essay material): Lineage research.** Karate lineage, historical connections, style genealogy — genuinely interesting to the author but not the audience. Keep in research files as reference, don't plan essays around it.

### Purpose of the Essays
- Distill principles from practice that are meaningful beyond the personal story
- The personal experience serves the ideas, not the other way around (this echoes "Not memoir" above, but extends to the project level)
- Readers should take away something they can use, not just something they found interesting about someone else's life
- The Zen/martial arts lens is valuable because it reveals something true, not because it's exotic

---

## Tone Benchmarks

For calibration, the target tone sits between:

- **Too academic**: "The phenomenological reduction inherent in zazen practice creates epistemic conditions favorable to non-dual awareness..."
- **Too casual**: "Karate totally changed my life, and here's why you should try it too!"
- **Target**: "There's a moment in kumite where you stop thinking about what to do next. Your body knows. Your hands are already moving. The first time this happens, you realize that everything you've been told about mushin isn't metaphor — it's description."

---

## Cross-Linking Approach

- Essays within the zen-karate series reference each other naturally ("as explored in *The Way Is in Training*...")
- Bridge essays (4 and 5) explicitly connect to the existing AI-focused docs
- Don't force connections — if an essay stands alone, let it stand alone
- `docs/philosophy/README.md` maintains the reading order for this track; `docs/README.md` provides a cross-track reading order
- When mentioning a specific command, rule, script, or skill by name in prose, link to the implementation on first mention (see [cross-linking rule](../../.cursor/rules/cross-linking.md) "Inline Implementation Links")
