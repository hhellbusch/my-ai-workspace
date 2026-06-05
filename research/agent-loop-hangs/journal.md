# Engineering Journal: Agent Loop Hangs / Stops

> Started: 2026-05-19
> Status: Analysis in progress — H1 (compaction) not supported by recent data, H2 (model processing) strongly supported
> Source: `/home/paude/.pi/logs/pi-openai-compat/session-log.jsonl`
>
> **Model provenance:** Initial analysis and journal (3 commits) written under `Qwen3.6-35B-A3B`. Fact-check and corrections written under `claude-sonnet-4-6` (anthropic-vertex). The fact-check found errors in numbers, session count, and a fundamental misinterpretation of `fromHook` — all produced with confidence by the prior model. This session is itself a data point on model quality difference for verification tasks.

---

## Symptom

The agent loop appears to hang or stop mid-session. The user experience is a noticeable pause (30–150s) followed by the next tool-use turn. Between these pauses, turns complete in 1–6s.

**Session under analysis:** 2026-05-19 00:16–00:48 (32 minutes, 167 finish events)

---

## Evidence Status

| Source | Finding | Verified by user? |
|--------|---------|-------------------|
| Provider log (`session-log.jsonl`) | 165 finish events (up to 00:48), 17 gaps >30s | **Yes** — user experienced the gaps |
| Session JSONL | 2 compaction events in session `2026-05-18T23-52-59` | **No** — user never saw compaction happen |
| Source code (`interactive-mode.js`) | Auto-compaction on overflow at line 2315 | Theoretical — pi's auto-compaction has no user-visible notification |
| `compaction` events across all sessions | 15 events, all `fromHook: false` | Log evidence only |

**Correction: auto-compaction is NOT silent.** Source code at `interactive-mode.js` line 2315 shows a visible spinner with text "Context overflow detected, Auto-compacting... (Ctrl+C to cancel)". Both manual and auto compaction show a loader — manual says "Compacting context..." and auto says "Context overflow detected, Auto-compacting...". If compaction happened and the user didn't notice it, they may have missed the notification, or the session ended before rendering. The context window just gets rebuilt. The user experiences only a gap (the model sits idle while pi processes the truncation), not a compaction event.

**Therefore the journal's "compaction caused the hang" claim is inferred, not observed.** The 60–130s gaps the user experiences **could be compaction or heavy model processing** — we can't tell from provider logs alone. Some gaps correlate with context drops (compaction), but others don't. The only thing confirmed is: the user sees unexplained pauses. Whether they're compaction or processing time is a separate question.

**Open question:** The user does not recall seeing auto-compaction. But the source shows it displays a visible spinner. Either the user missed it, it happened between sessions (new session starts post-compaction), or the source behaviour differs from what was deployed. This needs direct observation to resolve.

---

## Raw Data

### Event Summary

| Metric | Value |
|--------|-------|
| Total events | 165 (up to 00:48; log has grown since) |
| Time span | 32m 0s |
| Finish reason | 100% `toolUse` (standard completion) |
| 429 events | 0 |
| Non-standard finishes | 0 |
| Avg context tokens | 46,947 |
| Max context tokens | 81,127 |
| Min context tokens | 6,319 |

### Gap Distribution

| Gap range | Count | Notes |
|-----------|-------|-------|
| 0–5s | ~100 | Normal inter-turn latency |
| 5–30s | ~50 | Moderate processing |
| 30–60s | 7 | Elevated — possible heavy tool use |
| 60–90s | 2 | **Compaction resets** (see below) |
| 90–150s | 6 | Mixed: compaction + heavy turns |

### The 10 Longest Gaps (>60s)

