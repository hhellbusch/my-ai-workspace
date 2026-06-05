# Releases

> Day-based release tags for the workspace. Each tag points to the last commit of an active session. Use `git diff <tag>..<next-tag>` to analyze what changed.

## Quick Reference

```bash
# Compare two releases
git diff v2026-04-20..v2026-04-21 --stat

# List files changed in a release
git diff v2026-04-20..v2026-04-21 --name-status

# Full narrative
git log v2026-04-20..v2026-04-21 --oneline --author-date-order
```

## Summary

| Tag | Date | Commits | New Files | Theme |
|---|---|---|---|---|
| v2026-04-20 | 2026-04-20 | 69 | 674 | Field Notes branding, identity, local LLM benchmarks, essay writing |
| [v2026-04-21](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-20...v2026-04-21) | 2026-04-21 | 75 | 67 | Zanshin kit created, session brief, framework naming and solidification |
| [v2026-04-29](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-21...v2026-04-29) | 2026-04-29 | 31 | 64 | Helm component pattern, learning path, ArgoCD work (48d716c) |
| [v2026-04-30](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-29...v2026-04-30) | 2026-04-30 | 36 | 68 | Paude phases, worktrees, LID research, audit script |
| [v2026-05-02](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-30...v2026-05-02) | 2026-05-02 | 6 | 26 | Cursor → Pi migration, zanshin structured edits |
| [v2026-05-03](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-02...v2026-05-03) | 2026-05-03 | 37 | 381 | **Major reorg:** skills migration, submodule consolidation, kit extraction |
| [v2026-05-05](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-03...v2026-05-05) | 2026-05-05 | 12 | 270 | AgentSkills migration, skill implementations |
| [v2026-05-08](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-05...v2026-05-08) | 2026-05-08 | 8 | 8 | Session logging, push-all.sh, submodule URL standardization |
| [v2026-05-12](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-08...v2026-05-12) | 2026-05-12 | 36 | 121 | Architecture docs, paude-proxy, submodule sync, AGENTS.md distillation |
| [v2026-05-13](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-12...v2026-05-13) | 2026-05-13 | 77 | 212 | **commit-guard deep dive**, zanshin extension, rules/ migration |
| [v2026-05-18](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-13...v2026-05-18) | 2026-05-18 | 32 | 26 | vGPU docs/research dump, commit-guard fixes |
| [v2026-05-19](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-18...v2026-05-19) | 2026-05-19 | 5 | 1 | commit-guard loop-break |

## Releases

### [v2026-05-19](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-18...v2026-05-19)

> **Commit:** `0d01c5b` · 5 commits · 1 file

**Summary:** Commit-guard loop-break — the guard auto-passes when the same diff is blocked twice in a row. Prevents infinite re-review loops.

**Key changes:**
- `zanshin-pi-extension`: commit-guard auto-pass on second block of same diff

---

### [v2026-05-18](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-13...v2026-05-18)

> **Commit:** `4413db7` · 32 commits · 26 files

**Summary:** Two parallel tracks — vGPU docs/research dump and commit-guard iteration.

**vGPU (8 files):**
- A40 vGPU profile runbook
- ESO licensing, NFD auto-label, group defaults
- IOMMU MachineConfig YAMLs (Intel + AMD)
- vGPU pre-sync drain check hook
- vGPU template support for Helm-component pattern
- GPU/GitOps workflow assessment

**Infrastructure (submodule bumps):**
- `pi-openai-compat`: path fix, session log, context color thresholds, context % warning, DRY/SRP refactor
- `zanshin-pi-extension`: commit-guard embeds diff in block reason, skip on empty staging area, expanded guard + deletion fix

**Other:**
- `feat(meta): organic project brief creation` — project BRIEF.md scaffold from session

---

### [v2026-05-13](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-12...v2026-05-13)

> **Commit:** `2c72fc9` · 77 commits · 212 files · **Largest session**

**Summary:** The commit-guard deep dive. Extension quality work across zanshin, pi-openai-compat, and paude. Rules directory migration.

**commit-guard (extensive):**
- Embeds diff in block reason (multiple iterations)
- Gate 2 becomes agent-self-service
- Process-kill-guard (pkill/killall safety)
- Relative-link-guard improvements (fence tracking, source skip)
- URL-commit-guard enhancements
- Write-quality-guard added
- Unit tests (22 tests, all passing)
- Loop-break: auto-pass on repeated same diff
- Git add + git commit compound command blocking
- Project-scoped checkpoints via `resolveCheckpointDir`

**Extension quality:**
- `zanshin-pi-extension`: npm test (tsc + jiti validation), guard discovery docs, stale cache fix, guard-ui moved to lib/
- `paude-pi-extension`: pi-extension-guard, tsc check, allowlist discovery
- `pi-openai-compat`: context tracking, TTFT indicator, quota status bar

**Rules migration:**
- `.cursor/rules/` → `rules/` directory
- `.cursor/` → `.agents/skills/` canonical form
- Cross-references updated across workspace

