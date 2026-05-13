# ADC → Proxy Migration: Scope & Plan

**Date:** 2026-05-13  
**Status:** Scoping — no implementation yet  
**Trigger:** bbrowning/paude#201 — upstream paude 0.20.0a3+ no longer injects real ADC into agent containers; paude-proxy handles all Google credential exchange.

---

## Background

### What changed upstream

Upstream paude (≥0.20.0a3) implements the TokenVendor + GCloudInjector pattern in paude-proxy. The agent container gets a **stub ADC file** with dummy values instead of a real credential:

```json
{"type": "authorized_user", "client_id": "paude-proxy-managed",
 "client_secret": "paude-proxy-managed", "refresh_token": "paude-proxy-managed"}
```

Token flow:
1. Agent's Google Auth library reads the stub ADC, POSTs to `oauth2.googleapis.com/token`
2. Proxy's **TokenVendor** intercepts and returns dummy token `"paude-proxy-managed"`
3. Agent calls `*.googleapis.com` with dummy Bearer token
4. Proxy's **GCloudInjector** replaces it with a real OAuth2 token (from the proxy's own ADC)
5. Real credential never touches the agent container

The proxy receives the real ADC via `GOOGLE_APPLICATION_CREDENTIALS` env var (or `GCP_ADC_JSON` content) at session creation time. The agent container has no real credential.

### Current state of this fork

This workspace runs a fork of paude. Current session state:

- `PAUDE_VERTEX_AUTH_MODE=direct` — real ADC in agent container (old path)
- Real `authorized_user` ADC file at `~/.config/gcloud/application_default_credentials.json`
- `GOOGLE_CLOUD_PROJECT=itpc-gcp-global-revenue-claude` (still needed — not a credential)
- `ANTHROPIC_VERTEX_PROJECT_ID=itpc-gcp-global-revenue-claude` (still needed)
- `GOOGLE_CLOUD_LOCATION=global` → resolves to `global-aiplatform.googleapis.com`

The fork added a `PAUDE_VERTEX_AUTH_MODE` toggle (`direct` | `proxy`) specifically because the upstream proxy approach wasn't working at the time. The upstream has since shipped the fix (bbrowning confirmed 0.20.0a3 has it). The custom toggle is now obsolete.

### Custom Pi work at stake

Two custom extensions are relevant:

**`pi-anthropic-vertex`** (`submodules/pi-anthropic-vertex/`)  
Uses `@anthropic-ai/vertex-sdk` → standard Google ADC flow. When the stub ADC is present, the SDK will try to exchange the dummy refresh_token at `oauth2.googleapis.com/token`. The TokenVendor intercepts this and returns a dummy access token. Subsequent calls to `global-aiplatform.googleapis.com` get the real token injected by GCloudInjector. **This should work without code changes** — this is exactly what the upstream pattern is designed to handle.

**`pi-openai-compat`** (`submodules/pi-openai-compat/`)  
No Google auth involved. Uses `OPENAI_COMPAT_BASE_URL` + `OPENAI_COMPAT_API_KEY`. Already handled by the proxy's bearer injector. **No changes needed.**

**`paude-pi-extension`** (`submodules/paude-pi-extension/`)  
Injects system prompt context (container awareness, allowlist, workspace customizations). No credential handling. **No changes needed.**

---

## What needs to change

### 1. Paude fork — drop `PAUDE_VERTEX_AUTH_MODE`

The `direct` mode and the supporting machinery in the fork exist solely because the upstream proxy couldn't handle ADC at the time. Now it can. Remove:

- `VERTEX_AUTH_MODE_ENV`, `VERTEX_AUTH_MODE_DIRECT`, `VERTEX_AUTH_MODE_PROXY` constants from `shared.py`
- `_resolve_vertex_auth_mode()` function from `shared.py`
- `gather_proxy_credentials()` code paths that branch on `VERTEX_AUTH_MODE_PROXY` (the `_mint_vertex_bearer_token` call, `PAUDE_VERTEX_BEARER_TOKEN` passing)
- `build_session_env()` block that sets `VERTEX_AUTH_MODE_ENV` in agent container env
- `_mint_vertex_bearer_token()` and `_mint_gcp_access_token_from_adc()` functions (no longer needed)
- Constants `PROXY_VERTEX_BEARER_ENV`, `PROXY_VERTEX_PROJECT_ENV`, `PROXY_VERTEX_REGION_ENV` from `shared.py`
- Any proxy entrypoint handling of `PAUDE_VERTEX_AUTH_MODE=proxy` / `PAUDE_VERTEX_BEARER_TOKEN` in `containers/proxy/entrypoint.sh`

