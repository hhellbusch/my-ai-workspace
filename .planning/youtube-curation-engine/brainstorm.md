# YouTube Curation Engine — Brainstorm

**Created:** 2026-06-08  
**Status:** Brainstorm / pre-planning  
**Related:** library/README.md (YouTube entries), research/ (transcripts), .agents/skills/youtube-transcript-library/

---

## Problem

High-velocity YouTube channels (especially @aidotengineer) post more content than can be consumed. Need a system to:
1. Surface signal: most-viewed videos in time buckets (1w, 1m, 3m, 6m)
2. Curate: rank by personal interest, not just raw view counts
3. Schedule: run periodically to build a watchlist

## Existing Infrastructure

- `library/README.md` — ~20 YouTube sources already tracked with wing tags and topics
- `research/` — transcript research directories
- `.agents/skills/youtube-transcript-library/` — 4-step ingest workflow (fetch → metadata → library entry → log)
- `fetch-transcript.py` at `.cursor/skills/research-and-analyze/scripts/`

## Landscape Research

### Claw Inbox (77zero/claw-inbox)
- **Active** since April 2026, runs daily YouTube monitoring
- Uses `yt-dlp --flat-playlist` — no view counts, no ranking
- Channels: Two Minute Papers, AI Explained, Matt Wolfe, Yannic Kilcher, Fireship, Lex Fridman
- Output: Chinese summaries of new videos
- **Gap:** Raw feed → no signal extraction, no personalization

### youtube-ai-notifier (dhruvil0203/youtube-ai-notifier)
- Monitors channels with OpenAI summaries, sends emails
- **Gap:** Generic summaries, no personalization

### YouTube channel monitoring bots (Reavert/youtube-watchdog, etc.)
- All notification/webhook focused (Discord bots)
- **Gap:** None do personalized ranking or interest-based curation

### The Gap
No one is doing **personalized video ranking** tied to an interest profile. Most solutions are either:
- "Notify on new upload" (bots)
- "Fetch + generic summary" (Claw Inbox)

## Current Channels in Library (YouTube)

| Channel | Wing | Topics |
|---------|------|--------|
| Simple Lucas | — | productivity, single-tasking |
| Rian Doris | — | neuroscience, flow, dopamine, focus |
| 3Blue1Brown | — | ai, neural-networks, deep-learning |
| Level1Techs | — | local-llm, quantization, moe |
| Alex Krentsel / OpenClaw | — | autonomous-agents, gateway, cron, skills |
| Karpathy (Sequoia, LLM Wiki) | — | ai-engineering, agentic-engineering |
| Daniel Miessler (Unsupervised Learning) — ai, knowledge-work |
| Dan Walsh (DevConf) | — | career, containers, open-source |
| AI Engineer London (Lopopolo, Horthy) | — | ai-engineering, harness, memory |
| Alberta Tech | — | claude-code, developer-psychology |
| Simon Scrapes | — | memory, claude-code, agents |
| Aidotengineer (target) | — | — |

## Platform Decision: Paude + OpenClaw

**Discovery:** Paude supports OpenClaw as a first-class agent (`--agent openclaw`), with its own config, gateway on port 18789, and pre-built image. This means the YouTube curation engine can run inside an OpenClaw agent, not built from scratch in Pi.

**OpenClaw architecture (from Paude source):**
- Web-based gateway (port 18789)
- Browser interface + CLI connection via `paude connect`
- Uses OpenTelemetry for diagnostics
- Pre-installed via npm or Docker image
- Supports multiple providers: anthropic, openai, vertex
- Tools config: `"profile": "coding"`, `"fs": {"workspaceOnly": true}`, `"exec": {"host": "gateway", "security": "allowlist"}`
- Yolo mode: `"security": "full", "ask": "off"`
- Supports custom skills/tools via workspace config