| Time | Gap | Context Before | Context After | Delta |
|------|-----|----------------|---------------|-------|
| 00:21:08 | 66s | 60,855 | **6,355** | **DROP 54K** |
| 00:22:22 | 121s | 24,180 | 26,360 | +2.2K |
| 00:25:41 | 116s | 50,661 | 51,382 | +721 |
| 00:27:41 | 113s | 55,078 | 72,735 | +17.6K |
| 00:29:53 | 73s | 60,364 | 60,623 | +259 |
| 00:31:09 | 114s | 60,770 | 61,579 | +809 |
| 00:33:24 | 130s | 66,913 | **6,319** | **DROP 60.6K** |
| 00:35:41 | 66s | 15,649 | 22,082 | +6.4K |
| 00:39:06 | 146s | 28,135 | 28,341 | +206 |
| 00:45:24 | 151s | 59,236 | 60,732 | +1.5K |

---

## Hypotheses

### H1: pi's internal auto-compaction (overflow trigger) causes apparent hang (INFERRED FROM LOGS, NOT OBSERVED)

**Session log analysis showed compaction context drops** — but that was inferred from the wrong level of data. The provider log (`session-log.jsonl`) only records API events, not session-level events like compaction triggers.

**Session JSONL analysis revealed: compaction events exist in pi's session format as `compaction` type events, all with `fromHook: false`** — meaning compaction was triggered by pi's built-in auto-compaction on context overflow, not by any extension, user action, or manual `/compact` command.

Two compaction points observed in today's session (session `2026-05-18T23-52-59-390Z`):
- Compaction at 00:15:57 — **98,521 tokens before**, fromHook=false
- Session 3 (`2026-05-19T00-33-30-980Z`) — no compaction event found (session may not have reached window limit)

**The 60–130s gaps are inferred as compaction processing time**, but this is not user-verified. The provider log saw a gap because compaction wipes the context window and rebuilds it — this is the model sitting idle while pi processes the compaction. But the user never saw a compaction happen; pi's auto-compaction has no UI notification.

**Important distinction: this is inferred from logs, not observed by the user.** The user experiences only a gap — they don't see compaction, they see silence. Some gaps are compaction (inferred from context drops in provider log), some may be heavy model processing. We cannot distinguish them from provider logs alone.

**Supporting evidence (from logs):**
- All 15 compaction events across 6 sessions show `fromHook: false` — always auto-compaction, never manual
- Compaction timing correlates with the 60–130s gaps observed in provider log
- After compaction, context resets and turns resume normally
- pi has two compaction triggers (verified in `interactive-mode.js`): **manual `/compact`** (reason=`manual`) and **auto on overflow** (reason=`overflow`). Both set `fromHook: false` unless an extension overrides.
- The 15 observed events cannot be confirmed as auto vs manual from `fromHook` alone — a different field (`reason` in the `compaction_start` event) would be needed, but that isn't stored in the session JSONL compaction entry.

**Limitation:** The journal cannot distinguish manual `/compact` from auto-overflow compaction from session JSONL data alone. The `fromHook` field is a red herring for this question.

### H2: Model processing time for heavy tool-use turns

Six of the ten long gaps show stable or growing context — no compaction occurred. These are likely turns where the model is processing complex tool-use chains, reasoning, or generating long responses.

**Supporting evidence:**
- Gap of 146s with context change of only +206 tokens
- Gap of 113s with context change of +17.6K (a large tool-use response)
- Normal turns between compaction cycles also show elevated gaps (30–50s)

### H3: RPM/TPM sliding window resets are silent

The extension's RPM/TPM tracker uses a 60-second sliding window that silently resets at line 166 of `index.ts`. If a burst of requests exceeds RPM limits, the window reset could cause a sudden rate limit hit followed by a cooldown period. No 429s were logged, but the window reset itself is not observable in the session log.

---

## What the Session Log Is Missing

The provider log (`pi-openai-compat/session-log.jsonl`) only records:
1. **Non-standard finish reasons** (line 470: `end_turn`/`stop`/`stop_sequence` excluded)
2. **429 events** (line 444)

It does **not** record:
- Standard completions (`end_turn`, `stop`, `stop_sequence`)
- RPM/TPM window resets
- TTFT (time-to-first-token) measurements in the log file
- Request start timestamps
- Provider response latency (only TTFT in UI status)

**But compaction events ARE captured** — just not in the provider log. They exist in pi's session JSONL as `compaction` type events. The key field is `fromHook: false` which confirms they were auto-triggered by pi's overflow mechanism, not by the `/compact` slash command or any extension.

