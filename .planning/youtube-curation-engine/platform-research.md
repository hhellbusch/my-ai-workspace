# Platform Research — OpenClaw vs Pi for YouTube Curation

**Created:** 2026-06-08  
**Status:** Research complete  
**Related:** brainstorm.md, Paude OpenClaw agent docs

---

## OpenClaw Architecture (from Paude source)

Paude treats OpenClaw as a first-class agent with its own implementation at `/pvc/workspace/git-projects/paude/src/paude/agents/openclaw.py`.

### Integration Points
- **Gateway:** Web-based, port 18789, browser interface
- **CLI:** Terminal connection via `paude connect`
- **Base image:** `ghcr.io/openclaw/openclaw:latest` (pre-installed)
- **Config:** `~/.openclaw/openclaw.json`
- **Providers:** Anthropic, OpenAI, Vertex AI (model-agnostic)
- **Tools config:** `"profile": "coding"`, `"fs": {"workspaceOnly": true}`, `"exec": {"host": "gateway", "security": "allowlist"}`
- **Yolo mode:** `"security": "full", "ask": "off"`
- **OTEL:** Diagnostics plugin built-in
- **Network:** `extra_domain_aliases: ["openclaw"]`

### Pi vs OpenClaw Tradeoffs

| Capability | Pi | OpenClaw | Winner for YouTube |
|------------|----|----------|--------------------|
| Scheduling | None (need cron wrapper) | Built-in heartbeat + cron | OpenClaw ✅ |
| Memory | Session-based, no built-in persistence | MEMORY.md + search + wiki | OpenClaw ✅ |
| On-demand coding | Excellent (native) | Good (has it) | Pi ✅ |
| Extensions | TypeScript, rich API (registerTool, registerCommand, events) | Skills (workspace-based) | Pi ✅ |
| Auto-detection | None | Heartbeat checks for attention | OpenClaw ✅ |
| Channel routing | None | Multi-channel (WhatsApp, Telegram, Discord, etc.) | N/A for this use |
| Tool ecosystem | MCP-compatible | MCP-compatible + native tools | Tie |
| Secrets | env var passthrough (current) | env var passthrough via Paude | Tie |
| Git sync | Paude (commit/pull workflow) | Paude (commit/pull workflow) | Tie |

### Verdict
**Hybrid approach.** OpenClaw handles scheduled monitoring + memory + curation. Pi handles active coding, extension development, and the YouTube API wrapper tooling. Both run in Paude containers with the same git-based sync workflow.

---

## OpenClaw Built-in Scheduling

### Heartbeats — Periodic Agent Turns

**What it is:** Heartbeat runs periodic agent turns in the main session so the model can surface anything needing attention without spamming.

**Key features for YouTube curation:**
- **Default cadence:** 30m (1h for Anthropic OAuth)
- **Configurable:** `agents.defaults.heartbeat.every` — set `0m` to disable
- **Context control:** 
  - `isolatedSession: true` — fresh session each run, no conversation history bloat
  - `lightContext: true` — only inject `HEARTBEAT.md` from workspace bootstrap files (token-efficient)
- **Delivery:** `target: "last"` routes to last contact channel; `target: "none"` is default
- **Response contract:** Reply `HEARTBEAT_OK` when nothing needs attention — auto-stripped and dropped (≤ `ackMaxChars`, default 300)
- **Active hours:** Timezone-aware business hours restriction
- **Skip when busy:** `skipWhenBusy: true` defers when agent is busy with subagent or nested command lanes

**Example config:**
```json5
{
  agents: {
    defaults: {
      heartbeat: {
        every: "1h",
        target: "last",
        isolatedSession: true,
        lightContext: true,
        prompt: "Run youtube-watchlist. Check for new high-velocity videos on monitored channels. Score against interest profile in MEMORY.md. If nothing needs attention, reply HEARTBEAT_OK.",
      },
    },
  },
}
```

### Cron Jobs — Scheduled Tasks

**What it is:** Gateway's built-in scheduler. Persists jobs in SQLite, wakes agent at right time, delivers output to chat channels or webhooks.

**Schedule types:**
| Kind | CLI flag | Description |
|------|----------|-------------|
| `at` | `--at` | One-shot timestamp (ISO 8601 or relative like `20m`) |
| `every` | `--every` | Fixed interval |
| `cron` | `--cron` | 5-field or 6-field cron expression with optional `--tz` |

**Execution styles:**
| Style | `--session` value | Runs in | Best for |
|-------|-------------------|---------|----------|
| Main session | `main` | Dedicated cron wake lane | Reminders, system events |
| Isolated | `isolated` | Dedicated `cron:<jobId>` | Reports, background chores |
| Current session | `current` | Bound at creation time | Context-aware recurring work |
| Custom session | `session:custom-id` | Persistent named session | Workflows that build on history |

