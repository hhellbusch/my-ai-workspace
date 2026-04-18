---
description: Comprehensive content audit — link integrity, registry alignment, cross-references, and freshness
allowed-tools:
  - Shell
  - Read
  - Glob
  - Grep
---

# Audit — Content Health Check

<objective>
Systematically audit the workspace for content drift, broken links, stale registries, missing cross-references, and meta-system regressions. Catches the subtle problems that accumulate as content and tooling evolve across sessions.

This command is read-only. It reports findings organized by severity and asks what to fix.
</objective>

<context>
- Repo structure conventions: @.cursor/rules/repo-structure.md
- Project description: @.cursorrules (Project Contents section)
- Root README: @README.md (Directory Structure section)
- Docs index: @docs/README.md
- Research index: @research/README.md
- Backlog: @BACKLOG.md
- Planning: scan .planning/ for active projects
</context>

<process>

## Layer 1: Link Integrity

Scan all committed markdown files for internal links (both `[text](path)` and `[text](../relative/path)` forms). For each link:

1. Resolve the path relative to the file containing it
2. Check if the target file or directory exists
3. Report broken links grouped by source file

Skip external URLs (http/https) — those are not part of this audit.

## Layer 2: Registry Alignment

Compare documented inventories against what actually exists on disk.

### 2a. .cursorrules Project Contents
- Parse the "Project Contents" section of `.cursorrules`
- Compare against actual directories and their contents
- Flag: directories or content on disk but missing from .cursorrules
- Flag: entries in .cursorrules that don't match what's on disk

### 2b. Root README.md Directory Structure
- Parse the directory tree in `README.md`
- Compare against actual top-level directories (excluding gitignored)
- Flag: directories on disk but missing from the tree
- Flag: stale entries in the tree

### 2c. Meta-System Counts
- Count actual files in `.cursor/commands/`, `.cursor/skills/`, `.cursor/agents/`
- Compare against any documented counts in README.md or .cursorrules
- Flag mismatches

### 2d. docs/README.md
- List all .md files in `docs/` (excluding README.md)
- Compare against entries in docs/README.md
- Flag: files not listed in the reading list
- Flag: entries pointing to files that don't exist

### 2e. research/README.md
- List all directories in `research/` (excluding README.md)
- Compare against entries in research/README.md contents table
- Flag: directories not listed
- Flag: stale entries

### 2f. Backlog Consistency
- Check all file path references in BACKLOG.md Links fields
- Verify referenced paths exist
- Flag broken references

## Layer 3: Cross-Reference Gaps

Identify content that exists but isn't linked from its natural parent or peers.

### 3a. Orphaned Content
- Files in `docs/` not linked from docs/README.md
- Directories in `research/` not linked from research/README.md
- Commands in `.cursor/commands/` not documented in .cursorrules
- Skills in `.cursor/skills/` not documented in .cursorrules
- Rules in `.cursor/rules/` (informational — list what rules exist)

### 3b. Missing Cross-Links
- Check each docs/ essay's "Related Reading" section (if it has one) for links to other docs/ essays
- Identify docs/ essays that don't have a Related Reading section at all
- Check if planning projects in .planning/ have corresponding backlog items

### 3c. README Coverage
- List all directories (recursive to depth 2) that lack a README.md
- Exclude known exceptions: `sources/`, `findings/`, `completed/`, `phases/`, hidden directories

## Layer 4: Freshness Flags

### 4a. Stale Descriptions
- Compare .cursorrules "Documentation (docs/)" description against actual docs/README.md contents
- Check if backlog "Last updated" date is more than 2 weeks old with no recent commits
- Check .planning/ ROADMAP progress tables against actual phase completion (SUMMARY.md files)

### 4b. Potential Regressions
- If any `.cursor/skills/*/SKILL.md` references files that don't exist (broken skill references)
- If any `.cursor/commands/*.md` references files via @ syntax that don't exist
- If any `.cursor/rules/*.md` references files that don't exist

## Layer 5: Review Coverage

Scan all committed markdown files for `review:` frontmatter blocks. Categorize files by content type and report validation status.

Reference: `.cursor/rules/review-tracking.md` for the frontmatter convention and `AI-DISCLOSURE.md` for validation type definitions.

### 5a. Coverage by Category

For each content category, count:
- Files with `review:` frontmatter (reviewed)
- Files without `review:` frontmatter (assumed direction-reviewed)
- Validation types present (how many `read`, `tested`, `fact-checked`, etc.)

Categories:
- **Essays**: `docs/**/*.md` (excluding README.md files)
- **DevOps**: `ansible/**/*.md`, `ocp/**/*.md`, `argo/**/*.md`, `coreos/**/*.md`, `rhacm/**/*.md`, `vault/**/*.md`
- **Meta-system**: `.cursor/commands/*.md`, `.cursor/skills/**/*.md`, `.cursor/rules/*.md`
- **Research**: `research/**/*.md`, `library/**/*.md`

### 5b. Recently Added Without Review

Find markdown files committed in the last 14 days that have no `review:` frontmatter. These are candidates for the next review pass.

### 5c. Stale Reviews

Find files where the most recent validation date is older than the file's last git modification date. This means the file was changed after the last review — the review may no longer be current.

Present as:

```
### Review Coverage
- Essays: 3/16 reviewed (19%) — 2 read, 1 fact-checked
- DevOps: 12/248 reviewed (5%) — 8 read, 4 tested
- Meta-system: 15/237 reviewed (6%) — 10 read, 5 used-in-practice
- Research: 0/100 reviewed (0%)
- **Total: 30/601 reviewed (5%)**

### Needs Review (recently added)
- docs/case-studies/new-essay.md (committed 2026-04-17)

### Stale Reviews (modified after last review)
- docs/ai-engineering/the-shift.md — reviewed 2026-04-10, modified 2026-04-15
```

## Report

Present findings organized by severity:

```
## Content Audit Report

### Broken Links (fix these)
- [ ] `file.md` line N: link to `path/that/does/not/exist`

### Registry Drift (update these)
- [ ] `.cursorrules` missing: [description of what's missing]
- [ ] `README.md` directory tree missing: `.planning/`
- [ ] Meta-system count: says N commands, actually M

### Cross-Reference Gaps (consider adding)
- [ ] `docs/new-essay.md` not linked from docs/README.md
- [ ] `.cursor/commands/review.md` not documented in .cursorrules

### Missing READMEs
- [ ] `directory/` has no README.md

### Freshness Flags (review these)
- [ ] BACKLOG.md last updated N days ago
- [ ] .planning/project/ ROADMAP shows Phase 1 in progress but SUMMARY exists

### Clean Areas
- Link integrity: N files checked, M links validated
- Research index: up to date
- [etc.]
```

After reporting, ask: "Want me to fix any of these? Reply with numbers, categories, or 'all'."
</process>

<success_criteria>
- Every committed markdown file scanned for internal link integrity
- All registry documents (.cursorrules, README.md, docs/README.md, research/README.md) compared against disk
- Meta-system artifacts (skills, commands, rules, agents) checked for coherence
- Cross-reference gaps identified with specific suggestions
- Review coverage reported by content category with validation type breakdown
- Stale reviews flagged when files were modified after their last review date
- Clear severity-based report with actionable items
- No false positives from gitignored directories or expected-empty directories
</success_criteria>
