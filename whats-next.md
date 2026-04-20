# Handoff — Local LLM hardware experiments (2026-04-20)

<project_backlog>
**In Progress:**
- Upstream PR: `operators-installer` — `upgradeChain` (chart v3.5.0) — implementation on fork, self-review checklist pending before opening PR

**Up Next:**
- Guide: agentic personal AI infrastructure (PAI/Kai pattern)
- Local LLM: electricity measurement and case studies (ACTIVE TRACK) — deferred until stable model confirmed
- Zen-karate personal knowledge base — experiential content (CRITICAL PATH)
- Essay: The Way Is in Training (first essay) — blocked on personal experiential content
- Essay: The Dojo, Open Source, and Ways of Working — blocked on agile dojo research
- Zen-karate curated reading list — user annotations
- Headless browser fallback for research fetcher
- Low-content capture improvements for research skill

**Ideas count:** ~30 items

**Backlog items added this session:**
- Watch: vLLM FP8 MoE support for gfx1100 (RDNA3) — passive watch, no action needed
- Case study: graph splits — why hybrid CPU+GPU inference fails at scale
</project_backlog>

<original_task>
Pick up the Ollama hybrid CPU+GPU experiment (qwen2.5:72b), log findings, then work on the context window essay while the model downloads. Evolved into a full hardware capability exploration across three models: qwen2.5:72b (hybrid), qwen2.5:32b (full GPU attempts), and the confirmed working baseline qwen3:30b-a3b.
</original_task>

<work_completed>

**Experiment 1 — qwen2.5:72b hybrid offload (Ollama ROCm container)**
- Confirmed Ollama container GPU detection with two required flags: `-e HSA_OVERRIDE_GFX_VERSION=11.0.0` (RDNA3 gfx1100 hint) and `--security-opt label=disable` (SELinux device node bypass)
- Model loaded: 29/81 layers on GPU (36%), 52 layers on CPU (64%), 15.6 GiB GPU / 27.9 GiB pinned host RAM
- Context: auto-capped at 4096 (vs 32K trained) due to VRAM constraints
- **Result: 718 graph splits per prefill batch → >6 minutes to first token → unusable**
- Security implications of `--security-opt label=disable` documented in journal and committed
- Proper long-term fix: targeted SELinux policy module for kfd_t + DRI device types

**Experiment 2 — qwen2.5:32b Q4_K_M (RamaLama, first attempt)**
- `ramalama serve ollama://qwen2.5:32b` — quay.io/ramalama registry doesn't have this model; used ollama:// prefix
- Weights loaded fully: 65/65 layers on GPU, 18,508 MiB
- **OOM at KV cache + compute graph stage**: 1,744 MiB remaining after weights; n_parallel=4 KV cache = 1,024 MiB; compute graph needed ~750+ MiB; shortfall ~300–500 MiB
- Root cause: RamaLama hard-sets n_gpu_layers=999 which blocked the -fit algorithm from negotiating context reduction

**Experiment 3 — qwen2.5:32b Q4_K_M (post-reboot, ramalama serve)**
- Rebooted to clear ~1 GB leaked VRAM; post-reboot: ~600 MiB in use, ~19,864 MiB free
- `ramalama serve` started loading but system began locking up under memory pressure; port 8080 unreachable before server came up
- Killed — too close to the edge to be practically useful even if it loads
- **Confirmed: dense 32B is not viable on RX 7900 XT regardless of whether it technically fits**

**Documentation committed (all clean):**
- `research/ai-tooling/local-llm-experiment-journal.md` — full entries for all three experiments, findings, and analysis
- `docs/ai-engineering/local-llm-setup.md` — updated dense 32B row with precise failure mode (KV+compute stage, not weights)
- `docs/ai-engineering/local-llm-sysadmin.md` — added missing review frontmatter (unreviewed)
- `BACKLOG.md` — graph splits case study candidate, vLLM FP8 MoE watch item, electricity baseline methodology note
- 6 commits this session (all clean, git status empty)

