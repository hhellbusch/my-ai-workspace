---
name: release-tags
description: Tag and analyze day-based releases in a workspace — create release tags for recent sessions, generate RELEASES.md, and diff between releases to understand what changed
argument-hint: "[backfill | analyze | tag-current | help]"
allowed-tools: Read, Write, StrReplace, Shell, Glob, Grep
---

# Release Tags — Day-Based Release Tagging

Create structured release tags from unstructured "vibe coding" sessions. Each tag points to the last commit of an active day, and `RELEASES.md` captures what happened. Use `git diff <tag>..<tag>` to analyze changes between sessions.

## Context

- Releases file: `RELEASES.md` (repo root)
- Release tags: `vYYYY-MM-DD` (e.g. `v2026-05-19`)
- Current date: `date "+%Y-%m-%d"`

## Usage

| Command | Purpose |
|---|---|
| `/release-tags backfill` | Tag all untagged active days from the past N weeks |
| `/release-tags analyze` | Show diff summary for the last few releases |
| `/release-tags tag-current` | Tag today's session (for end-of-session) |
| `/release-tags help` | Show this summary |

---

## Process

### Subcommand: `help` (default, no arguments)

Show the usage table above and a quick example:

```bash
# Diff between two sessions
git diff v2026-05-12..v2026-05-13 --stat

# Files changed
git diff v2026-05-12..v2026-05-13 --name-status

# Full narrative
git log v2026-05-12..v2026-05-13 --oneline
```

---

### Subcommand: `backfill`

Identify and tag all untagged active days from the past 8 weeks.

#### Step 1: Discover active days

Find all days in the past 8 weeks with commits:

```bash
git log --format="%ad" --date=short --since="8 weeks ago" | sort -u
```

Filter out weekends (optional — the user may have worked weekends). For each day, count commits and new files:

```bash
git log --after="${day}T00:00:00" --before="${day}T23:59:59" --oneline | wc -l
git log --after="${day}T00:00:00" --before="${day}T23:59:59" --name-only --pretty=format: | grep -v '^$' | sort -u | wc -l
```

#### Step 2: Check existing tags

Find which days already have tags:

```bash
git tag -l 'v2026-*' | sort | while read t; do echo "${t#v}"; done
```

Days without tags are the ones to tag. Show the user:

```
Days to tag (N):
  v2026-04-29  — 31 commits, 64 files
  v2026-05-05  — 12 commits, 270 files
  ...
Already tagged:
  v2026-05-12  — existing
  v2026-05-13  — existing
```

#### Step 3: Create tags

For each untagged day, find the last commit and create the tag:

```bash
last=$(git log --after="${day}T00:00:00" --before="${day}T23:59:59" --format="%H" | tail -1)
git tag "v${day}" "$last"
```

Verify each tag points to the correct commit:

```bash
tag_commit=$(git rev-list -1 "v${day}")
expected=$(git log --after="${day}T00:00:00" --before="${day}T23:59:59" --format="%H" | tail -1)
# If they match, good. If not, surface the mismatch.
```

#### Step 4: Create or update RELEASES.md

If `RELEASES.md` doesn't exist, create it with:
1. A quick-reference table (tag, date, commits, files, theme)
2. Detailed release sections (date, commit hash, summary, key changes)

If `RELEASES.md` exists, append the new release sections and update the summary table.

**Compare links:** Tags in the summary table and release section headings should link to GitHub compare views. Derive the repo URL from `git remote get-url origin` (strip `.git`). Format: `[vYYYY-MM-DD](https://github.com/<org>/<repo>/compare/<prev>...<tag>)`. The first tag has no prior, so leave it unlinked with a note: `v2026-04-20 *(first tag — no prior compare)*`.

For summaries, use the commit messages to infer the theme. Cluster commits by topic (e.g., "vGPU docs", "commit-guard", "submodule bumps", "skills migration") and write a one-line summary per cluster. Group clusters into a coherent theme paragraph.

#### Step 5: Commit

```bash
git add RELEASES.md
git commit -m "docs: add release tags for <date-range> — N sessions tagged"
```

**Important:** Split `git add` and `git commit` (commit-guard requires this).

---

### Subcommand: `analyze`

Show a comparison of the last N releases (default: 5). For each pair of adjacent releases:

```bash
git diff <tag1>..<tag2> --stat
git diff <tag1>..<tag2> --name-status | head -30
```

Present:

```
## Release Comparison (last 5)

| From → To | Commits | Files Changed | Additions | Deletions |
|---|---|---|---|---|
| v2026-05-08 → v2026-05-12 | 36 | 121 | +420 | -180 |
| v2026-05-12 → v2026-05-13 | 77 | 212 | +1362 | -23376 |

## Key files changed (v2026-05-12 → v2026-05-13)
A  rules/process-kill-guard.md
M  .agents/skills/...
D  .cursor/rules/...
```

Ask: "Want me to diff a specific pair? Or generate a RELEASES.md section?"

---

### Subcommand: `tag-current`

Tag the current HEAD as the release for today. For end-of-session use.

1. Check if a tag for today already exists: `git tag -l "v$(date +%Y-%m-%d)"`
2. If yes, ask: "Tag for today already exists. Overwrite?"
3. If no: `git tag "v$(date +%Y-%m-%d)" HEAD`
4. Ask the user for a one-line summary of today's work (or infer from the last commit message)
5. Append a release section to `RELEASES.md` (or create it if missing)
6. Commit: `git add RELEASES.md` then `git commit -m "docs: add release tag for today"`

---

## Release Tag Naming Convention

Format: `vYYYY-MM-DD` (e.g. `v2026-05-19`)

- One tag per active day (not per session — days may span multiple sessions)
- Days with no commits are skipped
- Tags point to the **last commit** of the day, not necessarily the last commit before the next day (some days are just submodule bumps with no meaningful work)
- Existing tags are never overwritten without explicit confirmation

## How to Use Tags for Analysis

```bash
# What changed between two sessions?
git diff v2026-05-12..v2026-05-13 --stat

# Which files were added, modified, or deleted?
git diff v2026-04-20..v2026-04-21 --name-status

# Full narrative of a session
git log v2026-05-03..v2026-05-05 --oneline --author-date-order

# Files touched across all releases in a range
git diff v2026-04-20..v2026-05-19 --name-only | sort -u | wc -l

# Commits per release
for t in $(git tag -l 'v2026-*' | sort); do
  prev=$(git tag -l 'v2026-*' | sort | awk -v t="$t" 'prev{print prev} {prev=$1}')
  count=$(git log --oneline "$prev..$t" | wc -l)
  printf "  %-16s %3d commits\n" "$t" "$count"
done
```

## Submodule Releases

This skill tags the **root repo** only. Submodule commits are captured implicitly through the root's submodule pointer bumps. For submodule-level analysis:

```bash
git submodule foreach "git log --oneline v2026-05-12..v2026-05-13"
```

Submodule release tags are not managed by this skill (not every submodule has active daily work). If a submodule needs its own tags, create them manually with the same `vYYYY-MM-DD` convention.
