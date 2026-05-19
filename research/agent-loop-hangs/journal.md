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

### H1: Context compaction causes apparent hang (most likely)

Two context drops observed:
- 60,855 → 6,355 (−54K tokens, 66s gap)
- 66,913 → 6,319 (−60K tokens, 130s gap)

The model reached ~67K tokens (near the Qwen 3.6 35B model's window), the agent loop initiated compaction, and the 60–130s gap is compaction processing time, not a hang. The compaction itself is invisible in the session log — the log only records standard finish events and 429s.

**Supporting evidence:**
- Both largest gaps correlate with large context drops
- After each compaction, context resets to ~6K and rebuilds
- The 10th longest gap (146s) shows context almost unchanged (+206 tokens) — suggesting model processing time, not compaction

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

The current logging in `pi-openai-compat` only records:
1. **Non-standard finish reasons** (line 470: `end_turn`/`stop`/`stop_sequence` excluded)
2. **429 events** (line 444)

It does **not** record:
- Standard completions (`end_turn`, `stop`, `stop_sequence`)
- Context compaction events
- RPM/TPM window resets
- TTFT (time-to-first-token) measurements in the log file
- Request start timestamps
- Provider response latency (only TTFT in UI status)

**This is a blind spot.** The log captures the rare, not the routine. To diagnose the normal case (why some turns take 90–150s), we need to log every turn with timing.

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
