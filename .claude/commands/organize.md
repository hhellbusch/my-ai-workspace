---
description: Audit repository structure and flag misplaced files or convention violations
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Organize — Repo Structure Audit

## Instructions

This command is **read-only**. It reports findings but does not move or modify files. The user decides what to act on.

### Step 1: Load conventions

Read `.cursor/rules/repo-structure.md` to load the directory map, placement rules, and naming conventions.

### Step 2: Scan the repo root

List all files in the repo root (not directories). Compare against the allowed root files:
- `README.md`, `AI-DISCLOSURE.md`, `.gitignore`, `.cursorrules`, `.actrc`, `.actrc.example`, `.secrets`

Flag anything else as **"Misplaced root file"** with a suggested destination based on the directory map.

### Step 3: Check top-level directories

List all top-level directories (excluding `.git/`, `.cursor/`, `.claude/`, `.meta-system-backup/`, `.planning/`, `.taches-import/`, `.cursor-skills/`, `.claude-plugin/`).

For each directory:
1. Check if it appears in the directory map from the rule. Flag unknown directories as **"Unregistered directory"**.
2. Check if it has a `README.md`. Flag missing READMEs as **"Missing README"**.
3. Check naming convention: lowercase, hyphen-separated. Flag violations as **"Naming convention violation"**.

### Step 4: Check README.md directory structure

Read the root `README.md` and find the "Directory Structure" section. Compare the directories listed there against the actual top-level directories on disk. Flag:
- Directories on disk but missing from README as **"README out of date — missing entry"**
- Directories in README but not on disk as **"README out of date — stale entry"**

### Step 5: Check project contents registry

Read `CLAUDE.md` and find the "Workspace Structure" section. Also read `.cursorrules` and find the "Project Contents" section. Compare both against actual directories on disk. Flag mismatches the same way as Step 4 — flag in the document where the entry is missing.

### Step 6: Spot-check placement rules

Scan for common violations:
- Markdown files in the repo root that look like documentation (not repo-level config)
- Shell scripts or Python files in the repo root
- Directories named `analyses/` or `archive/` (should be consolidated into `research/` or removed)
- Troubleshooting-style content in `docs/` (symptom/cause/fix structure in a docs/ file)

### Step 7: Report

Present findings organized by severity:

```
## Repo Structure Audit

### Misplaced Files (move these)
- [ ] `file.sh` in root → suggested: `{destination}/`

### Missing READMEs
- [ ] `directory/` has no README.md

### Stale References
- [ ] `README.md` directory map missing: `{dir}/`
- [ ] `CLAUDE.md` / `.cursorrules` project contents missing: `{dir}/`

### Convention Violations
- [ ] `Directory_Name/` — should be lowercase-hyphenated

### Clean
- Everything else looks good. {N} directories checked, {M} follow conventions.
```

If there are no findings in a category, omit that section. End with the "Clean" summary line regardless.

After reporting, ask: **"Want me to fix any of these? Reply with the numbers or 'all'."**
