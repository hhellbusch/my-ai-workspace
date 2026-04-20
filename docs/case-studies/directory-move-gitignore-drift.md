---
review:
  status: unreviewed
---

# When the Refactor Updates What It Sees — Not What It Brings Along

> **Audience:** Engineers using AI assistants for repository reorganization, refactoring, or any operation that moves files and directories.
> **Purpose:** Documents how a `git mv` directory reorganization broke a `.gitignore` rule, briefly committing sensitive credentials and a 1.3 GB ISO to local git history. Distinct from AI reasoning failures — this is an execution side-effect that the AI didn't audit. Names the pattern and the structural fix.

---

## What Happened

A repository reorganization moved six product directories (`ansible/`, `argo/`, `coreos/`, `ocp/`, `rhacm/`, `vault/`) under a new `devops/` parent. The AI correctly:

- Executed `git mv` for all six directories
- Updated every cross-reference in docs, rules, commands, and `.cursorrules`
- Verified zero stale path references remained

What it didn't check: whether the root `.gitignore` rules still applied after the move.

The root `.gitignore` had:
```
ocp/install/
```

After `git mv ocp devops/ocp`, that pattern no longer matched the moved directory. Git started tracking `devops/ocp/install/` — which contained a 1.3 GB agent ISO, kubeadmin password, kubeconfig, and pull secrets. All of it landed in the next commit.

The failure was caught when `git push` was rejected for the large file. The commit was amended, the files were removed from local history, and a defense-in-depth fix was applied. The sensitive files never reached the remote.

---

## Why This Is a Different Kind of Failure

Most AI failure modes in this collection are **reasoning failures** — the AI produces wrong output because of how it processes information: anchoring on structure, inheriting stale context, agreeing sycophantically, answering from training knowledge about runtime state.

This is an **execution failure** — the AI correctly executed the task it understood (move directories, update references) but didn't audit the side effects of the mechanical operation it ran. The gap wasn't in reasoning; it was in the scope of the post-operation check.

| Type | Example | Catch mechanism |
|---|---|---|
| Reasoning failure | AI confirms existing backlog priorities | Sparring, zero-base evaluation, shoshin |
| Reasoning failure | AI reports stale document counts | Meta-system review, audit |
| **Execution failure** | `git mv` breaks `.gitignore` rules | **Post-operation audit of side effects** |

Sparring and shoshin don't catch this. A pre-commit review that checks link integrity doesn't catch this. The check needed is: *after any operation that moves directory structure, verify that gitignore rules still cover what they're supposed to cover.*

---

## The Fix

**Immediate:** `git rm --cached -r devops/ocp/install/`, update root `.gitignore` path, amend the commit. Since the push was rejected, no sensitive data reached the remote.

**Structural:** Add a local `.gitignore` inside `devops/ocp/` that says `install/`. A local `.gitignore` travels with its directory on `git mv` — the rule is relative to the directory, not an absolute path from the root. If `devops/ocp/` is ever moved again, the `.gitignore` moves with it and the rule still applies.

```
# devops/ocp/.gitignore
# Travels with the directory on git mv — survives future moves.
install/
```

The root `.gitignore` keeps its path-based rule as a second layer. Either one catches the case; both need to fail for sensitive files to escape.

---

## The Convention Going Forward

Any directory that contains sensitive or large files that should never be committed should have a **local `.gitignore`** as the primary protection, with the root `.gitignore` as a secondary layer. Path-based rules in the root `.gitignore` are fragile: they break silently on directory moves.

Candidate pattern: for any directory that is gitignored by path, add a local `.gitignore` inside it with the same rule expressed relatively. The cost is one extra file; the protection survives reorganization.

**Pre-commit check for directory moves:** After any `git mv`, run `git status` and look for newly-tracked files in previously-gitignored paths before committing. The signature is unexpected files appearing in `git status` that weren't there before the move.

---

## What This Session Did Right

The push rejection was the catch. GitHub's pre-receive hook blocked the 1.3 GB file before it landed on the remote. The sensitive files (credentials, kubeconfig) were collateral — they would have pushed silently if the ISO hadn't triggered the size limit.

If the ISO hadn't been present, the credentials alone (small text files) would have pushed without error. The large binary was accidental protection. That's worth naming: **the obvious problem (large binary) may mask the serious problem (credentials)**. A repository that doesn't have ISO files in its ignored directories might push the credentials without any size-limit rejection.

---

## Connection to Related Case Studies

| Case Study | Relationship |
|---|---|
| [When the Meta-Document Tries to Be the Catalog](meta-document-drift.md) | Same session; same pattern of a path-based rule becoming stale after reorganization |
| [When AI Ignores Changes Made by Other Sessions](stale-context-in-long-sessions.md) | Reasoning failure vs. execution failure — different mechanisms, both result in unexpected state |
| [When Case Studies Generate System Improvements](case-studies-as-discovery.md) | This case study produced a convention change (local `.gitignore`) and a pre-commit check |

---

## Artifacts

| Artifact | What it is |
|---|---|
| [`devops/ocp/.gitignore`](../../devops/ocp/.gitignore) | Local `.gitignore` — travels with the directory on moves |
| [`.gitignore`](../../.gitignore) | Root rule updated to `devops/ocp/install/` — secondary layer |
| [`.cursor/rules/repo-structure.md`](../../.cursor/rules/repo-structure.md) | Convention for directory moves and gitignore coverage |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
