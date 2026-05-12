# Git — Learning Guide

> For developers who want to understand what git does, not just memorize commands.

---

## 1. What Git Actually Is

Git is a **content-addressable filesystem**. You can think of it as three things at once:

### A. A content store (the object database)

Every file you put in git gets stored by its **content hash** — a SHA-1 fingerprint of the file's contents. Same content, same hash. Different content, different hash. The object database is the entire history of everything you've ever told git about.

```
Blob (file content)  →  hash
Tree (directory listing) →  hash
Commit (snapshot + metadata) →  hash
```

When you run `git add`, git takes a snapshot of a file, computes its hash, and stores it. When you run `git commit`, git creates a commit object that points to a tree object (the snapshot of the whole working directory) and to its parent commit(s).

### B. A directed acyclic graph (DAG) of commits

Commits form a graph — each commit points to zero or more parents. A normal linear history is a chain. A merge is a node with two parents. Git stores this graph explicitly.

```
A — B — C — D    ← linear history
        \
         E — F    ← feature branch from C
```

This graph is the source of truth. Everything else (branches, tags, refs) is just a label pointing to a node in the graph.

### C. A set of labels (refs)

A branch is a label. A tag is a label. `HEAD` is a label pointing to your current branch. When you "check out a branch," you're moving the HEAD label and updating your working directory to match the commit the label points to.

```
main    ────────────→ D
develop ──────────→ F
HEAD      ────────→ develop   ← your current position
```

**Key insight:** branches are cheap and disposable. They're just labels that move. This is why git branching feels so different from other version control systems.

---

## 2. The Mental Model: Staging Area

Git has a workflow that trips up beginners:

```
Working Directory  →  Staging Area  →  Local Repository
```

- **Working directory**: your actual files. What you see and edit.
- **Staging area** (the index): a list of files you're telling git "prepare a commit of these." Nothing is committed until you run `git commit`.
- **Local repository**: the database of all your commits.

`git add` moves files from working directory to staging area. `git commit` moves them from staging area to the repository.

**Why two steps?** Because sometimes you're working on multiple things at once and want to commit them separately. Sometimes one change touches ten files — you want to commit six of them now and four later. The staging area lets you be surgical.

**The command you'll use most:** `git add -A` (stage everything). If you're not doing surgical commits, just stage everything and commit.

---

## 3. The Four Commands That Matter

90% of git usage is four commands, repeated in various orders:

### `git add`

Tell git which files to include in the next commit.

```bash
git add file.txt              # Stage one file
git add *.js                  # Stage all .js files
git add -A                    # Stage everything (deleted, modified, new)
git add -p                    # Interactive — choose which changes to stage
```

### `git commit`

Create a permanent snapshot. The staging area becomes a commit in the repository.

```bash
git commit -m "feat: add user login"          # Commit with message
git commit -m "fix: handle null user" -a      # Stage everything + commit (shortcut)
git commit --amend                            # Fix the last commit's message/changes
```

**Commit messages that help future you:**

- **Describe why, not what**: `fix(api): handle null user header` is better than `fix header issue`
- **Use conventional types**: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `backlog`
- **One idea per commit**: if a commit touches unrelated things, split it
- **Format**: `type(scope): description` — e.g., `refactor: consolidate error handling`

### `git log`

View your history. This is where you'll spend most of your time looking back.

```bash
git log                         # Full history
git log --oneline               # One line per commit
git log --graph --oneline --all # Visual graph of branches and merges
git log --stat                  # Show file changes per commit
git log -n 5                    # Last 5 commits
git log --since="2 weeks ago"   # Time-filtered
git log --author="name"         # Filter by author
git log --follow <file>         # Trace a file across renames
```

**Pro tip**: `git log --oneline --graph --all --decorate` is your go-to for understanding where things are.

### `git push` / `git pull`

`git push` sends your commits to a remote (like GitHub). `git pull` fetches remote changes and merges them into your current branch.

```bash
git push origin main                    # Push to remote
git push -u origin feature/my-branch    # Push and set upstream tracking
git pull origin main                    # Fetch + merge remote changes
git pull --rebase origin main           # Fetch + rebase onto remote (cleaner history)
```

**Rebase vs merge when pulling:**
- **Merge**: creates a merge commit. Preserves history exactly. Can get messy with many merges.
- **Rebase**: rewinds your commits, fetches remote, replays your commits on top. Cleaner linear history. Loses the fact that a merge happened.

For personal feature branches, rebase is usually better. For shared branches that others are working on, merge is safer.

---

## 4. Branching — Your Primary Workflow

### Creating and switching branches

```bash
git branch feature/my-feature           # Create a new branch
git checkout feature/my-feature         # Switch to it
git checkout -b feature/my-feature      # Create + switch in one command
git branch                              # List all branches
```

### Branching strategy

**Default: main + feature branches**

```
main ──── main ──── main ──── main
        /          \
    feat-a        feat-b
```

1. Create `feature/<name>` off `main`
2. Work, commit, push on the feature branch
3. Merge back to `main` via PR or squash-merge when done
4. Delete the branch

**Escalate when**: multiple features need to be tested together, or integration testing is too risky on `main` directly.

**Escalated: main + develop + feature**

