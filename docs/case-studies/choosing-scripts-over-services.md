# Choosing Scripts Over Services — The YouTube Transcript Decision

> **Audience:** Engineers making build-vs-integrate decisions in AI-assisted workflows, where the architecturally elegant option isn't always the right one.
> **Purpose:** Documents a small but instructive architectural decision — MCP server vs. Python script for fetching YouTube transcripts — that demonstrates problem decomposition and workflow-fit thinking from [The Shift](../ai-engineering/the-shift.md).

---

## The Need

The project needed YouTube transcripts. The research track had a [Shi Heng Yi interview](../../research/zen-karate-philosophy/sources/they-betrayed-me---master-shi-heng-yi-explains-the-true-cost-of-success-shaolin-.md) (1 hour 37 minutes) that was a primary source for the essay series. The personal reference library needed to enrich video entries with transcript content. Doing this manually — watching, pausing, copying — was impractical.

The question was how to automate it.

---

## The Options

Three approaches were evaluated:

### Option 1: MCP server

[jkawamoto/mcp-youtube-transcript](https://github.com/jkawamoto/mcp-youtube-transcript) — a Model Context Protocol server that exposes YouTube transcript fetching as a tool the AI can call during conversation. The AI asks for a transcript, the MCP server fetches it, and the content appears in the conversation context.

**Advantages:** Seamless integration into conversation flow. No manual script invocation. The AI can fetch and process transcripts in a single exchange.

**Disadvantages:** Transcripts live in conversation context, not on disk. When the session ends, the transcript is gone. No persistent cache. No batch mode. Every future session that needs the same transcript fetches it again. And MCP servers add operational complexity — installation, configuration, version management.

### Option 2: Gemini API with video understanding

Google's Gemini API can process YouTube videos directly by URL — not just transcripts, but visual understanding. Useful for martial arts demonstrations where the visuals carry meaning.

**Advantages:** Richer than transcript-only. Could analyze movement, technique, and context that text can't capture.

**Disadvantages:** Requires API key and has per-request costs. The project doesn't currently need visual analysis — the transcripts are the primary source material. Overkill for the immediate need.

### Option 3: Python script

A standalone script using the `youtube-transcript-api` library. Fetch a transcript, save it as a timestamped markdown file. Support single video and batch mode. Integrate with the existing research skill's file-based workflow.

**Advantages:** Output is a file on disk — persistent across sessions, cacheable, grep-able, version-controllable. Batch mode handles multiple videos. Fits the existing pattern: [`fetch-sources.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-sources.py) fetches web pages as markdown, [`fetch-transcript.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-transcript.py) fetches transcripts as markdown. Same directory, same conventions, same workflow.

**Disadvantages:** Manual invocation. The AI can't call it silently during conversation — someone has to run `python3 fetch-transcript.py <url> <output-dir>`.

---

## The Decision

The script won. The MCP server was deferred to Ideas in the backlog. The Gemini API was logged as a future option.

---

## Why

The decision came down to one question: **what does the workflow actually need?**

The research workflow is file-based. Sources are fetched once, cached to `research/{topic}/sources/`, and read from disk in every subsequent session. The analysis skill processes files, not conversation context. The personal reference library stores enriched entries as markdown files. Everything downstream expects a file on disk.

An MCP server produces content in conversation context. To fit the workflow, someone would still need to copy the transcript to a file. The "seamless" integration actually adds a step.

The script produces a file directly. It fits the workflow without adaptation. It's the simpler tool — not the simpler technology, but the simpler fit.

### The problem decomposition lens

[The Shift](../ai-engineering/the-shift.md) describes problem decomposition as a core engineering skill that matters more with AI — breaking a problem into components and solving each at the right level. The transcript problem decomposes into:

1. **Fetch** — get the transcript text from YouTube
2. **Format** — convert it to timestamped markdown with metadata
3. **Persist** — save it to disk in the right directory
4. **Integrate** — make it available to the research workflow

The script handles all four. The MCP server handles #1 and #2 but pushes #3 and #4 back to the user. The script solves the whole problem; the MCP server solves half of it more elegantly.

### The "architecturally elegant" trap

MCP servers are the more modern approach. They integrate with the AI's tool-calling infrastructure. They feel like the "right" way to extend an AI assistant's capabilities. But "right" in the abstract and "right for this workflow" are different questions.

The project already has [`fetch-sources.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-sources.py) — a Python script that fetches web pages as markdown with stealth headers, proxy support, and domain-aware rate limiting. Adding [`fetch-transcript.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-transcript.py) alongside it is consistent. Adding an MCP server introduces a new category of dependency for one use case.

This is the same judgment pattern the AI workflows essay describes: choosing tools that fit the actual work, not tools that fit an architectural vision.

---

## What Got Built

The [`fetch-transcript.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-transcript.py) script:

- Accepts a YouTube URL (any format) and an output path
- Extracts the video ID, fetches available transcript languages
- Saves as markdown with YAML-style metadata (title, channel, URL, duration, language, segment count, fetch date)
- Timestamps every segment for reference
- Supports batch mode via a text file of URLs
- Lives in [`.cursor/skills/research-and-analyze/scripts/`](../../.cursor/skills/research-and-analyze/scripts/) alongside [`fetch-sources.py`](../../.cursor/skills/research-and-analyze/scripts/fetch-sources.py)

The first test run fetched the Shi Heng Yi interview: 2,142 segments, 1 hour 37 minutes, saved as a markdown file that the research skill could immediately process. The [`/reference`](../../.cursor/commands/reference.md) command's video enrichment workflow was updated to call the script automatically.

Total development time: one conversation exchange for the script, one for testing, one for integration.

---

## The Deferred Options

The MCP server sits in the backlog as an Idea — not rejected, just not needed yet. If the workflow evolves to need real-time transcript access during conversation (e.g., the AI analyzing a video while discussing it), the MCP server becomes the right tool. The script doesn't close that door.

The Gemini API video understanding is a different capability entirely. When the project needs visual analysis of martial arts demonstrations — analyzing stances, movement patterns, technique execution — that's when it becomes relevant. For now, the text is what matters.

---

## What This Demonstrates

**The simplest tool that fits the workflow is often the best tool.** The script is less sophisticated than an MCP server. It's also less complex to maintain, easier to debug, and produces output that fits the existing file-based workflow without adaptation.

**AI presenting options is the beginning, not the end.** The AI surfaced all three options with honest trade-offs. The human made the judgment call based on workflow knowledge the AI didn't have: that every downstream consumer expects files on disk, that sessions end and context is lost, that operational simplicity matters for a solo developer's side project.

**Deferred is not rejected.** The backlog captures the MCP server and Gemini API as future options with clear descriptions of when they'd become relevant. The decision is documented, the alternatives are preserved, and the door stays open.

---

## Artifacts

| Artifact | What it is |
|---|---|
| [fetch-transcript.py](../../.cursor/skills/research-and-analyze/scripts/fetch-transcript.py) | The script that was built |
| [/reference command](../../.cursor/commands/reference.md) | Updated to use the script for video enrichment |
| [Research skill SKILL.md](../../.cursor/skills/research-and-analyze/SKILL.md) | Scripts index updated to include the transcript fetcher |
| [Shi Heng Yi transcript](../../research/zen-karate-philosophy/sources/they-betrayed-me---master-shi-heng-yi-explains-the-true-cost-of-success-shaolin-.md) | The first transcript fetched — primary source for the essay series |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
