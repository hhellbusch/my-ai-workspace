# LiteMaaS / LiteLLM — Streaming Limitations with Thinking Models

**Status:** Active limitation as of 2026-05-13.
Tracked in [BACKLOG.md](../../BACKLOG.md) — search "RHOAI LiteLLM: enable `reasoning_content`".

---

## The limitation

Qwen3 models in thinking mode (`enable_thinking: true`) return their chain-of-thought inside `<think>...</think>` tags in non-streaming responses.
When streamed, LiteLLM strips the reasoning content entirely — the model visibly delays before its first token (it is reasoning), but the `reasoning_content` field never arrives.
The thinking panel in Pi never populates.

**Root cause:** LiteLLM cannot extract `<think>...</think>` tags mid-stream and discards them rather than buffering.
Newer LiteLLM versions (post ~1.67) support `stream_options: {"include_reasoning": true}`.
The pi-openai-compat extension already sends `thinkingFormat: "qwen-chat-template"` correctly — no extension changes are needed.
The fix is a LiteLLM upgrade on the RHOAI/LiteMaaS side.

**Workaround — paude-proxy relay:** Modify `paude-proxy` to intercept streaming requests when `enable_thinking` is set, issue the request non-streaming internally, then re-emit synthetic SSE chunks: first `delta.reasoning_content` chunks, then regular `delta.content`, then `[DONE]`.
Pi's stream parser handles this without changes.
See BACKLOG.md "paude-proxy thinking relay" for implementation detail.

---

## Meta-system implication

This limitation affects more than the thinking panel.
When the model's internal reasoning is invisible, the ability to diagnose behavioral failures degrades.

A concrete example: during a 2026-05-13 session, a Qwen3.6 model via LiteMaaS got into a self-correction loop — adding a TOC, removing it, re-adding it — without any user input triggering the reversals.
The session log showed only the outputs (the edits), not the reasoning.
With reasoning visible, the loop might have been legible earlier: "model is second-guessing a formatting decision with no authority to anchor to."
Without it, the failure looked like noise until it had already compounded.

**The broader principle:** Reasoning visibility is not just a UX feature — it is observability for the meta-system.
When you are trying to understand why a model behaved a certain way and improve the working discipline in response, the chain-of-thought is evidence.
Losing it means diagnosing from outputs alone, which is harder and less reliable.

This is distinct from the model being wrong.
A model that reasons visibly and reaches a bad conclusion is debuggable.
A model that reasons silently and produces bad output gives you less to work with.

---

## References

- BACKLOG.md: "RHOAI LiteLLM: enable `reasoning_content` in streaming for Qwen3" — technical detail, action item
- BACKLOG.md: "paude-proxy thinking relay — surface Qwen3 reasoning in Pi UI" — workaround design
- `submodules/pi-openai-compat/index.ts` — `thinkingFormat: "qwen-chat-template"` (already correct)
- `git-projects/pi-mono/packages/ai/src/providers/openai-completions.ts` lines 258–299 — stream parser that handles `reasoning_content`
