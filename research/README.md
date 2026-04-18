# Research

Research workspaces containing fetched sources, analysis findings, and assessments. Each directory is a self-contained research exercise created using the [research-and-analyze skill](../.cursor/skills/research-and-analyze/SKILL.md).

## Contents

| Directory | Topic | Sources | Key output |
|---|---|---|---|
| `openshift-ai-llm-deployment/` | Verification of Jared Burck's enterprise LLM deployment article | 53 of 62 references fetched | [assessment.md](openshift-ai-llm-deployment/assessment.md) |
| `nvidia-gpu-operator-ocp418/` | NVIDIA GPU Operator production impact on OCP 4.18 | Single analysis | [analysis.md](nvidia-gpu-operator-ocp418/analysis.md) |
| `zen-karate-philosophy/` | Zen Buddhism, karate, and applied philosophy for life and work | In progress | [personal-notes.md](zen-karate-philosophy/personal-notes.md), [curated-reading.md](zen-karate-philosophy/curated-reading.md) |
| `3blue1brown/` | Deep Learning series transcripts (neural networks, transformers, attention, LLMs) | 5 videos fetched | [README.md](3blue1brown/README.md) |

## Structure Convention

Each research workspace follows this layout:

```
research/{topic}/
├── manifest.md          # Reference tracking (URL, status, file path)
├── sources/             # Fetched source content (one .md per reference)
├── findings/            # Per-batch analysis results
├── assessment.md        # Final synthesized assessment
└── verification-notes-*.md  # Earlier partial analyses (if any)
```

See [Building a Research Skill](../docs/case-studies/building-a-research-skill.md) for the full story behind this workflow.
