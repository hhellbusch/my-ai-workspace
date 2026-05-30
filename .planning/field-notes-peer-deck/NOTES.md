# Field Notes peer deck — capture notes

> Written: 2026-05-29
> Deck: `presentations/field-notes-for-peers.md`
> Purpose: Ideas from peer-deck conversation to pick up later — ecosystem map, OpenClaw, clanker conjunction.

---

## Slide deck status

**Audience (pass 8, 2026-05-29):** **Master learning path** — cohesive build-up over elevator pitch. Restores PKM ecosystem, Simon Scrapes, the shift, discipline essays, portable toolkit, brain+clanker to main flow.

**Done:**
- Pass 5: mixed generalists
- Pass 6 (overflow): agent table → lines; first session split; one idea table → bullets; repo code block → bullets; reading maps tables → bullets; trimmed multi-session, start minimal, disclaimers; detail → speaker notes
- Pass 7: reading map as in-deck appendix (path + one-line *why read*); close-out slide replaces Q&A
- Pass 8: five-act master learning restructure — concepts build in order; trimmed ideas restored (shift, memory taxonomy, PKM map, spar/shoshin/zanshin, portable toolkit, OpenClaw)
- Pass 9: shoshin/spar review applied — shift qualification, Act IV reorder, compaction habit, honest L3–6 ceiling, spar bracket timing, draft/exploratory caveats, frictionless-entity link
- Pass 10: `presentations/SLIDE-RULES.md` + `.cursor/rules/presentations.mdc`; deck split for one-slide budget
- Pass 11: sycophancy/no pleasantries, culture amplification, harness interface bleed (Copilot/VS Code observation in speaker notes)
- Pass 12: agentic loop slides (Krentsel matryoshka); overflow splits per SLIDE-RULES
- Pass 13: harness building blocks + Agent Skills slides; AGENTS.md in repo map; appendix workflow entries updated
- Pass 14: harness ≥ model thesis; prompt/context/harness table; AI Engineer appendix slides
- Pass 15: Tejas Kumar harness talk ingested → `library/tejas-kumar-harnesses-in-ai.md`; deck appendix updated

**Corpus for harness/skills (no single essay):** `AGENTS.md`, `framework-bootstrap.md`, `ai-assisted-development-workflows.md` § Solution A, `.planning/ai-context-architecture/BRIEF.md`, OpenClaw library entry (skills vs tools)

---

## Harness talks — already in `library/` (AI Engineer channel)

| Entry | URL | Hook for deck |
|---|---|---|
| `ryan-lopopolo-harness-engineering.md` | https://www.youtube.com/watch?v=am_oeAoUhew | **AI Engineer London 2026.** "The harness is the job." Code as disposable build artifact; every "continue" is harness failure. OpenAI Codex team. |
| `dex-horthy-no-vibes-allowed.md` | https://www.youtube.com/watch?v=rmvDxxNubIg | **AI Engineer London 2026.** Context engineering; dumb zone; research → plan → implement. Prior talk: "12 Factor Agents" (2025). |
| `alberta-tech-why-devs-obsessed-claude-code.md` | https://www.youtube.com/watch?v=LACyqdAfnaw | Same Opus model: Claude Code ~#40 vs other harnesses ~#1 on Terminal Bench — empirical harness multiplier. |
| `andrej-karpathy-vibe-coding-to-agentic-engineering.md` | https://www.youtube.com/watch?v=96jN2OCOfLs | Software 3.0 — context window as the lever; agentic engineering framing (Sequoia, not AI Engineer). |
| `alex-krentsel-openclaw-deep-dive.md` | https://www.youtube.com/watch?v=sxX8BMscce0 | All systems = LLM calls; harness bundles context; matryoshka loopiness. |
| `tejas-kumar-harnesses-in-ai.md` | https://www.youtube.com/watch?v=C_GG5g38vLU | **AI Engineer.** Harness anatomy (tools, guardrails, verify); GPT-3.5 demo without prompt changes. |

**Worth ingesting next (optional):**

| Talk | URL | Why |
|---|---|---|
| Cole / others — *What Harness Engineering Actually Means* | https://www.youtube.com/watch?v=zYerCzIexCg | Clear prompt vs context vs harness vocabulary (verify channel — may not be official AI Engineer). |

**Stack vocabulary (useful on slides):** prompt engineering → context engineering → harness engineering (context lives *inside* harness).

**Slide rules (canonical):** [presentations/SLIDE-RULES.md](../../presentations/SLIDE-RULES.md)

**Next iteration candidates:**
- [ ] Re-export PDF — verify pass 10 splits cleared overflow
- [ ] Author `voice-approved` pass on title slide
- [ ] Optional: live-demo slide (bounded Path B ingest)

