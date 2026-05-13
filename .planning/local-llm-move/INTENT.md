# Intent — Move local LLM setup guides from docs/ to devops/

## Problem

`docs/ai-engineering/local-llm-setup.md` and `local-llm-vllm.md` are practical setup guides with commands, configurations, and reference tables — not essays. They belong with the category of "practical reference" rather than "curated thinking." The AGENTS.md rule is: essays → docs/, runnable examples & troubleshooting → devops/. These violate that boundary.

## Current state

- `docs/ai-engineering/local-llm-setup.md` — main setup guide (direction-reviewed)
- `docs/ai-engineering/local-llm-vllm.md` — vLLM reference (unreviewed)
- `docs/ai-engineering/local-llm-sysadmin.md` — disk management case study (this *stays* — it's a case study, not setup)
- 10+ files contain links to these paths (READMEs, library entries, research journals, backlog items)

## Proposed move

`docs/ai-engineering/local-llm-setup.md` → `devops/llm/local-llm-setup.md`
`docs/ai-engineering/local-llm-vllm.md` → `devops/llm/local-llm-vllm.md`

Create `devops/llm/README.md` as the directory home.

## What stays in docs/

- `local-llm-sysadmin.md` — case study (privacy argument made concrete)
- `what-a-context-window-actually-is.md` — essay (concepts, not commands)
- `openshift-ai-llm-deployment-summary.md` — essay (enterprise architecture analysis)
- `youtube-video-analysis.md` — guide for a workflow (research process, not setup)
- `spar-to-essay-pipeline.md` — case study (generative workflow, not setup)

## What's out of scope

- Moving the experiment journal or sparring notes (those are research material in `research/ai-tooling/`)
- Moving the Level1Techs library entry (it's an enriched reference, not setup)