**Implications for the YouTube project:**
1. OpenClaw has built-in scheduling (heartbeat, cron) — no need to build scheduling
2. OpenClaw has persistent memory — interest profile can be stored as agent memory
3. OpenClaw has tool registry — YouTube API wrapper can be a registered tool
4. OpenClaw runs autonomously — the monitor can run on a schedule without Pi invocation
5. Git-based sync with Paude (commits, pull back) — same workflow as Pi in Paude

## Priority Ranking (Dependency Chain)

| Priority | Capability | Why |
|----------|-----------|-----|
| **1** | **YouTube Data API wrapper** | Core building block. Gets view counts, metadata, channel lists. MVP: on-demand command to rank recent videos from a channel by velocity. |
| **2** | **Secret injection pattern** | API key needs to flow through paude-proxy without touching container state. Paude operator concern — formalize "inject any env var from paude config." |
| **3** | **Scheduling mechanism** | OpenClaw has heartbeat/cron built-in. Need to understand how it works and how to integrate the YouTube monitor into OpenClaw's scheduling. |
| **4** | **Watchlist ranking tool** | Uses #1 + #2 → time-bucketed rankings (1w/1m/3m/6m) by view velocity. The MVP feature. |
| **5** | **Interest profile from library** | Reads library entries, tags, wings to build a topic vector. |
| **6** | **Curation engine** | Matches new videos against interest profile, scores them, recommends what to watch. "Tell me what to watch." |
| **7** | **Transcript scheduling** | Auto-fetch transcripts on schedule, enrich the curated watchlist. |

## Design Decisions

### Ranking Metric: View Velocity
Not raw views. A video posted yesterday with 10k views is more interesting than one posted 6 months ago with 50k views.
- Formula: `views / days_since_publish`
- Time buckets: 1w, 1m, 3m, 6m
- This is a well-known metric for "what's hot now"

### MVP Scope
Start with **#1 + #4** as a single pass:
- Python tool that takes a channel ID
- Queries YouTube Data API v3
- Ranks by velocity in time buckets
- Outputs a watchlist
- Run manually: `/watchlist aidotengineer`

**Implementation target:** OpenClaw workspace (not Pi extension). Python script invoked by cron job, results written to workspace, memory_search available for interest matching.

### Architecture Sketch
```
[youtube-curation/
  api.py          — YouTube Data API wrapper (channel info, video list, metadata)
  ranking.py      — Velocity calculator, time bucket sorter
  watchlist.py    — CLI entry point, output formatter
  config.json     — Channels, interests (user-maintained)
]
```

## Open Questions

### 1. Secret Injection Abstraction
Currently paude injects specific secrets (git PAT, model keys) into container env. Want a generic mechanism where **any** paude config value flows into the container as an env var.
- Needs upstream paude-pi-extension change
- Should support a list of env vars to inject from paude config
- Not hardcoded — discoverable from paude's config schema
- **Status:** Need to scope paude-pi-extension changes

### 2. OpenClaw vs Pi
- **Pi:** Coding focus, on-demand, extensions system
- **OpenClaw:** Autonomous scheduling, persistent memory, web gateway, broader tool ecosystem
- **Decision:** Use OpenClaw for scheduling/background work, Pi for active coding tasks

### 3. Channel Priority
Start with @aidotengineer, then expand. Should the priority list be:
- Based on library coverage (most-touched topics first)?
- Based on upload frequency?
- User-curated?

## Integration Points

### Pi Skill / Extension
- `/watchlist <channel>` command or tool
- Could be a Pi skill (`.agents/skills/youtube-curation/SKILL.md`)
- Extension would need: API wrapper, scheduling hook, UI output formatting

### Paude Secret Injection
- API key flows via env var (e.g., `YOUTUBE_API_KEY`)
- Paude operator config → container env injection
- Pattern should be generic, not YouTube-specific

### Library Integration
- Watchlist output could reference library entries ("You already watched this channel's video from 2026-05-30")
- Curation engine matches new videos against existing wing/topic tags

### Transcript Pipeline
- Curated watchlist → `/youtube-transcript-library` skill for ingest
- Could auto-fetch transcripts for top-ranked items on a schedule

