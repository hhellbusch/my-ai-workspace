#!/usr/bin/env bash
set -euo pipefail

# new-work-branch.sh - create/switch to a branch using workspace conventions
#
# Usage:
#   ./scripts/new-work-branch.sh <type> <topic> [--from <base-branch>]
# Example:
#   ./scripts/new-work-branch.sh docs paude-bootstrap-guide

usage() {
  cat <<'EOF'
Usage:
  ./scripts/new-work-branch.sh <type> <topic> [--from <base-branch>]

Allowed types:
  feature | experiment | docs | fix

Examples:
  ./scripts/new-work-branch.sh docs paude-bootstrap-guide
  ./scripts/new-work-branch.sh feature env-check-enhancements --from main
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

type="$1"
topic="$2"
shift 2

base_branch="main"
if [[ $# -gt 0 ]]; then
  if [[ "${1:-}" != "--from" || $# -ne 2 ]]; then
    echo "Invalid arguments."
    usage
    exit 1
  fi
  base_branch="$2"
fi

case "$type" in
  feature|experiment|docs|fix) ;;
  *)
    echo "Invalid type: $type"
    echo "Allowed types: feature | experiment | docs | fix"
    exit 1
    ;;
esac

if [[ ! "$topic" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Invalid topic: $topic"
  echo "Topic must be kebab-case (lowercase letters, numbers, dashes)."
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "Not inside a git repository."
  exit 1
fi

cd "$repo_root"

if ! git show-ref --verify --quiet "refs/heads/$base_branch"; then
  echo "Base branch '$base_branch' not found locally."
  exit 1
fi

branch_name="$type/$topic"

if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  git switch "$branch_name"
  echo "Switched to existing branch: $branch_name"
  exit 0
fi

git switch "$base_branch" >/dev/null
git switch -c "$branch_name"
echo "Created and switched to: $branch_name (from $base_branch)"
