# Pi + Paude architecture decisions (2026-05-10)

## Decisions made

1. **Container-first workflow for current usage**
   - Primary mode is interactive work inside the paude container (`paude connect`), not harvest-first orchestration.

2. **Drop automatic `paude-pi-extension` loading**
   - Paude no longer auto-installs `paude-pi-extension` for every Pi session.
   - Extension use is now explicit and opt-in via `--pi-extension`.

3. **Keep base image minimal by default**
   - Zanshin and LID remain intentionally excluded from the base image.
   - Team members can choose and compose their own extension stack.

4. **Update to current Pi package namespace**
   - Migrate references from `@mariozechner/*` to `@earendil-works/*` in paude + extension repos.

5. **Credential handling target**
   - Continue proxy-only handling for API keys where possible.
   - Vertex sessions now follow paude's original security model: ADC credentials are injected in-container for Vertex auth, with proxy-filtered network boundaries.
   - Keep relay-mode exploration optional and non-default.

## Why these decisions

- The previous paude extension L0 focused on harvest semantics and was misaligned with current interactive usage.
- Auto-injecting an extension into every Pi session created unnecessary coupling and made prompt behavior harder to reason about.
- Minimal base images preserve reuse across peers and avoid imposing one workflow policy globally.
- The package namespace moved upstream; pinning to older package names increases drift risk.

## Open concern

You want the proxy to mediate LLM calls as well (not just egress filtering + API-key handling).

Current state:
- **OpenAI-compatible/API-key providers** can stay proxy-centered.
- **Vertex provider path** defaults to direct in-container ADC handling (aligned with upstream paude security model).
- **Optional pattern slice (experimental):** `PAUDE_VERTEX_AUTH_MODE=proxy` can still be explored as a strict relay variant when needed.

Implication:
- "Proxy as LLM intermediary for all providers" is a separate architecture change, not a docs-only or extension-only tweak.

## If we pick this back up later: concrete next steps

1. **Design note:** define a provider relay model for Vertex traffic (request/response path, auth handoff, streaming behavior, failure handling).
2. **Proxy token lifecycle:** handle token refresh/rotation for long-running sessions without requiring proxy restarts.
3. **Security model update:** document trust boundary changes when proxy becomes an active LLM relay.
4. **Observability:** instrument token/accounting and failure telemetry on both relay and direct paths.
5. **Rollout decision:** keep both modes (direct vs relay) or standardize on one after measured comparison.

## Prompt injection hygiene checkpoints (for future reviews)

- Keep always-on injections short, stable, and behavioral.
- Push domain detail to on-demand files (`.pi/SYSTEM.md`, kit docs).
- Avoid overlapping guidance across multiple extensions.
- Periodically inspect final prompt composition and compaction outcomes after extension changes.