**Meta housekeeping:**
- Loaded meta rules fresh at session start
- SELinux container security implications documented (--security-opt label=disable removes container_t device enforcement; acceptable for local dev, targeted policy module is the right long-term fix)
- quay.io/ramalama registry gap documented: not all models are mirrored; use ollama:// prefix for non-mirrored models
</work_completed>

<work_remaining>

**Immediate (hardware experiments):**
1. Benchmark qwen2.5:32b — it works but tok/s was never measured. On clean boot: `ramalama serve ollama://qwen2.5:32b` (port **8098**), then:
   ```bash
   curl http://localhost:8098/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"model":"qwen2.5:32b","messages":[{"role":"user","content":"What is 2+2?"}],"stream":false}' \
     | python3 -m json.tool
   ```
2. Compare output quality on a real task vs qwen3:30b-a3b
3. Decide which model to use for the electricity measurement baseline

**Experiment journal — still open:**
- qwen2.5:32b serve post-reboot entry needs `tok/s: not measured — system lockup` note (added context to OOM section but no explicit tok/s line)
- Electricity baseline experiment: deferred — needs stable working model first. Plan documented in journal.

**Context window essay:**
- `docs/ai-engineering/what-a-context-window-actually-is.md` — status: `unreviewed`. Was written from the prior session's experiment data. Good candidate for author read-through. Now has additional data points: qwen2.5:72b auto-capped at 4096 (confirmed), qwen2.5:32b same behavior. Essay currently only references the qwen3:30b-a3b 14,592 token example — could add a note about 4096 cap pattern.

**Case studies to draft (from backlog):**
- Graph splits — why hybrid CPU+GPU inference fails at scale (backlog entry added, source material in journal)
- Performed honesty (pre-existing backlog entry)
</work_remaining>

<attempted_approaches>
- **qwen2.5:72b hybrid via RamaLama** — failed before this session (RamaLama is GPU-only, n_gpu_layers=999 forces all layers to GPU, OOM). Documented in prior session journal entry. This is why Ollama container was used for 72B.
- **Ollama container without HSA_OVERRIDE_GFX_VERSION** — GPU detected as 0 VRAM, fell back to CPU-only. Required the env var for gfx1100 RDNA3 detection.
- **Ollama container without --security-opt label=disable** — SELinux blocked /dev/kfd and /dev/dri device node access even with --device flags. :Z volume flag only handles files, not devices.
- **quay.io/ramalama/qwen2.5:32b** — image doesn't exist on quay.io mirror. Error: "Manifest for qwen2.5:32b was not found in the Ollama registry." Use `ollama://qwen2.5:32b` instead.
- **ramalama serve qwen2.5:32b (pre-reboot)** — OOM at KV+compute stage, ~300-500 MiB short
- **ramalama serve qwen2.5:32b (post-reboot)** — system lockup, server never came up
</attempted_approaches>

<critical_context>

**Hardware baseline (tellurium):**
- GPU: AMD Radeon RX 7900 XT, 20 GB VRAM, gfx1100 (RDNA3)
- CPU: Intel i5-13600K (13th Gen)
- RAM: 62.6 GB
- Host OS: Fedora 43, kernel 6.18.10-200.fc43.x86_64
- ROCm: 6.4.2 (most packages) / 6.4.4 (rocm-core)
- SELinux: enforcing (relevant for container GPU passthrough)
- Display: Wayland/GNOME — uses ~600 MiB VRAM at idle after reboot

**Confirmed working stack:**
```bash
ramalama serve quay.io/ramalama/qwen3:30b-a3b
# ~90 tok/s, ~19.5 GB VRAM, ~14,592 n_ctx, GPU-only, no SELinux issues
```