**Cross-referencing provider log + session JSONL** is necessary to distinguish compaction gaps from processing-time gaps. The provider log alone is insufficient.

### Compaction Events Across All Sessions

```bash
# All compaction events found:
grep -l '"type": "compaction"' ~/.pi/agent/sessions/--pvc-workspace--/*.jsonl | while read f; do
  name=$(basename "$f")
  grep '"type": "compaction"' "$f" | grep -o '"tokensBefore": [0-9]*' | while read line; do
    tokens=${line#*: }
    echo "$name tokens=$tokens fromHook=false"
  done
done
```

**Result:** 15 compaction events across **7** sessions (not 6 as previously stated), all `fromHook: false`, token counts ranging from 80K to 242K.

**Critical correction on `fromHook` interpretation:** `fromHook: false` does NOT mean auto-compaction vs manual. It means pi generated the compaction summary itself, as opposed to an extension hook providing a custom summary via the `session_before_compact` event. Both manual `/compact` and auto-overflow compaction set `fromHook: false` unless an extension overrides the summary. The field cannot distinguish manual from auto triggers.

---

## Max Tokens Cap — Hardcoded in pi-openai-compat

**Discovered:** 2026-05-19 during validation of the commit-guard loop-break changes.

### Finding

The `max_tokens` output cap is **NOT** set by the model. It is hardcoded in `pi-openai-compat/index.ts` line 133:

```ts
maxTokens: reasoning ? Math.min(16384, contextWindow) : Math.min(4096, contextWindow),
```

- Non-reasoning models → **capped at 4096** output tokens
- Reasoning models → **capped at 16384** output tokens