**Command payloads** — deterministic scripts without needing a model:
```bash
openclaw cron create "*/15 * * * *" \
  --name "Queue depth probe" \
  --command "scripts/check-queue.sh" \
  --command-cwd "/srv/app" \
  --announce \
  --channel telegram \
  --to "-1001234567890"
```

**Delivery modes:**
| Mode | What happens |
|------|--------------|
| `announce` | Fallback-deliver final text to target if agent didn't send |
| `webhook` | POST finished event payload to URL |
| `none` | No runner fallback delivery |

**Error handling:** Timeouts, provider fallbacks, task reconciliation with durable history.

---

## OpenClaw Memory System

### File-Based Memory

| File | Purpose | Loaded when |
|------|---------|-------------|
| `MEMORY.md` | Long-term memory — durable facts, preferences, decisions | Start of every DM session |
| `memory/YYYY-MM-DD.md` | Daily notes — detailed context, observations | Today + yesterday automatically, slugged variants via memory_search |
| `DREAMS.md` | Dreaming sweep summaries for human review | Optional, human review |

### Memory Tools

- **`memory_search`** — Hybrid search (vector + BM25 keyword). Finds relevant notes even when wording differs.
- **`memory_get`** — Read specific memory files or line ranges.
- **Active Memory plugin** — Blocking memory sub-agent that runs *before* the main reply, injects relevant memory automatically.
- **Memory Wiki plugin** — Structured knowledge as a wiki vault with `wiki_search`, `wiki_get`, `wiki_apply`, `wiki_lint`.

### Memory Providers (Embeddings)

| Provider | ID | Needs API Key | Notes |
|----------|----|--------------|-------|
| Bedrock | `bedrock` | No | Uses AWS credential chain |
| DeepInfra | `deepinfra` | Yes | Default: `BAAI/bge-m3` |
| Gemini | `gemini` | Yes | Supports image/audio indexing |
| GitHub Copilot | `github-copilot` | No | Uses Copilot subscription |
| Local | `local` | No | GGUF model, ~0.6 GB download |
| Mistral | `mistral` | Yes | |
| Ollama | `ollama` | No | Local/self-hosted |
| OpenAI | `openai` | Yes | Default |
| OpenAI-compatible | `openai-compatible` | Usually | Generic `/v1/embeddings` |
| Voyage | `voyage` | Yes | |

### Key Features for Curation
- **Temporal decay** — Old notes lose ranking weight (default 30-day half-life). Evergreen files like `MEMORY.md` are never decayed.
- **Inferred commitments** — Short-lived follow-up memories, delivered through heartbeat.
- **Action-sensitive memories** — Capture approval context, expiry conditions, safe-to-act timing.

---

## OpenClaw Skills System

Skills in OpenClaw are workspace-based, similar to Pi skills but with a different integration model. They live in the workspace directory and are loaded from there.

**Comparison to Pi:**
| | Pi | OpenClaw |
|---|---|---|
| Location | `~/.pi/agent/skills/`, `~/.cursor/skills/` | Workspace `.agents/skills/` or `.cursor/skills/` |
| Format | SKILL.md with YAML frontmatter | Similar SKILL.md format |
| Registration | Auto-discovered by Pi | Auto-discovered by OpenClaw |
| Extension system | TypeScript extensions (registerTool, registerCommand, events) | Plugins (active-memory, memory-wiki, diagnostics-otel) |
| Custom tools | Yes (TypeScript) | MCP-compatible tools |
| Command hooks | Yes (registerCommand) | Via cron and heartbeat prompts |

**Key insight:** For the YouTube curation engine, we can use OpenClaw's skills for the interface layer (like a `/watchlist` command), and its plugins for the memory/search layer. The heavy lifting (YouTube API wrapper) can be a Python script that the skills/cron invokes.

---

## OpenClaw Multi-Channel Delivery

OpenClaw supports a wide range of messaging channels:
- WhatsApp, Telegram, Slack, Discord, Google Chat, Signal
- iMessage, IRC, Microsoft Teams, Matrix, Feishu, LINE
- Mattermost, Nextcloud Talk, Nostr, Synology Chat, Tlon
- Twitch, Zalo, WeChat, QQ, WebChat

The Gateway is the control plane — the product is the assistant. This means a YouTube watchlist could be delivered to any of these channels, not just the Paude container.

**For this project:** Probably irrelevant for now. The Paude container git workflow is sufficient for delivering results back to the workspace.

---

## Paude-Proxy — Credential Broker

**Paude-proxy is a MITM credential broker.** It sits between the agent container and the internet, intercepts HTTPS requests, and injects real API keys into request headers based on destination domain. The agent never sees real credentials.