## What to Ask Operator

1. **Paude secret injection:** Can we add a generic "inject env vars from paude config" mechanism to paude-pi-extension?
2. **Network allowlist:** Need `youtube.googleapis.com` and `www.googleapis.com` added if not already
3. **Scheduling:** Systemd timer or cron available in the container?

## References

- Claw Inbox: https://github.com/77zero/claw-inbox
- YouTube Data API v3: https://developers.google.com/youtube/v3
- Pi extension docs: `/usr/local/lib/node_modules/@earendil-works/pi-coding-agent/docs/extensions.md`
- Pi SDK docs: `/usr/local/lib/node_modules/@earendil-works/pi-coding-agent/docs/sdk.md`
- Paude extension: `/pvc/workspace/submodules/paude-pi-extension/extensions/paude-l0.ts`
- Paude OpenClaw agent: `/pvc/workspace/git-projects/paude/src/paude/agents/openclaw.py`

## Practical: Spinning Up OpenClaw via Paude

### Fork Status
Fork at `/pvc/workspace/git-projects/paude` is **fully up-to-date** with upstream. No lag. All agents are present (claude, codex, cursor, gascity, gemini, openclaw).

**Hermes is NOT in Paude.** Hermes Agent (https://github.com/txai/hermes) is a separate coding assistant. It exists in the ecosystem (Switch UI, session finder tools, terminal agent benchmarks) but Paude does not support it as an agent type.

### Prerequisites
- **Container runtime:** Podman or Docker (not present inside the Pi container — you'd run Paude commands from your host)
- **API credentials:** One of:
  - `ANTHROPIC_API_KEY` (for Anthropic provider)
  - `OPENAI_API_KEY` (for OpenAI provider)
  - `ANTHROPIC_VERTEX_PROJECT_ID` + `GOOGLE_CLOUD_PROJECT` (for Vertex AI provider)
- **Vertex + ADC:** `gcloud auth application-default login` for Vertex auth

### Steps

1. **Install Paude** (on host):
   ```bash
   uv tool install paude
   ```

2. **Create OpenClaw session:**
   ```bash
   # With OpenAI
   paude create --agent openclaw --provider openai --allowed-domains "default openclaw youtube" my-youtube-curator
   
   # With Anthropic
   paude create --agent openclaw --provider anthropic --allowed-domains "default openclaw youtube" my-youtube-curator
   
   # With Vertex AI (recommended for existing PAI/Kai infrastructure)
   paude create --agent openclaw --provider vertex --allowed-domains "default openclaw youtube" my-youtube-curator
   ```

3. **Connect** (terminal mode):
   ```bash
   paude connect my-youtube-curator
   ```

4. **Connect** (web mode — for OpenClaw, a browser URL is printed):
   ```bash
   paude connect my-youtube-curator
   # Opens http://localhost:18789 in browser
   ```

### paude.json Update
Your workspace `paude.json` currently only has `"agent": "pi"`. To use OpenClaw by default:
```json
{
  "setup": "pip install requests beautifulsoup4 markdownify pdfplumber youtube-transcript-api",
  "create": {
    "allowed-domains": ["default", "research", "youtube", "openclaw"],
    "agent": "openclaw"
  }
}
```

### What Happens Inside the Container
- OpenClaw is pre-installed from `ghcr.io/openclaw/openclaw:latest`
- Gateway listens on port 18789
- Config at `~/.openclaw/openclaw.json`
- Workspace mounted at `/pvc/workspace`
- Python packages installed via `paude.json` setup
- Secrets delivered via `/credentials/env/` (not visible in container spec)
- Git-based sync: agent commits, you `git pull`

### What You Need from Operator
1. **Network allowlist:** `youtube.googleapis.com`, `www.googleapis.com` (for YouTube Data API)
2. **Secret injection:** Add `YOUTUBE_API_KEY` to the generic env var injection mechanism
3. **Provider credentials:** API key for whichever provider you use (OpenAI, Anthropic, or Vertex)
