# Personal Reference Library

A persistent collection of books, talks, articles, videos, and other sources that inform thinking across projects. Each entry combines personal notes with AI-enriched context (cached summaries, reviews, key themes) so any future session can draw from the source without re-explaining it.

## How It Works

- **Catalog**: [`catalog.md`](catalog.md) is the master table of all references with basic metadata (50+ entries covering books, courses, and training from 2010–present).
- **Enriched entries**: References that need deep context for active projects get their own file with AI-researched summaries, key themes, and cached sources.
- **Ingest log**: [`log.md`](log.md) records every ingest in date order — parseable with `grep "^## " library/log.md`. Required for every new entry.
- **Adding references**: Use `/reference add <title>` for enriched entries, or add rows directly to `catalog.md` for quick logging. Always append to `log.md`.
- **Connecting to projects**: Project-specific reading lists (like `research/zen-karate-philosophy/curated-reading.md`) link to enriched entries rather than duplicating context.
- **Searching**: Use `/reference search <term>` to find references by keyword across both the catalog and enriched entries.

## Enriched Entries

These references have deep AI-researched context (summaries, key themes, notable ideas, cached sources):

| Entry | Type | Tags | Added |
|---|---|---|---|
| [The Zen Way to Martial Arts](zen-way-martial-arts.md) | Book | zen, karate, martial-arts, philosophy | 2026-04-17 |
| [Karate by Jesse (Jesse Enkamp)](karate-by-jesse.md) | Website | karate, okinawa, history, bunkai, shito-ryu | 2026-04-17 |
| [Finding Karate](finding-karate.md) | Book | karate, philosophy, training | 2026-04-17 |
| [Karate Philosophy](karate-philosophy.md) | Book | karate, philosophy, dojo-kun | 2026-04-17 |
| [Simple Lucas](simple-lucas.md) | YouTube | productivity, single-tasking, zen-parallels | 2026-04-17 |
| [Rian Doris / FlowState](rian-doris.md) | YouTube | neuroscience, flow, dopamine, focus | 2026-04-17 |
| [3Blue1Brown — Deep Learning Series](3blue1brown.md) | YouTube | ai, neural-networks, deep-learning, transformers, llm | 2026-04-17 |
| [Shi Heng Yi — Isolation Is The Gateway to Success](shi-heng-yi-isolation.md) | YouTube | zen, shaolin, isolation, solitude, self-mastery, martial-arts | 2026-04-18 |
| [Dan Walsh — Career lessons (DevConf.US 2025)](dan-walsh-devconf-2025-career-lessons.md) | YouTube | career, containers, selinux, open-source, mentorship, ai-tooling | 2026-04-18 |
| [Daniel Miessler — AI WILL Replace Knowledge Workers](daniel-miessler-ai-replace-knowledge-workers.md) | YouTube | ai, knowledge-work, organizational-chaos, skills, automation, lattice | 2026-04-18 |
| [Git For Ages 4 And Up — Michael Schwern (linux.conf.au 2013)](git-for-ages-4-and-up.md) | YouTube | git, version-control, beginner, mental-model, branching, remotes, gitops | 2026-04-28 |
| [Automate OpenShift Cluster Deployment with RHACM and AAP (DevConf.US 2024)](automate-ocp-cluster-deployment-rhacm-aap.md) | YouTube | openshift, rhacm, aap, ansible, gitops, cluster-lifecycle, policy-automation, fleet, disconnected | 2026-04-28 |
| [Ryan Lopopolo — Harness Engineering (AI Engineer London 2026)](ryan-lopopolo-harness-engineering.md) | YouTube | ai-engineering, agents, harness, context-engineering, code-is-free, openai, codex | 2026-04-30 |
| [Dex Horthy — No Vibes Allowed (AI Engineer London 2026)](dex-horthy-no-vibes-allowed.md) | YouTube | ai-engineering, context-engineering, rpi, dumb-zone, sub-agents, brownfield, humanlayer | 2026-04-30 |
| [Andrej Karpathy — From Vibe Coding to Agentic Engineering (Sequoia 2026)](andrej-karpathy-vibe-coding-to-agentic-engineering.md) | YouTube | ai-engineering, vibe-coding, agentic-engineering, software-3.0, jagged-intelligence, verifiability, karpathy | 2026-04-30 |
| [Simon Scrapes — Every Claude Code Memory System Compared](simon-scrapes-claude-code-memory-systems.md) | YouTube | ai-engineering, memory, claude-code, agents, memsearch, mempalace, autonomous-agents, paude | 2026-04-30 |
| [Andrej Karpathy — LLM Wiki (GitHub Gist)](karpathy-llm-wiki.md) | Gist | ai-engineering, memory, llm-wiki, knowledge-base, schema, ingest, persistent-context | 2026-04-30 |
| [MemPalace — Local-first AI memory](mempalace.md) | Tool / Architecture | ai-engineering, memory, verbatim-storage, semantic-search, wings-rooms-drawers, mcp, agent-memory | 2026-04-30 |