### Architecture
```
Agent (dummy creds) → paude-proxy:3128 → Real upstream
                        ↓
                  Injects real API keys
```

### How It Works
1. Agent sends requests with dummy credentials (e.g., `ANTHROPIC_API_KEY=paude-proxy-managed`)
2. Proxy terminates TLS (MITM) using a shared CA cert
3. Proxy looks up destination domain in credential routing table
4. Proxy replaces auth header with real credentials
5. Proxy forwards to upstream over new TLS connection
6. Response passes back unmodified

### Security Model
- **Credential theft prevention:** Real credentials only exist in the proxy, never in the agent container
- **Domain routing:** Strict suffix matching (`.openai.com` does NOT match `evil-openai.com`)
- **Host header forgery protection:** Routing uses CONNECT target (TCP layer), not Host header
- **No redirect following:** 3xx responses pass through to client (no redirect-based credential leakage)
- **Source IP filtering:** `PAUDE_PROXY_ALLOWED_CLIENTS` restricts which IPs can connect

### Credential Routing Configuration

**Default config** is embedded in the binary at `internal/credentials/credentials.json`.

**Custom config:** Pass via `PAUDE_PROXY_CREDENTIALS_CONFIG=/path/to/credentials.json`

**Injector types:**
| Type | Description | Required params |
|---|---|---|
| `bearer` | `Authorization: Bearer <value>` | — |
| `api_key` | Custom header with credential value | `header_name` |
| `gcloud` | OAuth2 Bearer from ADC (auto-refreshed) | — |

### Google Cloud ADC (Vertex AI) — Two-Step Flow

For Google Cloud APIs, the proxy uses a special two-step approach:
1. **Token vending:** Agent has a stub ADC file with dummy values. When its auth library POSTs to `oauth2.googleapis.com/token`, the proxy intercepts and returns a dummy token.
2. **Credential injection:** When the agent calls `*.googleapis.com` with the dummy Bearer token, the proxy's `GCloudInjector` replaces it with a real OAuth2 token from its own ADC.

The agent never sees any real credential — not the refresh token, not even a short-lived access token.

### Rolling Into Paude (from integration docs)

Paude has planned a phased rollout to replace its squid proxy with paude-proxy:
- Phase 1: Build and publish paude-proxy image (done — repo exists)
- Phase 2: Add `--proxy-type=mitm` flag behind a feature flag
- Phase 3: Test with each agent type (Claude Code, Cursor, Gemini, OpenClaw)
- Phase 4: Make paude-proxy the default
- Phase 5: Remove squid

**Current state:** Squid is still the default in Paude. paude-proxy exists as a submodule (`submodules/paude-proxy/`) with full implementation and docs.

### What This Means for YouTube API Key

The YouTube API key needs to be added to the credential routing table. Two options:

1. **Workspace-level config** (no paude-proxy changes needed):
   - Create `paude-proxy-config.json` in the workspace
   - Pass it via `PAUDE_PROXY_CREDENTIALS_CONFIG` env var
   - Add `YOUTUBE_API_KEY` → `youtube.googleapis.com` route

2. **Upstream paude integration** (requires paude changes):
   - Add YouTube API key entry to the default credentials.json
   - This would require Ben's approval/PR since upstream is quiet

**Recommendation:** Option 1 — workspace-level config. No dependency on paude changes.

---

## What's Still Needed

### 1. Secret Injection Pattern

**Paude-proxy already solves this — and does it better than env var injection.**

Paude-proxy is a MITM credential broker running as a separate container (port 3128). The model:
- Agent sends dummy credentials (e.g., `ANTHROPIC_API_KEY=paude-proxy-managed`)
- Proxy terminates TLS via MITM, looks up the destination domain in its credential routing table
- Proxy replaces the auth header with real credentials before forwarding to upstream
- Agent never sees, stores, or can exfiltrate real credentials

**Current default credential routing table:**
| Env Var | Domain Pattern | Header Injected |
|---|---|---|
| `ANTHROPIC_API_KEY` | `*.anthropic.com` | `x-api-key: <key>` |
| `OPENAI_API_KEY` | `*.openai.com` | `Authorization: Bearer <key>` |
| `CURSOR_API_KEY` | `*.cursor.com`, `*.cursorapi.com` | `Authorization: Bearer <key>` |
| `GH_TOKEN` | `github.com`, `api.github.com` | `Authorization: Bearer <PAT>` |
| `GOOGLE_APPLICATION_CREDENTIALS` | `*.googleapis.com` | `Authorization: Bearer <token>` (auto-refreshed OAuth2) |