**Docs:**
- GPU guide expanded (vGPU/passthrough from peer review)
- `paude tooling layer model` + workspace paude.json
- Argo: GPU stack for helm-component-pattern + MIG version
- OpenShift GPU bare-metal guide
- Portable AI toolkit catalog in README

**Cleanup:**
- `.claude/` vendor config removed
- `.cursor/` removed (duplicates `.agents/`)
- `CLAUDE.md` → `AGENTS.md`

---

### [v2026-05-12](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-08...v2026-05-12)

> **Commit:** `ee97960` · 36 commits · 121 files

**Summary:** Architecture documentation, paude-proxy integration, submodule synchronization, AGENTS.md distillation.

**Architecture docs:**
- "Portable AI toolkit" — Paude + Pi + Zanshin architecture overview
- `paude-proxy` configuration and PAT reference
- Git learning guide for developers
- Paude integration docs and submodule pins

**Submodule sync:**
- paude → develop branch, `--no-pi-extensions` flag
- paude-pi-extension → allowlist discovery, git authorship
- zanshin-pi-extension → fork workflow, integration discipline
- pi-anthropic-vertex → model list updates

**AGENTS.md:** Distilled from 248 → 123 lines, removed vendor-specific references

**Backlog:**
- RHOAI LiteLLM streaming `reasoning_content` limitation
- paude-proxy thinking relay concept

**Cleanup:**
- Removed `argo-diff-preview` submodule
- Pruned unused zanshin-kit skills from workspace

---

### [v2026-05-08](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-05...v2026-05-08)

> **Commit:** `c00dbeb` · 8 commits · 8 files

**Summary:** Session logging, safe submodule push, URL standardization.

**New features:**
- Session logging system — zanshin extension patch + `workspace/sessions/` directory
- `push-all.sh` — safe submodule push with branch inference
- Extension source location in `submodules/` + patch apply instructions

**Standardization:**
- Submodule URLs: SSH → HTTPS (PAT auth compatibility)
- Removed `AGENT-NOTES` directive from paude L0 extension source

---

### [v2026-05-05](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-03...v2026-05-05)

> **Commit:** `3e8bb45` · 12 commits · 270 files

**Summary:** AgentSkills migration — skills reorganized by tool ownership, `.cursor/skills/` removed.

**Migration:**
- Renamed `.cursor/rules/` `.md` → `.mdc`
- Renamed `heal-skill` → `improve-skill`
- Skills reorganized: `tools/cursor/skills/`, `tools/pi/skills/`, `tools/claude-code/skills/`
- `.cursor/skills/` removed entirely (canonical = `.agents/skills/`)
- Submodule pointer bumps for `zanshin-pi-extension` (Copilot `plugin.json`)

**Cleanup:**
- Deleted `.cursorrules` (silently ignored in Agent mode)
- Pruned 6 low-value/stale skills
- Replaced thin skill wrappers with real implementations

---

### [v2026-05-03](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-05-02...v2026-05-03)

> **Commit:** `d49fcaa` · 37 commits · 381 files · **Major reorg**

**Summary:** The big restructuring. Skills migration to AgentSkills, submodule consolidation, kit extraction, YouTube transcript skill.

**Kit extraction:**
- `zanshin-kit/` → `zanshin-pi-extension` submodule
- Submodules consolidated under `submodules/` directory
- `lid-pi-extension` converted to submodule

**Skills:**
- `youtube-transcript-library` SKILL.md authored
- YouTube transcript ingestion skill (Level 1)
- Removed `iphone-apps` and `macos-apps` expertise (unused)
- Flatten `consider/` and `research/` with prefixed names

**Pi workspace:**
- `.pi/` config replaces copied dirs with symlinks to `.cursor/` source of truth
- `SYSTEM.md` token-conscious alignment
- `AGENT-NOTES` added for youtube-skill fix
- `LOCAL-LLM-EXPERIMENT-JOURNAL.md` update (FP8 MoE)

**Docs:**
- Local LLM setup guide
- Pi bootstrap guide (framework-bootstrap, paude guide)
- `pi-resource-wiring` reference
- Paude getting-started update
- `SYSTEM.md` update
- README update

---

### [v2026-05-02](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-30...v2026-05-02)

> **Commit:** `c8712cd` · 6 commits · 26 files

**Summary:** Cursor → Pi migration groundwork, zanshin structured edits.

**New features:**
- Zanshin structured edit discipline rule + Python PostToolUse hook
- Migrate Cursor configuration to Pi-native format
- Add markdownlint config
- Semantic line breaks convention

**Devops:**
- Learning path git curriculum update
- Fix broken Microsoft Learn URL

---

### [v2026-04-30](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-29...v2026-04-30)

> **Commit:** `46da469` · 36 commits · 68 files

**Summary:** Paude development progression, worktrees, LID research, audit infrastructure.

**Paude:**
- Phase 1 mechanics complete — smoke test passed
- Phase 2 — lab READMEs + AGENT-NOTES + roadmap update
- Orchestration demo (workspace-snapshot task)
- Task spec for observability platform metrics guide

**Worktrees:**
- Git worktrees convention + memory systems library entry
- Update convention: worktrees inside repo, paude create syntax

