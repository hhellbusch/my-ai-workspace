#!/usr/bin/env bash
# Point this clone at tracked hooks under .githooks/ (local config only).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/pre-commit

git config core.hooksPath .githooks

echo "Installed git hooks from .githooks/ (core.hooksPath=.githooks for this repo)."
echo "Pre-commit runs review-frontmatter on staged devops/docs markdown and link check."
echo "Bypass once: git commit --no-verify"
echo "Skip link check: SKIP_LINK_CHECK=1 git commit"