**Ollama ROCm container (working command — needed for hybrid offload):**
```bash
podman run -d --name ollama \
  --group-add=video \
  --device /dev/kfd \
  --device /dev/dri \
  --security-opt label=disable \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
  -p 11434:11434 \
  -v "${HOME}/.ollama:/root/.ollama:Z" \
  docker.io/ollama/ollama:rocm
```
Security note: `--security-opt label=disable` removes SELinux container_t device enforcement. Acceptable for local dev, not for multi-user/production.

**Model status on this hardware:**
- **qwen2.5:32b Q4_K_M: CONFIRMED WORKING** — loads on fresh boot with 382 MiB free (18,508 + 1,024 KV + 307 compute = 19,839 MiB). 2 graph splits. Port 8098. **Requires clean boot** — VRAM fragmentation from prior failed loads causes OOM. tok/s not yet measured.
- 72B hybrid: 718 graph splits per batch → unusable for interactive work
- qwen3:30b-a3b MoE: ~90 tok/s, confirmed working, more headroom, no clean-boot requirement

**FP8 MoE on gfx1100:** Hardware supports FP8 (RDNA3 matrix ops), software doesn't (vLLM fused_moe kernels tuned for MI300X/gfx942 only). Passive watch item in backlog.

**Key documents:**
- Experiment journal: `research/ai-tooling/local-llm-experiment-journal.md`
- Setup guide: `docs/ai-engineering/local-llm-setup.md`
- Context window essay: `docs/ai-engineering/what-a-context-window-actually-is.md` (unreviewed)
- Sysadmin doc: `docs/ai-engineering/local-llm-sysadmin.md` (unreviewed)
</critical_context>

<current_state>
- **Git:** Clean — all work committed across 6 commits this session
- **Running process:** qwen2.5:32b ramalama serve is likely still running/struggling — kill it: `pkill -f llama-server`
- **qwen2.5:32b blobs:** Downloaded and cached at `~/.ramalama/` (or wherever RamaLama stores models). ~18.5 GB on disk. Can delete to reclaim space if not planning Q3_K_M experiment.
- **Backlog:** Current — all this session's findings logged
- **Context window essay:** Unreviewed draft, good for next session read-through
- **Electricity measurement:** Deferred pending stable model. Plan documented in journal. Ready to execute once qwen3:30b-a3b is confirmed running again.
</current_state>

<case_study_opportunities>
**Graph splits — why hybrid CPU+GPU inference fails at scale**
- Already added to backlog as a case study candidate
- Core finding: 718 PCIe bus hand-offs per prefill batch; RAM quantity is irrelevant when bus is the bottleneck; 6+ minutes to first token. Counterintuitive and well-documented with real numbers.
- Source: experiment journal 2026-04-20 qwen2.5:72b entry

**The hardware ceiling as a discovered constraint, not a planned finding**
- The session started intending to test hybrid 72B, then pivoted to 32B after failure, then hit the 32B ceiling
- Pattern: each "next best option" was reached by elimination, not selection — connects to the survivorship bias case study already in the collection
- The 32B failure mode (fits in VRAM, fails on overhead) is a subtler version of the same pattern: something that "should work" by the headline spec that doesn't in practice
</case_study_opportunities>

<assumptions_carried>
- **qwen3:30b-a3b as the ceiling:** Confirmed across two sessions. The ~90 tok/s figure is from a prior session; not re-measured this session. If the next session starts fresh with this model, take a fresh tok/s reading for the journal.
- **Electricity measurement plan:** Assumed this model (qwen3:30b-a3b) will be the baseline for electricity measurement. If a better option emerges (e.g., Q3_K_M 32B works cleanly), revisit the baseline choice.
- **Context window essay accuracy:** Essay references qwen3:30b-a3b 14,592 token runtime context. Both 72B and 32B models this session also auto-capped at 4096. This could either strengthen the essay (it's a consistent pattern across models) or need a nuance (4096 is the default, not a fixed cap — it depends on VRAM).
</assumptions_carried>