**LID research:**
- Cohesion question explicitly logged
- Research angles: Paude brief format, bidirectional differential, enterprise adoption

**Audit:**
- Audit script + engineering discipline principle
- Library: close remaining stubs, wire audit into /audit
- Weekly cadence check, zanshin-kit rule registration

**Framework:**
- Universal blind-spots step added to pre-commit gate
- Shoshin: document-level frame check + honest ceiling

**Backlog:**
- Paude three-stage progression
- LID research with enterprise-validated SDD methodology
- Paude multi-agent first-class

---

### [v2026-04-29](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-21...v2026-04-29)

> **Commit:** `48d716c` · 31 commits · 64 files

**Summary:** Helm component pattern — the full architecture. Learning path expansion.

**Helm component pattern (ArgoCD):**
- Full reference implementation with `hub/`, `rendered/` directories
- Global-root multi-hub chart, `clusters.yaml` inventory
- Hub bootstrap chart + GitHub Action for rendered application generation
- Component registry, global defaults, AppProjects
- Operator + instance split, operators-installer integration
- Per-cluster targetRevision resolution (hub → group → cluster)
- Opinions section with rationale and costs
- Comparison with `gitops-standards-repo-template`
- Applications-only bootstrap vs ApplicationSet

**Learning path:**
- VMware admins v1.8 — ACM/ZTP expansion
- DevConf.US 2024 talk
- Phase 6 upgrade strategy — bare metal constraints, TALM canary
- Networking, storage, security, observability, backup/DR, GitOps repo structure

**Other:**
- RHACM troubleshooting: missing observability addon

---

### [v2026-04-21](https://github.com/hhellbusch/my-ai-workspace/compare/v2026-04-20...v2026-04-21)

> **Commit:** `69663c7` · 75 commits · 67 files

**Summary:** Zanshin kit creation and solidification. The framework gets its name, its rules, and its first portability.

**Zanshin kit created** (`a2bfd3d`):
- Portable working style for foreign environments
- Collaboration style section (brevity, cut before adding)
- Reference-from-clone as preferred workflow
- Team repo guidance (docs/planning placement)
- Structured self-evaluation prompt
- Quick-capture and multi-context spec after spar
- Close-out mode: keep shoshin/stack, skip spar only
- Multi-context folded into close-out
- Team repo guidance: docs/planning placement

**Session brief:**
- Lifecycle: archive on start, delete after verification
- Spar fixes, drop "who-you-are" section

**Framework:**
- Named "Zanshin" (`36c8d9a`)
- Session framework doc — human-facing map of the framework
- Interaction patterns concept doc
- Cross-links across five ai-engineering docs
- Session brief for stack tracking
- `/start` audit + interaction patterns
- Public commits during private sessions require explicit review
- Briefing guardrail: git SHA comparison
- State-check guardrail for session-start briefings
- Capture review agent-initiated at milestones
- Guardrail ordering, branch-closure capture
- Quick wins + spar-trigger hook

**Essays:**
- Zanshin essay: "What remains when the session ends"
- Spar revisions round 2
- Source backlog entries

**Case studies:**
- Architecture fixes and AI self-diagnosis
- Link-depth-drift case study

---

### v2026-04-20 *(first tag — no prior compare)*

> **Commit:** `3d30f8b` · 69 commits · 674 files

**Summary:** The branding session. Field Notes identity, local LLM hardware experiments, essay writing, case studies.

**Identity/branding:**
- Rename to "Field Notes"
- `ABOUT.md` with Henry Hellbusch — person-first public context
- README: signal intent to share, discuss, debate
- Rename `prompts/` → `.prompts/`
- Remove name from `.cursorrules` — template-friendly
- Identity stays in `ABOUT.md`

**Local LLM:**
- Local LLM setup guide expanded (vLLM ROCm, RamaLama)
- Experiment journal: qwen2.5:32b benchmark, qwen3:32b OOM, qwen2.5:72b hybrid
- Verified RamaLama results — 14k context, 90 tok/s, thinking model
- Ollama ROCm container setup — SELinux fix, GPU detection
- vLLM FP8 MoE watch item
- 70B hybrid offload experiment stub

**Essays:**
- "What a Context Window Actually Is"
- "The Case for Local: Disk Management as a Privacy-First AI Task"

**Case studies (3 added):**
- Frictionless entity, lifecycle boundary
- Survivorship bias (#20) — "What Survives a Crash"
- Meta-document-drift

**Framework:**
- `/checkpoint` command added
- `/start` synthesizes handoff from git log when `whats-next.md` absent
- Progressive bookkeeping rule
- Severity framing, README routing
- Case study index → unordered lists
- Journey separated from catalogue in docs index

**Research:**
- Shodan as beginning degree — philosophical anchor
- GitHub sharing and open-source publishing intent

---

## Notes

- Tags point to the **last commit** of each day's work. Diff them with `git diff <prev>..<current>`.
- Days with no tag (gaps) had no committed changes.
- Submodule bumps count toward the root repo's commit total on the day they were committed.
- For submodule-level analysis: `git submodule foreach "git log --oneline <tag>..HEAD"`