```
main ──── main ──── main
         /          \
    develop ─── develop ─── develop
       /   \       /
   feat-a feat-b feat-c
```

1. Create `develop` off `main` (once per integration cycle)
2. Feature branches from `develop`, not `main`
3. Merge features to `develop` as they complete
4. When all pass testing, merge `develop` to `main`
5. Delete `develop` — it's ephemeral

**Hotfixes: always off main**

```
main ──── main ──── main ──── main
              \
          hotfix-x
```

If something on `main` needs an immediate fix, branch off `main`, fix, test, merge back, delete.

### Never rebase main. Rebasing feature branches is fine when small and not shared.

---

## 5. Undo — When You Mess Up

Git is designed to be forgiving. Here's how to recover:

### "I staged the wrong file"

```bash
git reset HEAD file.txt    # Unstage a file (keep changes in working directory)
```

### "I committed with the wrong message"

```bash
git commit --amend          # Change the last commit's message (or add staged changes)
```

### "I committed too early / forgot something"

```bash
# Stage the missing changes, then:
git commit --amend --no-edit    # Amend without changing the message
```

### "I need to go back to a previous state"

```bash
git checkout HEAD~1    # Go back one commit (detached HEAD)
git checkout feature-branch    # Switch to a named branch
git checkout -           # Switch back to previous branch
```

### "I pushed bad commits and need to fix them"

```bash
git reset --hard HEAD~1    # Go back one commit (DESTROYS those commits)
git push --force           # Force push to remote (WARNING: overwrites remote)
```

**Force push is dangerous** — it rewrites history on the remote. Only use it on branches where you're the only contributor.

### "I need to undo a commit that others have pulled"

```bash
git revert <commit-hash>    # Create a new commit that undoes the changes
git push origin main        # Push the revert commit
```

`revert` creates a new commit (safe, no history rewrite). `reset --hard` destroys history (dangerous with shared branches).

---

## 6. Finding Things — Log and Search

### Find a commit by message

```bash
git log --all --grep="login" --oneline
```

### Find when a file was changed

```bash
git log --follow --diff-filter=A -- <file>   # When was it added?
git log -p -- <file>                          # Show changes to this file over time
```

### Find where a line of code was introduced

```bash
git blame file.py          # Show who changed each line
git blame -L 20,30 file.py # Lines 20-30 only
```

### Find commits that touched a specific file path

```bash
git log --all -- <path/to/file>
```

---

## 7. Remote Workflows

### Cloning a repository

```bash
git clone https://github.com/user/repo.git    # Clone and create remote tracking
cd repo
git pull origin main                           # Ensure you're up to date before starting work
```

### Setting up a local branch to track a remote branch

```bash
git checkout -b feature/main origin/main       # Create and track origin/main
```

### Fetching without merging

```bash
git fetch origin          # Download remote refs without merging
git log origin/main       # See what's on the remote
git pull origin main      # Fetch + merge in one command
```

### When you see "Your branch is behind"

```bash
git status                # Shows: "Your branch is behind 'origin/main' by X commits"
git pull origin main      # Fetch and merge the remote changes
# or
git pull --rebase origin main    # Fetch and rebase on top
```

---

## 8. Common Patterns and Anti-Patterns

### Do:

- Commit on logical boundaries (one idea per commit)
- Write commit messages that explain why
- Pull before pushing to avoid conflicts
- Use feature branches for anything non-trivial
- Keep `main` clean — it's production

### Don't:

- Commit secrets, credentials, or private keys
- Commit generated files (node_modules, build output, etc.) — use `.gitignore`
- Force push to shared branches
- Rebase `main`
- Commit partial work that doesn't compile or test
- Push without pulling first (causes conflicts)

---

## 9. The Commands Cheat Sheet

| Goal | Command |
|------|---------|
| Create new branch | `git checkout -b <name>` |
| Switch branches | `git checkout <name>` |
| List branches | `git branch` |
| Stage all changes | `git add -A` |
| Stage one file | `git add <file>` |
| Commit | `git commit -m "message"` |
| View history | `git log --oneline --graph --all --decorate` |
| See working tree changes | `git status` |
| See file-level changes | `git diff` |
| Push to remote | `git push origin <branch>` |
| Pull from remote | `git pull origin <branch>` |
| Undo last commit (keep changes) | `git reset HEAD~1` |
| Undo last commit (discard changes) | `git reset --hard HEAD~1` |
| Fix last commit message | `git commit --amend` |
| Revert a commit safely | `git revert <hash>` |
| See who changed each line | `git blame <file>` |
| Find a commit by message | `git log --all --grep="text" --oneline` |

---

## 10. Further Learning

- **Pro Git** (free online): [git-scm.com/book](https://git-scm.com/book) — the definitive reference
- **Oh Shit, Git?!:** [ohshitgit.com](https://ohshitgit.com/) — quick fixes for common git mistakes
- **Git Immersion:** [gitimmersion.com](https://gitimmersion.com/) — interactive tutorial
- **Learn Git Branching:** [learngitbranching.js.org](https://learngitbranching.js.org/) — visual branch visualization

---

*This guide is part of the devops learning path. It covers fundamentals; for project-specific git workflows, see the workspace's working style documentation.*
