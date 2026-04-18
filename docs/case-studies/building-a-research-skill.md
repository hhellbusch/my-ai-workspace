# Building a Research and Verification Skill — A Case Study in Meta-Development

> **Audience:** Engineers and leaders interested in how AI-assisted development works at the meta level — building tools that make AI more effective at complex, multi-step tasks.
> **Purpose:** Documents the end-to-end process of identifying a gap in AI-assisted workflows, designing a reusable skill to fill it, and validating the skill against a real-world research exercise.

---

## Background

This document traces a single thread of work across two extended AI-assisted sessions. It started with a simple request — summarize a technical blog post — and evolved through progressive discovery into a reusable research automation system.

The work demonstrates several themes from [The Shift](../ai-engineering/the-shift.md):
- Problem decomposition applied to a process, not just code
- Systematic debugging applied to workflow failures, not just bugs
- Building tools that compensate for known AI limitations
- The meta-development pattern: using AI to build systems that make AI more effective

---

## The Sequence of Events

### Phase 1: The Article Summary

A colleague published a long-form technical article on deploying LLMs with Red Hat OpenShift AI, citing 62 references. The first task was straightforward: create a layered summary for different audiences.

**Output:** [Enterprise LLM Deployment on OpenShift AI — Summary](../ai-engineering/openshift-ai-llm-deployment-summary.md)

This worked well for summarization. But when we tried to verify the article's accuracy against its cited sources, the workflow broke down.

### Phase 2: Manual Verification — Finding the Limits

We attempted to verify the article's claims by fetching and reading its 62 cited references inline. The problems surfaced quickly:

- **Fetch failures:** ~20 of 62 URLs returned errors (403 from bot protection, 404s, timeouts, rate limiting). Each failure consumed conversation context without producing useful output.
- **Context window pressure:** Successfully fetched pages were large (some Red Hat docs ran 80,000+ characters). Reading multiple sources in a single conversation pass crowded out the analysis work.
- **No persistence:** If the conversation reset or hit a length limit, all fetched content was lost. Re-fetching the same URLs burned time and risked triggering more rate limiting.
- **Sequential bottleneck:** Each source was fetched and analyzed one at a time. With 62 references, this was painfully slow.

Despite these constraints, we produced a partial verification analysis covering about half the sources. The findings were useful — we identified qualifier stripping, maturity level omissions, and vendor marketing presented as independent analysis. But the process was fragile and unrepeatable.

**Output:** [Verification Notes](../../research/openshift-ai-llm-deployment/verification-notes-v1.md) (partial, from the first session)

### Phase 3: Designing the Skill

The pain points from Phase 2 mapped directly to design requirements:

| Problem | Design Response |
| --- | --- |
| Fetched content lost on conversation reset | Write everything to disk immediately |
| Context window overflow from large pages | Work in small batches, reading from filesystem |
| Sequential fetch/analyze loop | Separate gather and analyze into distinct phases |
| 20+ fetch failures from bot protection | Build a dedicated fetcher with stealth headers and concurrency |
| Slow analysis across 62 sources | Parallelize analysis across independent batch agents |

The skill was designed as a router pattern with three workflows:

```
SKILL.md (router)
├── workflows/
│   ├── gather-sources.md     Fetch all URLs to disk, produce manifest
│   ├── analyze-claims.md     Read sources in batches, verify claims, write findings
│   └── synthesize-findings.md  Compile findings into assessment
├── scripts/
│   └── fetch-sources.py      Concurrent batch fetcher with stealth + proxy support
├── templates/
│   ├── manifest-template.md
│   ├── batch-findings-template.md
│   └── assessment-template.md
└── references/
    ├── verification-patterns.md   How to check different claim types
    └── fetcher-notes.md           Architecture, anti-bot strategies, browser fallback roadmap
```

The key architectural decisions:

1. **Filesystem as the coordination layer.** Sources, findings, and the manifest all live on disk. This means work survives conversation resets, content can be re-analyzed without re-fetching, and large documents never need to fit in a single context window.

2. **Manifest-driven pipeline.** A markdown table tracks every reference: URL, fetch status, output file path, and notes. The fetcher reads and updates this manifest. The analyzer reads it to plan batches. Everything is traceable.

3. **Parallel batch analysis.** The analyze workflow explicitly instructs launching up to 4 independent agents simultaneously. Each agent reads its own source files and writes its own findings file — no conflicts, no coordination overhead.

4. **Progressive hardening of the fetcher.** The Python script evolved across several iterations:
   - v1: Sequential, basic requests, single User-Agent
   - v2: Concurrent (ThreadPoolExecutor), rotating User-Agents, stealth browser-mimicry headers, per-domain rate limiting, proxy support, PDF extraction via pdfplumber

**Output:** The complete skill at `.cursor/skills/research-and-analyze/` (this is a [Cursor IDE](https://cursor.sh/) AI skill — a structured set of instructions, workflows, and scripts that the IDE's AI agent follows when performing research tasks)

### Phase 4: Validation Run

We re-ran the entire pipeline against the same Jared Burck article to validate the skill end-to-end.

**Gather results:**

| Metric | Manual (Phase 2) | Skill (Phase 4) |
| --- | --- | --- |
| Sources fetched | ~42 of 62 (68%) | 53 of 62 (85%) |
| Fetch method | Individual WebFetch calls | Concurrent script + WebFetch fallback |
| Time to fetch | ~30 minutes of conversation | ~35 seconds (script) + ~2 minutes (fallback) |
| Persistence | In conversation memory only | 54 files on disk (sources/) |

**Analysis results:**

| Metric | Manual (Phase 2) | Skill (Phase 4) |
| --- | --- | --- |
| Batches | ~6, sequential, partial | 8, parallel (4 at a time) |
| Sources analyzed | ~30 | 53 |
| Findings files | 1 combined document | 8 structured batch files + 1 assessment |
| Persistence | In conversation memory | 15 files on disk (findings/) |

**Final assessment:** A structured document with a confidence table by topic area, 5 key findings, and recommendations for what to trust, verify independently, or discard. The findings were consistent with the partial manual analysis but more comprehensive and better organized.

**Output:** Complete research workspace at `research/openshift-ai-llm-deployment/` containing:
- `manifest.md` — 62 references with status tracking
- `sources/` — 54 files (53 references + original article)
- `findings/` — 15 batch analysis files
- `assessment.md` — final synthesized assessment

---

## What the Skill Reveals About AI-Assisted Work

### The meta-development loop

This is the pattern described in [AI-Assisted Development Workflows](../ai-engineering/ai-assisted-development-workflows.md) taken to its logical conclusion: using AI to build a system that makes AI better at a specific class of task. The skill doesn't replace human judgment — it structures the workflow so that judgment can be applied efficiently to source material that's already on disk, organized, and tracked.

### Known limitations compensated for

The skill's design directly addresses known AI limitations:

- **Context windows are finite** — so work in small batches from disk, not from memory
- **Connections are unreliable** — so fetch everything upfront, retry failures, and use fallback methods
- **AI is confidently wrong** — so every finding traces back to source text on disk where a human can verify the comparison
- **Conversations end** — so persist everything to the filesystem, not just to conversation state

### The sycophancy problem in practice

The article verification exercise is a concrete example of what [The Shift](../ai-engineering/the-shift.md) calls the sycophancy risk. The Jared Burck article is well-written and confident. An AI asked to summarize it will faithfully reproduce its claims, including the ones that strip qualifiers ("99% accuracy" becomes "strictly maintaining 99% accuracy") or present roadmap features as shipping capabilities. The skill forces a comparison between what the article says and what the cited sources actually say — creating the adversarial pressure that summarization alone doesn't provide.

### What still requires a human

- Deciding which claims matter enough to verify
- Evaluating whether a "verified with caveats" finding is material or pedantic
- Judging the strategic implications of the assessment
- Deciding what to share, with whom, and how to frame it

---

## Remaining Gaps

- **`developers.redhat.com` bot protection:** 7 of the 9 unfetched sources were blocked by Cloudflare on this domain. A headless browser fallback (Playwright) is designed but not yet implemented. The architecture and approach are documented in [`references/fetcher-notes.md`](../../.cursor/skills/research-and-analyze/references/fetcher-notes.md).

- **Low-content captures:** Some pages returned minimal content (46-75 characters) where the content extraction missed the main article body. The domain-specific selector system can be extended for these cases.

- **No automated re-verification:** The skill is currently human-initiated. A future improvement could compare a new fetch against a previous one to detect source changes over time.

---

## File Index

### Documentation Suite

| File | Purpose |
| --- | --- |
| [The Shift](../ai-engineering/the-shift.md) | Core thesis on engineering skills in the AI era |
| [AI-Assisted Development Workflows](../ai-engineering/ai-assisted-development-workflows.md) | Practical patterns for AI-assisted infrastructure work |
| [Using AI Outside Your Expertise](../ai-engineering/ai-for-unfamiliar-domains.md) | Case study: GIF recoloring as an unfamiliar domain |
| [Enterprise LLM Summary](../ai-engineering/openshift-ai-llm-deployment-summary.md) | Layered summary of the Jared Burck article |
| [Building a Research Skill](building-a-research-skill.md) | This document |

### Research and Analysis Skill

> **Note:** These files live under `.cursor/skills/` — the convention for [Cursor IDE](https://cursor.sh/) AI agent skills. They are structured Markdown instructions and Python scripts that the AI agent follows during research tasks. The scripts (e.g., [`fetch-sources.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-sources.py)) are standard Python and can be used independently of Cursor.

| File | Purpose |
| --- | --- |
| [`SKILL.md`](../../.cursor/skills/research-and-analyze/SKILL.md) | Skill router — intake, routing, principles |
| [`gather-sources.md`](../../.cursor/skills/research-and-analyze/workflows/gather-sources.md) | Fetch all URLs to disk |
| [`analyze-claims.md`](../../.cursor/skills/research-and-analyze/workflows/analyze-claims.md) | Parallel batch claim verification |
| [`synthesize-findings.md`](../../.cursor/skills/research-and-analyze/workflows/synthesize-findings.md) | Compile assessment from findings |
| [`fetch-sources.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-sources.py) | Concurrent batch fetcher (stealth, proxy, PDF) |
| [`verification-patterns.md`](../../.cursor/skills/research-and-analyze/references/verification-patterns.md) | Claim types and verification approaches |
| [`fetcher-notes.md`](../../.cursor/skills/research-and-analyze/references/fetcher-notes.md) | Architecture, anti-bot notes, browser fallback plan |
| `templates/*.md` | Manifest, batch findings, and assessment templates |

### Research Workspace (Validation Run)

| File | Purpose |
| --- | --- |
| [`manifest.md`](../../research/openshift-ai-llm-deployment/manifest.md) | 62-reference tracking manifest |
| [`sources/`](../../research/openshift-ai-llm-deployment/sources/) (54 files) | Fetched reference content |
| [`findings/`](../../research/openshift-ai-llm-deployment/findings/) (15 files) | Per-batch analysis results |
| [`assessment.md`](../../research/openshift-ai-llm-deployment/assessment.md) | Final synthesized assessment |

---

## AI Disclosure

This document, the research skill, and all analysis artifacts were produced with AI assistance across two extended development sessions and have not been fully reviewed by the author. The AI performed code generation, source fetching, claim comparison, and document drafting. Human direction guided the problem identification, skill design decisions, and quality standards throughout. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.
