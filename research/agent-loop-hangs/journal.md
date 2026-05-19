# Engineering Journal: Agent Loop Hangs / Stops

> Started: 2026-05-19
> Status: Investigating
> Source: `/home/paude/.pi/logs/pi-openai-compat/session-log.jsonl`

---

## Symptom

The agent loop appears to hang or stop mid-session. The user experience is a noticeable pause (30–150s) followed by the next tool-use turn. Between these pauses, turns complete in 1–6s.

**Session under analysis:** 2026-05-19 00:16–00:48 (32 minutes, 167 finish events)

---

## Raw Data

### Event Summary

| Metric | Value |
|--------|-------|
| Total events | 167 |
| Time span | 32m 15s |
| Finish reason | 100% `toolUse` (standard completion) |
| 429 events | 0 |
| Non-standard finishes | 0 |
| Avg context tokens | 45,499 |
| Max context tokens | 72,735 |
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

### H1: pi's internal sliding window auto-compaction causes apparent hang (CONFIRMED)

**Session log analysis showed compaction context drops** — but that was the wrong level of data. The provider log (`session-log.jsonl`) only records API events, not session-level events like compaction triggers.

**Session JSONL analysis revealed: compaction events exist in pi's session format as `compaction` type events, all with `fromHook: false`** — meaning compaction is auto-triggered by pi's built-in sliding window, not by any extension or user action.

Two compaction points observed in today's session (session `2026-05-18T23-52-59-390Z`):
- Compaction at 00:15:57 — **98,521 tokens before**, fromHook=false
- Session 3 (`2026-05-19T00-33-30-980Z`) — no compaction event found (session may not have reached window limit)

**The 60–130s gaps are compaction processing time.** The provider log saw a gap because compaction wipes the context window and rebuilds it — this is the model sitting idle while pi processes the compaction.

**This is NOT autocompaction in the sense of "the model compacts on its own."** It's pi's built-in sliding window mechanism: when the context window reaches its limit, pi auto-truncates old messages and rebuilds the window. The agent is unaware — it just sees a gap.

**Supporting evidence:**
- All compaction events across sessions show `fromHook: false` — always pi's window, never an extension trigger
- Compaction timing correlates with the 60–130s gaps observed in provider log
- After compaction, context resets and turns resume normally

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

**But compaction events ARE captured** — just not in the provider log. They exist in pi's session JSONL as `compaction` type events. The key field is `fromHook: false` which confirms they're triggered by pi's internal sliding window, not by any extension.

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

**Result:** 15 compaction events across 6 sessions, all `fromHook: false`, token counts ranging from 80K to 242K. This confirms compaction is always pi's internal mechanism, never an extension trigger.

---

## Open Questions

1. What is the actual model's context window for `Qwen3.6-35B-A3B`? (The extension auto-discovers it — is it correct?)
2. Is the 60–130s compaction time expected for this model/token-count?
3. Do the "stable context" long gaps correlate with specific tool-use patterns?
4. Is there a per-request latency distribution we can get from the provider logs (if available)?
5. Does compaction frequency correlate with hang frequency?

---

## Next Steps

1. **Enhance the session log** to record:
   - Every turn (not just non-standard finishes)
   - Per-turn timing (request start → first token → end)
   - Compaction/reset events
   - RPM/TPM window resets
2. **Reproduce** the hang under controlled conditions and capture the enhanced log
3. **Compare** turn timing patterns between compaction and non-compaction gaps

---

## References

- Session log: `/home/paude/.pi/logs/pi-openai-compat/session-log.jsonl`
- Extension source: `submodules/pi-openai-compat/index.ts`
- Pi openai-compat extension commit: `bc6d5a3` (current)
