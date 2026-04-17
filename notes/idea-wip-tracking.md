# Idea: Work-in-Progress and Priority Tracking

> **Status:** Idea — not yet planned or implemented. Captured from a conversation about repo organization (April 2026).

## The Problem

This workspace accumulates ideas, partial work, and upstream contributions that need follow-up. Currently there's no structured way to:

- Track what's in progress vs. what's just an idea
- Prioritize across unrelated work items
- Hand off context between sessions so the AI can pick up where we left off
- See at a glance what needs attention

## Examples of In-Flight Work

- **Helm chart upstream improvement** (`git-projects/helm-charts/`) — needs review, testing, and submission upstream
- **ArgoCD diff preview contribution** (`git-projects/argocd-diff-preview/`) — resulted in [upstream issue #381](https://github.com/dag-andersen/argocd-diff-preview/issues/381)
- **Headless browser fallback for research fetcher** (`.cursor/skills/research-and-analyze/`) — designed but not implemented
- **Low-content capture improvements** for the research skill
- Various OCP troubleshooting guides that could be expanded

## Possible Approaches

1. **A simple markdown file** (`WIP.md` or `BACKLOG.md`) in the repo root — low ceremony, easy to scan, AI can read/update it
2. **A slash command** (`/whats-next` already exists for session handoffs, but it's session-scoped not project-scoped)
3. **GitHub Issues** — standard tooling, but adds friction for quick captures
4. **A dedicated section in the root README** — visible but could get noisy
5. **A `notes/backlog.md`** — fits the existing convention for informal notes

## What Would Make This Useful

- Quick to add items (low friction during a session)
- Scannable priority ordering
- Each item has enough context that the AI can understand what to do without re-reading the full history
- Items link to relevant files/directories
- Clear lifecycle: idea → in progress → done/abandoned

## Next Step

Plan this in a future session using `/create-plan`.