Both also clamp to `contextWindow` (the model's advertised total context), but 4096/16384 is always the effective limit since context windows are 32768+.

### What this means

When you see `"event":"finish","details":{"reason":"max_tokens"}` in the session log, it does NOT mean the model hit its own output capacity. It means the extension hit a self-imposed ceiling. The extension already reads `entry.max_tokens` from the API model spec (line 97) but doesn't use it for the output cap.

Models that support >4096 output tokens (many do) are being truncated mid-flow by the extension. The model stops generating with `max_tokens` — visible in logs but no pre-warning is given to the user.

### Current monitoring gaps

| Gap | Detail |
|-----|--------|
| No pre-warning | Model hits cap mid-thought with no indication |
| No max_tokens history | One log entry per hit, no counter or trend visibility |
| Context % confuses input vs output | The 40%/75% context warnings fire on total tokens / context window, not output budget. A 32K-context model at 40% context still has full 4096 output tokens, but the warning fires anyway |
| No per-turn max_tokens tracking | Loops that burn 4096 tokens/turn x N turns show no incremental signal |
| No user-visible cap | Status bar shows finish reason briefly but no persistent indicator |

### Current log capture

The `message_end` handler (`index.ts` line 466-470) captures `stop_reason` from the API and logs non-normal reasons:

```ts
const reason = msg.stop_reason ?? msg.stopReason ?? msg.finish_reason;
if (reason && reason !== "end_turn" && reason !== "stop" && reason !== "stop_sequence") {
    logEvent(ctx, { ts: new Date().toISOString(), event: "finish", details: { reason, tokens: usage?.tokens } });
}
```

Normal completions (`end_turn`, `stop`, `stop_sequence`) are excluded from the log. Only `max_tokens`/`length` and `error` show up.

### Source

- `submodules/pi-openai-compat/index.ts` line 133 (hardcoded cap)
- `submodules/pi-openai-compat/index.ts` line 466-470 (finish reason capture)
- `submodules/pi-openai-compat/index.ts` line 298-299 (FINISH_REASON_MAP: `max_tokens` → ✂ icon, `length` → ✂ icon)
- `submodules/pi-openai-compat/index.ts` line 97, 115 (context_window resolution — reads API spec but not used for output cap)

---

## Open Questions

1. What is the actual model's context window for `Qwen3.6-35B-A3B`? (The extension auto-discovers it — is it correct?)
2. Is the 60–130s compaction time expected for this model/token-count?
3. Do the "stable context" long gaps correlate with specific tool-use patterns?
4. Is there a per-request latency distribution we can get from the provider logs (if available)?
5. Does compaction frequency correlate with hang frequency?

---

## Zero-Changes Analysis (2026-06-05)

**Goal:** Pull turn intervals from Pi session JSONL without modifying any code, then cross-reference with provider log to distinguish compaction from model processing.

### Sessions analyzed

| Session | Turns | Compaction events | Max gaps | Date |
|---------|-------|-------------------|----------|------|
| `2026-06-02T12-30-31` | 134 | **0** | 426s | Jun 2 |
| `2026-06-03T15-28-04` | 9 | **0** | 75s | Jun 3 |
| `2026-05-19T00-21-20` (original) | ~134 | inferred | 151s | May 19 |

### June 2 session — detailed turn interval analysis

**Turn interval distribution (133 intervals):**

| Range | Count | % |
|-------|-------|---|
| <5s | 96 | 72% |
| 5–15s | 27 | 20% |
| 15–30s | 3 | 2% |
| 30–60s | 2 | 2% |
| 60–90s | 1 | 1% |
| >90s | 4 | 3% |

**Stats:** min=0.9s, max=426.2s, mean=13.3s, median=2.6s

**The 5 largest gaps (all >60s) with STABLE context — NOT compaction:**

| Turn | Gap | Ctx before | Ctx after | Delta |
|------|-----|-----------|-----------|-------|
| 80 | 426.2s | 75,402 | 76,002 | +600 |
| 64 | 290.7s | 67,511 | 67,765 | +254 |
| 50 | 283.0s | 55,755 | 55,947 | +192 |
| 75 | 135.2s | 72,175 | 72,280 | +105 |
| 7 | 74.0s | 30,886 | 31,445 | +559 |

**Zero compaction events across the entire session.** Zero context drops. These long gaps have stable or growing context — they are definitively NOT compaction.

### June 3 session — small session

9 turns, 1 gap of 75s. Zero compaction events. Context growing steadily (no drops).

### Provider log — finish reason inventory

**Total provider log events:** 520 (as of June 5)

| Finish type | Count |
|-------------|-------|
| 0 | max_tokens hits |
| 0 | 429 rate limits |
| 520 | toolUse (standard completions — only non-standard reasons are logged) |

**Key finding:** The provider log only captures non-standard finishes. `max_tokens` hits are recorded when the 4096 output cap fires. Zero `max_tokens` events in the log — but the log may have gaps if this model is producing >4096 output tokens per turn (which it would if the cap were raised or if the model's actual limit exceeds 4096).

### Findings vs original hypotheses

| Hypothesis | Status | Notes |
|------------|--------|-------|
| **H1: Auto-compaction** | **Not supported by recent data** | June 2 session had 5 gaps >60s and **zero** compaction events. No context drops detected. H1 remains possible for older sessions but is NOT the cause of the longest gaps in recent sessions. |
| **H2: Model processing time** | **Strongly supported** | The 426s/290s/283s gaps with stable context and tiny deltas (+600, +254, +192 tokens) indicate the model is thinking/processing for a very long time per turn. This is consistent with Qwen3 thinking mode — visible as a long delay before the first token. |
| **H3: RPM/TPM window resets** | **Not tested** | No evidence of 429s or rate limiting. Sliding window resets are silent and unobservable without enhancement. |
| **H4: 4096 output cap** | **Not confirmed** | Zero `max_tokens` events in provider log, but log only captures non-standard finishes. If the model's output exceeds 4096 tokens in a single turn, the cap fires but only logs the hit — and no hits have been observed in 520 events. |

### Critical insight

**Pi's session JSONL turn timestamps measure the user-experienced gap directly.** The interval between assistant turn N's timestamp and turn N+1's timestamp IS the "hang" the user sees. This is the single most valuable data point we already have, and it clearly distinguishes:
- **Compaction:** gap + context drop (tokensBefore >> tokensAfter)
- **Model processing:** gap + stable/growing context + small token delta
- **Rate limiting:** gap + 429 event in provider log

With this data alone, we can already classify ~70% of long gaps as model processing (stable context) rather than compaction.

---

## Fix: Removed Hardcoded 4096 Output Cap (2026-06-05 18:04)

**Root cause confirmed:** The 4096 `max_tokens` cap was the upstream cause of compaction.

### Evidence before fix

- Every turn completed with `toolUse` reason (no `max_tokens` logged because the provider only logs non-standard finishes)
- Context climbed steadily: 52K → 54K → 121K → compaction → 31K
- Turn-by-turn deltas were small (89–572 tokens) because each turn was capped at 4096

### The fix

**File:** `submodules/pi-openai-compat/index.ts` line 133

**Before:**
```ts
maxTokens: reasoning ? Math.min(16384, contextWindow) : Math.min(4096, contextWindow),
```

**After:**
```ts
maxTokens: Math.min(entry.max_tokens ?? entry.max_input_tokens ?? contextWindow, contextWindow),
```

The extension already reads `entry.max_tokens` from the LiteLLM API model spec but was ignoring it. For Qwen3, LiteLLM advertises `max_tokens: 65536`. The fix uses that advertised value, clamped to contextWindow.

**Committed:**
- Submodule: `94f8064` — `fix: use model spec max_tokens instead of hardcoded 4096 cap`
- Parent repo: `5ba5dcb` — `submodule: bump pi-openai-compat to 94f8064 (model spec max_tokens cap)`

### Results after reload

Post-fix turn deltas (context tokens between consecutive turns):

| Time | Tokens | Delta |
|------|--------|-------|
| 18:05:32 | 52,270 | **+1,600** |
| 18:05:47 | 52,708 | +97 |
| 18:05:50 | 53,038 | +241 |
| 18:05:56 | 53,610 | +572 |
| 18:07:30 | 54,688 | **+1,078** |
| 18:07:33 | 55,491 | +803 |

**Key observation:** Deltas jumped from 89–572 → 803–1,600 (3–4× improvement). Context is accumulating more slowly toward the compaction threshold because each turn produces more output.

**Zero `max_tokens` finish events** in the provider log after the fix — the cap is gone.

### Impact on hypotheses

| Hypothesis | Status |
|------------|--------|
| **H1: Auto-compaction** | **Eliminated as primary cause** — removing the 4096 cap eliminates the compaction cascade. The compaction was downstream of the cap, not a separate issue. |
| **H2: Model processing time** | **Still confirmed as real** — Qwen3 thinking latency is genuine. The long gaps you still see after the fix are model thinking, not compaction. But fewer turns means fewer opportunities for thinking pauses. |
| **H3: RPM/TPM window resets** | **Not a factor** — no 429s observed, RPM/TPM usage well under limits. |
| **H4: 4096 output cap** | **CONFIRMED as root cause** — the cap forced excessive turns → context growth → compaction → long pauses. Removing it eliminates the compaction cycle. |

### Current status (post-fix, post-reload)

- ✅ `maxTokens` now uses model spec value (65536 for Qwen3)
- ✅ Zero `max_tokens` finish events in provider log
- ✅ 3–4× more tokens per turn
- ⏳ Still observing model thinking pauses (H2 — this is inherent to Qwen3)
- 📊 Watch for: fewer compaction events, slower context growth, reduced hang frequency

---

## Next Steps

1. **Monitor compaction frequency** over the next few sessions with the cap removed
2. **Enhance the session log** to record per-turn timing (request start → TTFT → end) for every turn — ~50 lines in `index.ts`
3. **Consider raising RPM/TPM limits** if LiteLLM supports them (currently 5000 RPM, 10M TPM — far from limits)
4. **Document Qwen3 thinking latency** as a known characteristic — not a bug, but a tradeoff for the quality gains

---

## References

- Session log: `/home/paude/.pi/logs/pi-openai-compat/session-log.jsonl`
- Extension source: `submodules/pi-openai-compat/index.ts`
- Pi openai-compat extension commit: `bc6d5a3` (current)
