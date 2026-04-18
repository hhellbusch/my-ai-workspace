---
name: research-and-analyze
description: Systematic research and source verification for articles, blog posts, and technical documentation. Use when verifying claims against cited sources, analyzing accuracy of external content, or building evidence-based assessments from multiple references.
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
What would you like to do?

1. **Start new research** — I have an article/document to verify
2. **Continue gathering** — I have a manifest with unfetched sources
3. **Analyze sources** — Sources are on disk, ready for claim verification
4. **Synthesize findings** — Analysis is done, compile the assessment
5. **Full pipeline** — Do everything: gather → analyze → synthesize

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "new", "start", "verify", "research" | `workflows/gather-sources.md` |
| 2, "continue", "fetch", "retry" | `workflows/gather-sources.md` (resume mode) |
| 3, "analyze", "check", "verify claims" | `workflows/analyze-claims.md` |
| 4, "synthesize", "compile", "summarize", "assessment" | `workflows/synthesize-findings.md` |
| 5, "full", "everything", "pipeline", "all" | Run all three workflows in sequence |

**After reading the workflow, follow it exactly.**
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