---

## Ecosystem map (for deck + future doc)

Field Notes sits at the intersection of three conversations usually kept separate:

| Conversation | Examples | Field Notes analogue |
|---|---|---|
| **PKM / second brain** | Forte PARA, Zettelkasten, digital garden | `research/` → `library/` → `docs/` / `devops/` |
| **LLM knowledge base** | Karpathy LLM Wiki, Recall | `library/` + ingest schema (`/reference`, cross-link rules) |
| **Agent memory / harness** | Simon Scrapes levels, memsearch, MemPalace, OpenBrain | Rules, skills, backlog, handoffs — manual Level 1–2 |

**Key distinction (Simon Scrapes):** Levels 1–4 = *operational memory* (what did we decide). Levels 5–6 = *knowledge accumulation* (what did I read, how ideas connect). Field Notes is strong on 5 + harness; weak on automated 3–4 unless added.

**Karpathy three-layer map** (see `library/karpathy-llm-wiki.md`):

| LLM Wiki | Field Notes |
|---|---|
| `raw-sources/` | `research/*/sources/` |
| `wiki/` | `library/` |
| `schema/` | `AGENTS.md`, ingest checklist, `/audit` |

**Zettelkasten** (Sascha / zettelkasten.de): atomic notes + structure notes + central "machine" note — *articulate before automate*. Field Notes is synthesis-grain (essays, case studies), not atomic Zettelkasten. Optional future layer: short atomic notes with IDs if needed.

**Database question:** Don't replace markdown with SQL. Add vector/graph/Postgres when *find-it-again* or *multi-agent shared recall* hurts more than curation — OpenClaw uses markdown config + vector memory for search; complementary.

---

## OpenClaw (recorded 2026-05-29)

**Library entry:** `library/alex-krentsel-openclaw-deep-dive.md`
**Transcript:** `research/openclaw/sources/openclaw-video-sxX8BMscce0.md`
**Video:** https://www.youtube.com/watch?v=sxX8BMscce0 (Alex Krentsel — architecture deep dive)

**Naming history:** Clawd / Clawdbot → Moltbot → [OpenClaw](https://github.com/openclaw/openclaw)

**Architecture (three layers):**
1. Connectors — Telegram, Discord, WhatsApp, …
2. Gateway — sessions, cron, heartbeat, memory
3. Agent runtime — LLM, shell, Agent Skills

**Distinctive vs Field Notes:** proactivity (cron + heartbeat), always-on channels, optional vector memory (agent-initiated search, not bulk inject).

**Workspace links already in corpus:** Simon Scrapes Level 3 OpenClaw-style; Miessler DA thesis (proactivity); Paude `--agent openclaw`; Red Hat BYOA blog (`research/openshift-ai-llm-deployment/sources/ref-50.md`).

---

## Brain + clanker conjunction

**Frame for peers:** Field Notes = brain you own in git. Clanker (OpenClaw-class runtime) = hands + alarm clock.

```
Field Notes (git)          Clanker runtime (OpenClaw / Paude+Pi)
─────────────────          ───────────────────────────────────
library/, devops/, docs/    cron, heartbeat, Telegram/Discord
rules, skills, BACKLOG      shell, browser, execution
human review, /audit        vector session memory (optional)
         │                            │
         └──── workspace mounted ─────┘
```

**Promotion rule:** durable learning → commit to `library/` or `BACKLOG`, not only vector memory.

**Safety:** containerize clanker (Paude pattern, Docker OpenClaw guides) — don't give unconstrained host access.

**Minimum experiment (when ready):**
1. Scoped clone/worktree the repo for the agent
2. Existing `.agents/skills/` (same Agent Skills standard as OpenClaw)
3. One cron: weekly backlog staleness → message on a channel
4. Ingest pipeline: URL → transcript in `research/` → human or Cursor enriches `library/`

---

## Related library entries (starting points)

- `library/simon-scrapes-claude-code-memory-systems.md` — memory taxonomy
- `library/karpathy-llm-wiki.md` — synthesis layer
- `library/mempalace.md` — verbatim vs wiki
- `library/alex-krentsel-openclaw-deep-dive.md` — OpenClaw architecture
- `library/daniel-miessler-single-da-thesis.md` — proactivity / OpenClaw mention
- `docs/ai-engineering/portable-ai-toolkit.md` — Paude + Pi + Zanshin

---

## Future doc ideas (not scheduled)

- Short `docs/` or `presentations/` appendix: "Field Notes in the PKM landscape"
- Compare slide: Field Notes vs Recall vs OpenClaw vs MemPalace (four columns, one row each)
- Cross-link deck to `library/` entries in speaker notes only (keep slides clean)
