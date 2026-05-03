---
name: research-and-analyze
description: Systematic research and source verification for articles, blog posts, technical documentation, and video transcripts. Use when verifying claims against cited sources, analyzing accuracy of external content, evaluating talks and videos, or building evidence-based assessments from any source material.
---

<essential_principles>

### 1. Gather First, Analyze Second

Never try to fetch and analyze in the same pass. External fetches timeout, content is too large for inline processing, and conversation resets lose everything. Instead:
- **Gather phase**: Fetch all sources to disk. Produce a manifest of successes/failures.
- **Analyze phase**: Read files from disk in manageable batches. Write findings to disk incrementally.
- **Synthesize phase**: Compile per-source findings into an overall assessment.

### 2. Everything Goes to Disk

Source content, intermediate findings, and final assessment all live on the filesystem. This means:
- Work survives conversation resets
- Content can be re-analyzed without re-fetching
- Findings accumulate across sessions
- Large content doesn't overwhelm context windows

### 3. Work in Batches — Parallelize When Possible

Don't try to analyze 20 sources at once. Group into batches of 3-5 by topic:
- Each batch reads source files from disk and writes its own findings file
- **Batches are independent** — launch them as parallel Task agents (up to 4 at once)
- Each agent gets: the original article, its source files, specific claims to check, and the findings template
- Compare claims against what sources actually say
- Write findings for that batch to disk
- After all batches return, verify all expected output files exist

### 4. Track Provenance

Every claim should trace back to: where the article says it → what the cited source actually says → whether they match. Use the manifest to track which sources have been checked and which remain.

### 5. Workspace Convention

All research artifacts go in a `research/` directory within the project, organized by subject:

```
research/
├── {subject}/
│   ├── manifest.md          # What was fetched, status, file mapping
│   ├── sources/             # Raw fetched content
│   │   ├── ref-01.md
│   │   ├── ref-02.md
│   │   └── ...
│   ├── findings/            # Per-batch analysis notes
│   │   ├── batch-01.md
│   │   ├── batch-02.md
│   │   └── ...
│   └── assessment.md        # Final synthesized assessment
```

</essential_principles>

<intake>
**HARD STOP — present these options and wait. Do not proceed until the user responds.**

Even if the user has already provided a URL, article, or YouTube link, you do not know:
- Whether they want the full pipeline or a specific phase
- Whether they want the transcript-only path or citation verification
- What subject slug to use for the research directory

Present this menu and wait:

---

What would you like to do?

1. **Start new research** — article or document with citations to verify
2. **YouTube / single-source transcript** — evaluate a talk, video, or single source with no citations
3. **Continue gathering** — I have a manifest with unfetched sources
4. **Analyze sources** — sources are on disk, ready for claim verification
5. **Synthesize findings** — analysis is done, compile the assessment
6. **Full pipeline** — do everything: gather → analyze → synthesize

Also tell me: **what subject slug should I use for the research directory?** (e.g., `miessler-single-da-thesis`, `openai-gpt5-launch`) — this becomes `research/{slug}/`.

---

**Do not take any action until the user responds to the above.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "new", "start", "verify", "article" | `workflows/gather-sources.md` |
| 2, "youtube", "transcript", "video", "talk", "single source" | `workflows/gather-sources.md` — transcript variant (Step 2T) |
| 3, "continue", "fetch", "retry" | `workflows/gather-sources.md` (resume mode) |
| 4, "analyze", "check", "verify claims" | `workflows/analyze-claims.md` |
| 5, "synthesize", "compile", "summarize", "assessment" | `workflows/synthesize-findings.md` |
| 6, "full", "everything", "pipeline", "all" | Run all three workflows in sequence, stopping at each phase-boundary checkpoint |

**After reading the workflow, follow it exactly. Each workflow has a phase-boundary checkpoint at the end — stop there and wait for explicit user confirmation before starting the next phase.**
</routing>

<reference_index>
All domain knowledge in `references/`:

**Patterns:** verification-patterns.md — common claim types and how to check them
**Fetcher:** fetcher-notes.md — architecture, anti-bot strategies, proxy/VPN usage, browser fallback roadmap
</reference_index>

<workflows_index>
| Workflow | Purpose |
|----------|---------|
| gather-sources.md | Extract URLs, batch-fetch to disk, produce manifest |
| analyze-claims.md | Read source files in batches, verify claims, write findings |
| synthesize-findings.md | Compile findings into overall confidence assessment |
</workflows_index>

<templates_index>
| Template | Purpose |
|----------|---------|
| manifest-template.md | Source tracking: URL, status, file path, notes |
| batch-findings-template.md | Per-batch analysis structure |
| assessment-template.md | Final assessment with confidence table |
</templates_index>

<scripts_index>
| Script | Purpose |
|----------|---------|
| fetch-sources.py | Concurrent batch URL fetcher with stealth headers, proxy support, PDF extraction, and domain-aware rate limiting |
| fetch-transcript.py | YouTube transcript fetcher — single video or batch mode, saves timestamped markdown to disk |
</scripts_index>
