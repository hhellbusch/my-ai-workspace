# System prompt layering

> Written: 2026-06-08
>
> Documents how Pi assembles the system prompt from multiple sources,
> the order in which extensions inject their blocks, and the total token
> budget at session start.

---

## Prompt assembly pipeline

Pi builds the system prompt in stages. Extensions can intercept and modify it via `before_agent_start`. Handlers run in **extension load order** (defined by `packages` array in `settings.json`), and each handler can append to the accumulated prompt.

```
[Base Pi system prompt]
  │  (~200 lines — tool descriptions, guidelines, session structure)
  ▼
[paude-l0.ts]           ← index 1 in settings.json packages
  │  (~130 lines)
  ▼
[zanshin.ts]            ← index 2 in settings.json packages
  │  (~16 lines L0 + kit paths)
  ▼
[User's prompt]
```

**Load order** is determined by the `packages` array in `~/.pi/agent/settings.json`:

| Index | Package | Extension | Injected at | Content |
|-------|---------|-----------|-------------|---------|
| 0 | `pi-openai-compat` | N/A | (no before_agent_start) | Model discovery, provider config |
| 1 | `paude-pi-extension` | `paude-l0.ts` | `before_agent_start` | Container awareness, paude-proxy, network, agent types, workspace customizations |
| 2 | `zanshin-pi-extension` | `zanshin.ts` | `before_agent_start` | Three failure modes, slash commands, auto-behaviors, collaboration line, kit paths |

**Total system prompt:** ~340–360 lines (~8–10 KB). The L0 blocks from zanshin and paude are injected at `before_agent_start` and are visible to the LLM on every turn.

---

## Extension responsibilities

### paude-l0.ts (paude-pi-extension)

Fires on `before_agent_start` when inside a Paude container. Injects:

- Container location and commit discipline
- Push capability (paude-proxy credentials at connect time)
- **paude-proxy credential broker** — how credentials flow, supported types, token vending
- **Network** — allowlist location, curl testing for 403s, git over HTTPS, token reconnection
- **Available agents** — Pi, OpenClaw, Hermes (comparison for task routing)
- **Workspace customizations** — dynamically generated skills/rules/prompts list
- Pi extension development workflow

**Size:** ~130 lines, ~4 KB. **Status:** functional but bloated — see trimming plan below.

### zanshin.ts (zanshin-pi-extension)

Fires on `before_agent_start`. Injects:

- Three failure modes (statelessness, compaction, fluent-but-wrong)
- Slash commands (`/spar`, `/shoshin`, `/checkpoint`, `/push`, `/pop`, `/stack`)
- Auto-behaviors (checkpoint after N writes, session start project detection, stack persistence)
- Collaboration line ("shorter over longer")
- Kit file paths (WORKING-STYLE.md, STYLE.md, etc.)

**Size:** ~16 lines, ~0.5 KB. **Status:** tight — good.

### Guard extensions (9 files)

Fire on `tool_call` (not `before_agent_start`). Zero system prompt cost. Each fires on `git commit` bash calls; only `secrets-guard` reliably triggers. Runtime cost is negligible.

---

## Optimization targets

The system prompt is ~340–360 lines. The zanshin L0 is already tight at ~16 lines. The paude L0 is the primary optimization target at ~130 lines.

### Current paude L0 structure

| Section | Lines | Status |
|---------|-------|--------|
| Container location + commit discipline | ~5 | **Keep** — essential context |
| Push capability | ~5 | **Keep** — clarifies push vs harvest |
| Credentials & paude-proxy | ~25 | **Trim** — credential types are config-time info, not turn-time |
| Network — paude-proxy | ~30 | **Trim** — troubleshooting only, already in `devops/paude-proxy/README.md` |
| Available agents | ~15 | **Keep** — useful for task routing |
| Workspace customizations | ~5 (dynamic) | **Keep** — contextually relevant |
| Don't escape + Pi extension dev | ~5 | **Trim** — dev workflow is niche; "don't escape" is covered by container context |
| YouTube curation research reference | ~2 | **Remove** — narrow/stale |

### Proposed trimmed paude L0

- **Keep** (~55 lines): container location, commit discipline, push capability, one-line paude-proxy intro, available agents, workspace customizations, don't escape
- **Move to on-demand references** (~75 lines saved): credential types → `devops/paude-proxy/README.md`, network troubleshooting → same, extension dev workflow → `docs/PI-EXT-DEV.md`, YouTube reference → remove from L0
- **Target total:** ~260 lines (~5–6 KB)

---

## On-demand references

Files loaded only when the task needs them (not in system prompt):

- `devops/paude-proxy/README.md` — full paude-proxy credential types, token vending, configuration
- `submodules/zanshin-pi-extension/docs/PI-EXT-DEV.md` — Pi extension development workflow
- `submodules/zanshin-pi-extension/kit/WORKING-STYLE.md` — full zanshin discipline (read on demand)
- `submodules/zanshin-pi-extension/kit/ENGINEERING-PRINCIPLES.md` — DRY, KISS, SRP, broken windows (read on demand)
- `.agents/skills/*/SKILL.md` — slash commands (loaded by skill resolver)

---

## Token budget

| Component | Lines | Approx tokens |
|-----------|-------|---------------|
| Base Pi prompt | ~200 | ~4,000 |
| paude L0 (current) | ~130 | ~3,000 |
| zanshin L0 | ~16 | ~400 |
| **Total** | **~346** | **~7,400** |

After trimming paude L0 to ~55 lines, total drops to ~260 lines (~5,200 tokens). ~30% reduction in L0-only payload, ~15% reduction in total system prompt.

---

## Related

- `.planning/ai-context-architecture/BRIEF.md` — where context lives (global vs project vs on-demand)
- `.planning/ai-context-architecture/ROADMAP.md` — evolution plan (Phase 3: zanshin L0 extension)
- `submodules/paude-pi-extension/extensions/paude-l0.ts` — source of paude L0 block
- `submodules/zanshin-pi-extension/extensions/zanshin.ts` — source of zanshin L0 block