What remains for Vertex in `gather_proxy_credentials()`: pass `GCP_ADC_JSON` (real ADC content) to the proxy container, and pass `GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_LOCATION` as non-secret env vars to the agent container. Those are config, not credentials.

### 2. Paude fork — verify stub ADC is provisioned

The OpenShift backend already injects `STUB_ADC_JSON` via ConfigMap (`resources.py` line `"gcloud-adc": STUB_ADC_JSON`). Verify:
- The stub is written to the correct path (`~/.config/gcloud/application_default_credentials.json`) in the agent container
- `GOOGLE_APPLICATION_CREDENTIALS` is set in the agent container pointing to the stub path (or the default XDG location is used)
- The real ADC path/content is passed to the **proxy** container via `GOOGLE_APPLICATION_CREDENTIALS` or `GCP_ADC_JSON`

### 3. Paude fork — verify allowlist includes Google OAuth endpoint

For the TokenVendor to intercept the token exchange, `oauth2.googleapis.com` must be reachable through the proxy. Check that it is in the session's `ALLOWED_DOMAINS`. The proxy entrypoint routes all `*.googleapis.com` through the GCloudInjector, but `oauth2.googleapis.com` specifically handles the stub ADC exchange. It may already be included; confirm.

### 4. `pi-anthropic-vertex` — no code changes expected

The extension's credential flow is fully compatible with the stub ADC + proxy pattern. The `resolveProject()` function already handles the case where `gcloud` CLI is unavailable (falls back to env vars). Project env vars (`GOOGLE_CLOUD_PROJECT`, `ANTHROPIC_VERTEX_PROJECT_ID`) continue to be set in the agent container as non-secret config — that's correct.

One thing to confirm at implementation time: the `apiKey` shell expansion in `registerAnthropicVertex`:

```typescript
apiKey: "!sh -lc 'printf %s \"${ANTHROPIC_VERTEX_PROJECT_ID:-${GOOGLE_CLOUD_PROJECT:-...}}\"'"
```

This is the project ID, not a credential — it should still resolve from env vars in the agent container. No change needed.

### 5. Paude fork — bump submodule to upstream 0.20.0a3+

The fork should be rebased/merged against upstream to pick up the proxy-managed credential changes that are already implemented there. Review upstream diff carefully — the fork has custom Pi agent support (`pi.py`, the `PAUDE_PI_EXTENSIONS` env var, `pi-anthropic-vertex` installation in Dockerfile) that does not exist upstream and must be preserved.

---

## What does NOT need to change

- `pi-openai-compat` — no Google auth, already proxy-managed
- `paude-pi-extension` — no credential handling
- `zanshin-pi-extension`, `lid-pi-extension` — no credential handling
- `GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_LOCATION` / `ANTHROPIC_VERTEX_PROJECT_ID` env vars in the agent container — these are project config, not credentials, and stay in the agent
- The `pi-anthropic-vertex` model list, streaming logic, region resolution — unaffected

---

## Risk: `global` region and GCloudInjector domain matching

Current session: `GOOGLE_CLOUD_LOCATION=global`, which means the Vertex endpoint is `global-aiplatform.googleapis.com`.

The proxy's `credentials.json` routes `gcloud` injector to `.googleapis.com` (suffix match). This covers `global-aiplatform.googleapis.com`. Confirm that the domain allowlist also includes this host — it may currently be set to `{region}-aiplatform.googleapis.com` with a specific region (e.g., `us-east5`).

---

## Sequencing

This is purely scoping for now. When implementation begins:

1. Set up test session against upstream 0.20.0a3+ to confirm TokenVendor + GCloudInjector works with `pi-anthropic-vertex` as-is (before any code changes) — de-risks the assumption that no extension changes are needed
2. Remove `PAUDE_VERTEX_AUTH_MODE` machinery from the paude fork
3. Rebase fork against upstream, preserving Pi-specific additions
4. Test end-to-end with the cleaned-up fork
5. Document any allowlist changes needed for `oauth2.googleapis.com` and `global-aiplatform.googleapis.com`

---

## References

- Issue: bbrowning/paude#201 — RFE: isolating Google ADC
- Upstream docs: bbrowning/paude-proxy README § "gcloud ADC (Vertex AI / Gemini)"
- Upstream integration guide: bbrowning/paude-proxy `docs/PAUDE_INTEGRATION.md`
- Upstream version with fix: paude 0.20.0a3+
- Fork files affected: `src/paude/backends/shared.py`, `containers/proxy/entrypoint.sh`, `src/paude/agents/pi.py` (comment cleanup)
- Extension not affected: `pi-anthropic-vertex/index.ts`, `pi-openai-compat/index.ts`, `paude-pi-extension/`
