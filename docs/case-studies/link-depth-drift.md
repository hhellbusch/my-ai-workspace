---
review:
  status: unreviewed
  notes: "AI-generated case study draft. Shell command output verified at audit time. Narrative framing needs author read."
---

# When the Directory Moves and the Links Don't Know

> **Audience:** Engineers using AI assistants for repository reorganization or any operation that restructures directory depth.
> **Purpose:** Documents how moving directories one level deeper silently breaks every relative upward link in the affected subtree — uniformly, invisibly, and only discoverable by navigating the links. Companion to the gitignore drift case study from the same reorganization.

---

## What Happened

The same reorganization that broke `.gitignore` rules also broke 23 internal navigation links. Six product directories (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`) were moved under a new `devops/` parent. The AI executed the move correctly, updated cross-references in docs and rules, and committed cleanly.

What it didn't check: whether the relative upward links inside those directories still resolved.

Every file that previously linked to the root-level `AI-DISCLOSURE.md` using `../../AI-DISCLOSURE.md` was now one level deeper. The correct path was `../../../AI-DISCLOSURE.md`. The files committed without error. Git had no opinion. The links simply stopped resolving.

The failure wasn't discovered in that session. It wasn't discovered in the next one, or the one after. It surfaced months later when a full repository audit was run and 23 broken links appeared with a uniform signature: all off by exactly one `../`, all in the `devops/` subtree, all pointing to the same root-level file.

---

## Why This Is Silent

The gitignore drift case produced an immediately loud failure: `git push` was rejected for a file that was too large. This one produced nothing.

Markdown files with broken relative links render without error. Git tracks the file content, not the validity of paths inside it. A link that resolves to a missing file looks identical in `git diff` to a link that resolves correctly. The commit succeeds, CI passes (if there's no link-checking step), and the session ends with everything feeling done.

The signature of this failure is uniformity. One broken link might be a typo. Twenty-three broken links, all off by the same amount, all in the same subtree, all pointing to the same target — that's a structural root cause, not random breakage. But seeing the signature requires running the audit. Without it, each broken link is invisible in isolation.

| Property | Value |
|---|---|
| Files affected | 23 |
| Root cause | Single directory reorganization (`git mv`) |
| Error per file | Off by exactly one `../` |
| Signal at commit time | None |
| Signal at push time | None |
| Time until discovery | Multiple sessions |

---

## The Mechanism

Relative upward links encode the directory depth of the file that contains them. A file at `ocp/troubleshooting/README.md` uses `../../AI-DISCLOSURE.md` to reach the root. After `git mv ocp devops/ocp`, the same file is at `devops/ocp/troubleshooting/README.md` — one level deeper. The link still says `../../AI-DISCLOSURE.md`, which now resolves to `devops/AI-DISCLOSURE.md`. That file doesn't exist.

Every file in the moved subtree that uses any relative path pointing upward has the same problem. The number of `../` segments needed increases by one for each level the directory moved down. Moving from root-level to one level deep: every relative upward link needs one additional `../`. Every file. Every link.

This is not a rare edge case. It is the guaranteed result of any directory move that increases depth.

---

## What the Human Brought

The audit that caught this was a deliberate framework practice — `/audit` run as a periodic content health check. Without it, the correct question to ask would have been: *after this reorganization, did we check whether the links inside the moved subtree still resolve?* That question was not asked at the time of the move.

The human contribution was running the audit and recognizing the signature: "23 files, all off by one, all in devops — that's a depth shift from a directory move, not random breakage." The root cause was diagnosed immediately from the pattern. Without that recognition, the fix would have been 23 separate manual corrections rather than one shell loop.

---

## The Fix

The immediate fix was systematic — one shell command to find and correct all affected links:

```bash
# Find all broken AI-DISCLOSURE.md links in the devops subtree
find devops -name "*.md" | while read f; do
  dir=$(dirname "$f")
  grep -oP '\]\(\K[^)]+(?=\))' "$f" | grep "AI-DISCLOSURE" | while read link; do
    resolved=$(python3 -c "import os,sys; print(os.path.normpath(os.path.join(sys.argv[1],sys.argv[2])))" "$dir" "$link" 2>/dev/null)
    [ ! -e "$resolved" ] && echo "BROKEN: $f -> $link"
  done
done
```

Every affected file had exactly the same correction: one additional `../` prepended to the link path. A `sed` pass over the `devops/` subtree fixed all 23 in one operation.

---

## The Convention Going Forward

After any directory move that changes depth, run a link check on the moved subtree before committing. The check is fast, the failure is slow to accumulate, and the correction is mechanical when caught immediately.

```bash
# Replace MOVED_DIR with the destination path, e.g. devops/ocp
find MOVED_DIR -name "*.md" | while read f; do
  dir=$(dirname "$f")
  grep -oP '\]\(\K[^)]+(?=\))' "$f" | grep -v '^https\?://' | grep -v '^http' | while read link; do
    target="${link%%#*}"
    [ -z "$target" ] && continue
    resolved=$(python3 -c "import os,sys; print(os.path.normpath(os.path.join(sys.argv[1],sys.argv[2])))" "$dir" "$target" 2>/dev/null)
    [ ! -e "$resolved" ] && echo "BROKEN: $f -> $link"
  done
done
```

This check is now documented in `repo-structure.md` under "When Moving Directories." It belongs there rather than here because it's a pre-commit hygiene step, not a recovery procedure.

---

## Why This Case Is Worth Naming Separately

The gitignore drift case covers the security consequence of the same reorganization. This case covers the navigation consequence. They share a root cause but demonstrate different failure properties:

- Gitignore drift: **loud failure, fast discovery** (push rejected)
- Link depth drift: **silent failure, slow discovery** (nothing signals it)

The silence here is the point. A practitioner who reads the gitignore drift case and thinks "I should check gitignore rules after directory moves" has not learned to check link depth. Both checks need to be on the same post-move checklist.

More broadly: when an AI assistant executes a structural reorganization, the scope of "did this work correctly?" extends beyond what the AI naturally audits. The AI checked cross-references in docs, rules, and commands — the files it was explicitly told to update. It didn't check the relative link math inside the moved files themselves. The gap between "the task I was given" and "the side effects of executing it" is where these failures live.

---

## Connection to Related Case Studies

| Case Study | Relationship |
|---|---|
| [When the Refactor Updates What It Sees — Not What It Brings Along](directory-move-gitignore-drift.md) | Same directory reorganization; gitignore rule failure vs. link depth failure — different failure surfaces, same root cause |
| [When AI Ignores Changes Made by Other Sessions](stale-context-in-long-sessions.md) | Both involve state that degrades silently across sessions; gitignore drift is loud, link drift is quiet, stale context is inside the model |
| [When Case Studies Generate System Improvements](case-studies-as-discovery.md) | The audit that found this case also produced three systemic improvements: audit noise reduction, registry sync checks, and pre-move link verification guidance |

---

## Artifacts

| Artifact | What it is |
|---|---|
| [`.cursor/rules/repo-structure.md`](../../.cursor/rules/repo-structure.md) | "When Moving Directories" section — link-depth drift pattern and pre-commit check |
| [`.cursor/commands/audit.md`](../../.cursor/commands/audit.md) | Layer 1 link integrity check — updated to skip scraped content dirs and fenced code blocks (noise reduction from the same audit run) |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
