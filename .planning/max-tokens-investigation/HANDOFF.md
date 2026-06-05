# Handoff: Max tokens cap investigation

## Context

We discovered that `pi-openai-compat/index.ts` line 133 hardcodes output token caps:
- Non-reasoning: `min(4096, contextWindow)`
- Reasoning: `min(16384, contextWindow)`

These are **not** model-enforced limits. The extension sets them in `ProviderModelConfig.maxTokens`, which gets passed to the API request. The backend (LiteLLM MaaS) enforces the real cap, but the extension never reads it.

## What we found

### Current state
- Extension queries `/v1/models` (standard OpenAI endpoint — no output token limit field)
- Extension queries `/model/info` (LiteLLM-specific — `model_info.max_tokens` = context window, NOT output limit)
- The code comments explicitly say: *"max_tokens on model_info is the context window (LiteLLM convention)"*
- Extension correctly uses `model_info.max_tokens` for **context window** (input side)
- Extension sets **output cap** to hardcoded 4096/16384 because nothing else is available

### Why 4096 exists
- **Commit 1** (May 3, initial): blanket `Math.min(4096, contextWindow)` — conservative default, no rationale in code or commit message
- **Commit 2** (May 7): reasoning models raised to 16384 with comment "Reasoning models need more output headroom for thinking traces"
- No code-level or commit-level justification for why 4096 specifically

### How other providers handle it

| Provider | Approach | Example values |
|----------|----------|---------------|
| `pi-anthropic-vertex` | Hardcoded per-model, matches official specs | Claude Sonnet: 64K, Opus: 128K, Haiku: 4.6: 8K |
| `pi-gitlab-duo` example | Hardcoded per-model | GPT-5.1: 16K, Claude 4.5: 16K |
| `pi-openai-compat` | Two hardcoded values for all models | 4096 non-reasoning, 16384 reasoning |

The first two read official model specs and hardcode those. Our extension reads API responses but ignores output token limits entirely.

### Real impact
- Qwen3.6-35B supports up to 16384 output tokens (per official docs)
- Extension caps it at 4096
- User sees `finish_reason: "max_tokens"` in session-log — but it's the extension's cap, not the model running out of capacity
- Complex answers get truncated mid-flow

### What 429 / session-log capture currently shows

Session log (`~/.pi/logs/pi-openai-compat/session-log.jsonl`) records:
- Non-standard finishes only (`max_tokens`/`length` and `error`)
- 429 events with retry-after header
- Excludes `end_turn`, `stop`, `stop_sequence` (normal completions)

The `message_end` handler (line 466-470):
```ts
const reason = msg.stop_reason ?? msg.stopReason ?? msg.finish_reason;
if (reason && reason !== "end_turn" && reason !== "stop" && reason !== "stop_sequence") {
    logEvent(ctx, { ts: ..., event: "finish", details: { reason, tokens: usage?.tokens } });
}
```

## What we need to do

**Goal:** Remove or reduce the artificial 4096 cap on output tokens.

**Constraints:**
- 10M TPM limit — runaway consumption is already managed by RPM/TPM tracking + 429 alerts
- No user-visible errors when increasing the cap
- Should work for any model the backend exposes, not just Qwen3

**Options (ranked by effort → benefit):**

### Option A: Raise the floor (lowest effort)
Change line 133 to remove the 4096 cap entirely, or raise it to match reasoning model cap:
```ts
// Before
maxTokens: reasoning ? Math.min(16384, contextWindow) : Math.min(4096, contextWindow),
// After (option A1 — remove all caps, let model return what it wants)
maxTokens: contextWindow,
// After (option A2 — raise non-reasoning to reasoning level)
maxTokens: Math.min(16384, contextWindow),
```
**Pros:** 3-line change, covers Qwen3's real limit (16384), no API dependency
**Cons:** May still be lower than some models' actual limits

### Option B: Read `max_output_tokens` from LiteLLM /model/info (medium effort)
Add `max_output_tokens?: number | null` to `LiteLLMModelInfo` interface. Use it if present, fall back to current logic.
**Pros:** Auto-discovers if backend supports it
**Cons:** LiteLLM MaaS may not expose it; need to verify what the actual backend returns

### Option C: Build a model map (highest effort, most accurate)
Like `pi-anthropic-vertex`: define known max output tokens per model by ID pattern.
**Pros:** Most accurate, matches what other providers do
**Cons:** Needs updating for new models, more code

## Files to touch

- `submodules/pi-openai-compat/index.ts` — line 133 (the hardcoded cap)
- `submodules/pi-openai-compat/index.ts` — `LiteLLMModelInfo` interface (if Option B)
- `research/agent-loop-hangs/journal.md` — update with findings and resolution

## Verification

```bash
cd submodules/pi-openai-compat && npx tsc --noEmit && npm test
cd ../zanshin-pi-extension && npx tsc --noEmit && npm test
```

Push both submodules, bump workspace pointer, pull into Pi cache, `/reload` to test.

## Key source references

- `submodules/pi-openai-compat/index.ts` line 133 — hardcoded cap
- `submodules/pi-openai-compat/index.ts` line 97 — comment "max_tokens on model_info is the context window (LiteLLM convention)"
- `submodules/pi-openai-compat/index.ts` line 466-470 — finish reason capture + logging
- `submodules/pi-openai-compat/index.ts` lines 298-299 — FINISH_REASON_MAP for max_tokens display
- `~/.pi/agent/extensions/pi-anthropic-vertex/index.ts` lines 44-80 — reference for how other providers set maxTokens
- `~/.pi/agent/extensions/pi-anthropic-vertex/node_modules/@earendil-works/pi-coding-agent/examples/extensions/custom-provider-gitlab-duo/index.ts` — another reference provider

## Decision needed

Option A (raise floor to 16384) is the obvious first step. If after testing you find some models still getting truncated, then Option B (try reading max_output_tokens from backend) or Option C (model map) becomes the next step. The question is whether to do the simple fix now or spend time investigating the backend API first.