**For YouTube API:** Add an entry to the credential routing config:
```json
{
  "env_var": "YOUTUBE_API_KEY",
  "injector": "api_key",
  "params": { "header_name": "Authorization" },
  "domains": ["youtube.googleapis.com", "www.googleapis.com"]
}
```

**Custom credential routing:** The proxy supports `PAUDE_PROXY_CREDENTIALS_CONFIG` pointing to a custom JSON file. This means YouTube API key injection can be done without modifying paude-proxy source — just pass a config file.

**Status:** Solved by paude-proxy's credential routing. Need to add YouTube API key to the routing config.

### 2. YouTube API Integration
OpenClaw's tools system is MCP-compatible. We'd need:
- A Python script that wraps the YouTube Data API v3
- Skills or cron jobs that invoke it
- Memory files that store the interest profile

### 3. Interest Profile Storage
This is the key innovation — storing a topic vector or interest profile that the curation engine uses to rank videos:
- Option A: `MEMORY.md` entry with topic weights
- Option B: `memory/interests.md` with structured data
- Option C: Memory Wiki with structured claims about topics
- **Recommended:** Option A for simplicity — one `INTERESTS.md` in the workspace with topic tags and weights

---

## Next Steps

1. **Design the YouTube API wrapper** — Python tool that queries YouTube Data API, returns ranked results
2. **Design the interest profile format** — How do we represent what topics the user cares about?
3. **Design the cron/heartbeat integration** — How does OpenClaw invoke the wrapper on a schedule?
4. **Implement MVP** — YouTube API wrapper + manual invocation first, then schedule

---

## References

- OpenClaw README: https://github.com/openclaw/openclaw
- OpenClaw heartbeat: `docs/gateway/heartbeat.md`
- OpenClaw cron: `docs/automation/cron-jobs.md`
- OpenClaw memory: `docs/concepts/memory.md`, `docs/concepts/memory-search.md`, `docs/concepts/active-memory.md`
- OpenClaw memory wiki: `docs/plugins/memory-wiki.md`
- Paude OpenClaw agent: `/pvc/workspace/git-projects/paude/src/paude/agents/openclaw.py`
- Paude docs: `/pvc/workspace/git-projects/paude/docs/`
- Pi extension docs: `/usr/local/lib/node_modules/@earendil-works/pi-coding-agent/docs/extensions.md`
- **Paude-proxy:** `submodules/paude-proxy/` — MITM credential broker
  - `README.md` — full docs on how the credential injection works
  - `docs/PAUDE_INTEGRATION.md` — planned rollout into Paude (squid → paude-proxy migration)
  - `internal/credentials/credentials.json` — current default routing table
  - `internal/credentials/config.go` — credential config schema
  - `internal/credentials/gcloud.go` — Google ADC token vending

## Practical: Spinning Up OpenClaw via Paude

### Fork Status
Fork at `/pvc/workspace/git-projects/paude` is **fully up-to-date** with upstream. All agents present (claude, codex, cursor, gascity, gemini, openclaw).

**Hermes is NOT in Paude.** Hermes Agent exists in the ecosystem (Switch UI, session finder tools, terminal agent benchmarks) but Paude does not support it as an agent type. The Paude agent registry is: claude, codex, cursor, gascity, gemini, openclaw.

### Prerequisites (host machine)
- **Container runtime:** Podman or Docker (not present inside Pi container)
- **API credentials:** One of:
  - `ANTHROPIC_API_KEY` (Anthropic provider)
  - `OPENAI_API_KEY` (OpenAI provider)  
  - `ANTHROPIC_VERTEX_PROJECT_ID` + `GOOGLE_CLOUD_PROJECT` (Vertex AI)
- **Vertex + ADC:** `gcloud auth application-default login` for Vertex auth

### Steps

1. **Create OpenClaw session:**
   ```bash
   paude create --agent openclaw --provider openai --allowed-domains "default openclaw youtube" my-youtube-curator
   ```
   (Or `--provider anthropic` / `--provider vertex`)

2. **Connect:**
   ```bash
   paude connect my-youtube-curator  # prints browser URL for OpenClaw
   ```

### Inside the Container
- OpenClaw pre-installed from `ghcr.io/openclaw/openclaw:latest`
- Gateway on port 18789
- Config at `~/.openclaw/openclaw.json`
- Workspace at `/pvc/workspace`
- Python packages from `paude.json` setup
- Secrets via `/credentials/env/` (not visible in container spec)
- Git sync: agent commits → `git pull`

### What You Need from Operator
1. Network allowlist: `youtube.googleapis.com`, `www.googleapis.com`
2. Secret injection: Add `YOUTUBE_API_KEY` to generic env var injection
3. Provider API key (OpenAI, Anthropic, or Vertex)