See [`catalog.md`](catalog.md) for the complete reference list (50+ books, courses, and training).

---

## Wing Index (Topic View) {#wing-index}

Entries grouped by topic wing. This is the retrieval-first view — navigate by meaning, not format.

### `ai-engineering`

Agents, harness engineering, context management, memory systems, models, agentic workflow:

| Entry | Subtopic | Added |
|-------|----------|-------|
| [Ryan Lopopolo — Harness Engineering](ryan-lopopolo-harness-engineering.md) | harness / agent-steering | 2026-04-30 |
| [Dex Horthy — No Vibes Allowed](dex-horthy-no-vibes-allowed.md) | context-engineering / RPI | 2026-04-30 |
| [Andrej Karpathy — Vibe Coding to Agentic Engineering](andrej-karpathy-vibe-coding-to-agentic-engineering.md) | software-3.0 / agentic | 2026-04-30 |
| [Simon Scrapes — Claude Code Memory Systems](simon-scrapes-claude-code-memory-systems.md) | memory / agents | 2026-04-30 |
| [Andrej Karpathy — LLM Wiki](karpathy-llm-wiki.md) | memory / knowledge-base | 2026-04-30 |
| [MemPalace](mempalace.md) | memory / verbatim / wings-rooms-drawers | 2026-04-30 |
| [3Blue1Brown — Deep Learning Series](3blue1brown.md) | foundations / transformers / llm | 2026-04-17 |
| [Daniel Miessler — AI WILL Replace Knowledge Workers](daniel-miessler-ai-replace-knowledge-workers.md) | AI impact / org | 2026-04-18 |
| [Hank Green — AI Water Use](hank-green-ai-water-use.md) | AI infrastructure | 2026-04-18 |
| [EngineersOfAI — What are AI Agents?](engineersofai-what-are-ai-agents.md) | agents / foundations | 2026-04-28 |
| [Daniel Miessler — PAI](daniel-miessler-pai.md) | personal AI infrastructure | 2026-04-18 |
| [Daniel Miessler — Single Digital Assistant](daniel-miessler-single-da-thesis.md) | agentic / orchestration | 2026-04-18 |

### `philosophy-practice`

Zen, karate, martial arts, flow, solitude, self-mastery:

| Entry | Subtopic | Added |
|-------|----------|-------|
| [The Zen Way to Martial Arts](zen-way-martial-arts.md) | zen / karate | 2026-04-17 |
| [Finding Karate](finding-karate.md) | karate / philosophy | 2026-04-17 |
| [Karate Philosophy](karate-philosophy.md) | karate / dojo-kun | 2026-04-17 |
| [Karate by Jesse](karate-by-jesse.md) | karate / history / bunkai | 2026-04-17 |
| [Simple Lucas](simple-lucas.md) | productivity / single-tasking | 2026-04-17 |
| [Rian Doris / FlowState](rian-doris.md) | neuroscience / flow | 2026-04-17 |
| [Shi Heng Yi — Isolation Is The Gateway](shi-heng-yi-isolation.md) | shaolin / solitude | 2026-04-18 |
| [Enkamp × Shi Heng Yi — Mastery](enkamp-shi-heng-yi-mastery.md) | mastery / martial arts | 2026-04-18 |
| [André Bertel — Adaptive Reliability](andre-bertel-adaptive-reliability.md) | karate / seminar | 2026-04-18 |

### `devops`

Git, OpenShift, RHACM, AAP, Ansible, cluster lifecycle:

| Entry | Subtopic | Added |
|-------|----------|-------|
| [Git For Ages 4 And Up](git-for-ages-4-and-up.md) | git / mental-model | 2026-04-28 |
| [Automate OCP Cluster Deployment — RHACM + AAP](automate-ocp-cluster-deployment-rhacm-aap.md) | openshift / cluster-lifecycle | 2026-04-28 |
| [Dan Walsh — Career Lessons](dan-walsh-devconf-2025-career-lessons.md) | containers / selinux / career | 2026-04-18 |

## Entry Template

Each entry follows this structure:

```markdown
# [Title]

## Metadata
- **Author:**
- **Type:** Book / Talk / Article / Video / Course / Website
- **Published:**
- **URL:** (if available online)
- **Tags:**
- **Added:** YYYY-MM-DD
- **Projects:** (which workspace projects reference this)

## Why This Matters (personal)
[Your notes on why this source is significant to you]

## Key Themes (AI-enriched)
[AI-researched summary of major themes, drawn from reviews and analyses]

## Notable Ideas
[Specific concepts, quotes, or frameworks worth referencing]

## Sources
[URLs of reviews, summaries, or analyses that were used for enrichment]
```

## Related

- [`research/`](../research/) — Project-specific research workspaces
- [`.planning/`](../.planning/) — Project briefs and roadmaps that may reference library entries
- [`docs/`](../docs/) — Published essays that draw from these sources
