# Roadmap: Zen, Karate, and the Way of Working

## Overview

This series leads with a philosophical anchor essay — grounded in the deepest available source material (Inoue, Rika Usami, Hayashi lineage, personal practice) — then broadens into applied essays connecting dojo culture to engineering, open source, and ways of working. Later essays explore specific concepts (five hindrances, discipline as freedom) and bridge to the AI-era themes in the existing `docs/` essay track. The research foundation and personal knowledge base are shared resources that serve every essay.

## Phases

- [ ] **Phase 1: Foundation** - Personal knowledge base, curated sources, voice guide, research manifest
- [ ] **Phase 2: Research** - Per-essay gap filling (bulk source library already cached)
- [ ] **Phase 3: Essay 1** - "The Way Is in Training" — philosophical anchor essay
- [ ] **Phase 4: Essay 2** - "The Dojo, Open Source, and Ways of Working" — applied entry point
- [ ] **Phase 5: Essay 3** - "Five Hindrances" — Shi Heng Yi's framework applied to life and work
- [x] **Ego, AI, and the Zen Antidote** - Companion to *The Shift*, bridging AI and zen tracks (published ahead of sequence)
- [ ] **Phase 6: Later Essays** - "Discipline as Freedom", others from threads

## Phase Details

### Phase 1: Foundation
**Goal**: All inputs populated — personal notes, curated reading, voice guide, research manifest ready for fetching
**Depends on**: Nothing (first phase)
**Plans**: 2 plans

**Current state (~40-45% complete):**
- Structural scaffolding is ~90% done: templates created, style guide complete, 10 cached source files in `research/zen-karate-philosophy/sources/`, lineage maps built (Hayashi-ha + Athens Shotokan), curated reading list populated with 10 entries.
- Personal/experiential content is ~20%: training history and some notes/fragments exist, but the philosophical core — formative moments, philosophical anchors, life application examples, Shi Heng Yi connection, what's hard to convey — is mostly placeholder. This is the hard part that only the user can provide, and it's what gives the essays their distinctive voice.

Plans:
- [ ] 01-01: User populates personal-notes.md experiential sections (checkpoint: human input) — formative moments, philosophical anchors, life application, Shi Heng Yi connection, Shihan/Sensei crystallizing moments
- [x] 01-02: Build source library from curated reading + web research (substantially complete — 10 cached source files, 5 library entries, curated reading list with annotations)

**Key files:**
- `research/zen-karate-philosophy/personal-notes.md`
- `research/zen-karate-philosophy/curated-reading.md`
- `.planning/zen-karate/STYLE.md`
- `research/zen-karate-philosophy/sources/` (10 files)

### Phase 2: Research (per-essay gap filling)
**Goal**: Fill source gaps specific to each essay as it enters drafting
**Depends on**: Phase 1 (personal experiential content especially)
**Plans**: Per-essay, not monolithic

The original plan called for a formal fetch → batch-analysis pipeline. In practice, the source library has been built organically across research sessions. What remains is targeted gap-filling per essay:

- **Essay 1 (Way Is in Training):** Source material is deep — Inoue comprehensive bio, Rika Usami bio, Hayashi bio, Jesse Enkamp articles, Deshimaru. Primary gap is personal experiential depth from Phase 1.
- **Essay 2 (Dojo/Ways of Working):** Needs targeted research on agile dojo movement (Target, Ford, Pivotal Labs), open source etiquette formalization, code kata origins (Dave Thomas).
- **Essay 3+ :** TBD based on which threads mature.

### Phase 3: Essay 1 — The Way Is in Training
**Goal**: Philosophical anchor essay drafted, reviewed, published in `docs/philosophy/`
**Depends on**: Phase 1 personal-notes experiential sections populated. Research sources already cached.
**Plans**: 3 plans

This essay leads because the source material is deepest here and it establishes the philosophical vocabulary the rest of the series builds on. It draws from threads 2, 4, 5, 7, 12, 13, 15 in `.planning/zen-karate/threads.md`.

**Available source material:**
- Inoue comprehensive biography and teaching philosophy (uchi-deshi experience, "if kihon can do," three principles, kime, bunkai levels, "kata is the most personal of all the arts")
- Rika Usami biography (7-year journey, 5-hour train rides, shin-gi-tai, retirement as non-attachment, Chatanyara Kushanku as lineage expression)
- Hayashi biography (dojo yaburi, breadth of study, founding of Hayashi-ha)
- Deshimaru ("every moment of life is kata," bunbu ryodo, gyodo)
- Jesse Enkamp (Okinawan vs. Japanese, what got lost, bunkai as recovery)
- Personal practice (the gap, the return, what survives, training across lineages)

Plans:
- [ ] 03-01: Section outline with voice notes, source attributions, and personal experience integration points
- [ ] 03-02: Draft with sparring pass (`/spar`)
- [ ] 03-03: Review, publish, cross-link + seed glossary

### Phase 4: Essay 2 — The Dojo, Open Source, and Ways of Working
**Goal**: Applied entry point essay drafted, reviewed, published
**Depends on**: Phase 3 (vocabulary established, glossary seeded) + targeted research on agile dojos
**Plans**: 3 plans

This essay takes the philosophical foundation from Essay 1 and applies it to engineering culture, open source, and agile transformation. It draws from threads 3, 6, 7, 10, 11, 12 in `.planning/zen-karate/threads.md` and connects to `docs/ai-engineering/ai-assisted-upstream-contributions.md` as a worked example.

Plans:
- [ ] 04-01: Targeted research — agile dojo movement (Target, Ford, Pivotal Labs), open source etiquette, code kata origins
- [ ] 04-02: Section outline with voice notes and source attributions
- [ ] 04-03: Draft, review, publish

### Phase 5: Essay 3 — Five Hindrances
**Goal**: Third essay drafted, reviewed, published
**Depends on**: Phase 4
**Plans**: 3 plans

Plans:
- [ ] 05-01: Research meta-prompt for Essay 3
- [ ] 05-02: Plan meta-prompt for Essay 3
- [ ] 05-03: Draft, review, publish

### Phase 6: Later Essays
**Goal**: Remaining essays from the threads document, sequence TBD after earlier essays prove the workflow
**Depends on**: Phases 3-5 (foundation established)
**Plans**: TBD

**Note:** "Ego, AI, and the Zen Antidote" (`docs/philosophy/ego-ai-and-the-zen-antidote.md`) was written ahead of the planned sequence because thread 14 matured rapidly and bridged directly to *The Shift*. It absorbs most of the "Beginner's Mind in the Age of AI" material. The remaining candidates are:

- [ ] "Discipline as Freedom" — paradox of restriction and growth
- [ ] Others emerging from threads (organizational karma, breaking the cycle, lineage as transmission, science and tradition)
- [ ] Update `docs/README.md` with complete reading track + cross-links

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 1/2 | In progress — scaffolding done, user experiential input needed | - |
| 2. Research (per-essay) | — | Bulk sources cached; gap-fill as essays enter drafting | - |
| 3. Essay 1 (Way Is in Training) | 0/3 | Blocked on Phase 1 experiential content | - |
| 4. Essay 2 (Dojo/Ways of Working) | 0/3 | Needs targeted agile dojo research | - |
| 5. Essay 3 (Five Hindrances) | 0/3 | Not started | - |
| Ego, AI, and the Zen Antidote | — | Published | 2026-04-17 |
| 6. Later Essays | 0/TBD | Not started | - |
