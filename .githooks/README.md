# Git hooks (optional)

Tracked hooks for this repository. Git does not use this directory until you install it locally.

## Install (once per clone)

```bash
bash scripts/install-githooks.sh
```

That sets `core.hooksPath` to `.githooks` for **this repo only** (local git config).

## Pre-commit

When a commit stages `devops/` or `docs/` markdown (or the markdown check scripts), the hook runs:

1. `python3 scripts/check-review-frontmatter.py --staged`
2. `bash scripts/check-markdown-links.sh` (full tree — same as CI)

If the commit has no scoped markdown, the hook exits immediately.

### Bypass

| Goal | Command |
|------|---------|
| Skip all hooks once | `git commit --no-verify` |
| Skip entire pre-commit | `SKIP_PRE_COMMIT=1 git commit` |
| Skip link check only | `SKIP_LINK_CHECK=1 git commit` |

CI still runs both checks on pull requests and pushes to `main`.

## Uninstall

```bash
git config --unset core.hooksPath
```
