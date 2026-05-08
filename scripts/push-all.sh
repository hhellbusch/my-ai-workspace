#!/usr/bin/env bash
set -euo pipefail

# push-all.sh — push all submodules to the correct remote branches, then push the parent repo.
#
# Submodules are normally in detached HEAD state (git checks out a pinned commit, not a branch).
# This script handles both cases:
#   - Attached (named branch): push to the tracked remote branch if ahead.
#   - Detached: check whether HEAD is already reachable from any remote branch.
#     If yes → clean, nothing to push. If no → orphaned local commits exist;
#     infer target branch from .gitmodules `branch =` or from the parent commit's
#     remote refs, then push. Warn and skip if the target is ambiguous.
#
# Auth: reads GH_TOKEN from the environment or sources /pvc/workspace/.env.
# Usage: ./scripts/push-all.sh [--dry-run]

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[push-all] DRY RUN — no pushes will be made"
fi

# --- auth ---
if [[ -z "${GH_TOKEN:-}" ]]; then
  if [[ -f "$WORKSPACE_ROOT/.env" ]]; then
    # shellcheck source=/dev/null
    source "$WORKSPACE_ROOT/.env"
  fi
fi
if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "[push-all] ERROR: GH_TOKEN is not set and .env was not found or did not export it." >&2
  exit 1
fi
echo "[push-all] token length: ${#GH_TOKEN}"

# Build an authenticated remote URL from an HTTPS origin URL.
# Handles both https://github.com/... and git@github.com:... forms.
authed_url() {
  local url="$1"
  # Strip any embedded credentials already in the URL
  url=$(echo "$url" | sed 's|https://[^@]*@|https://|')
  # Convert SSH to HTTPS
  url=$(echo "$url" | sed 's|git@github\.com:|https://github.com/|')
  # Inject token
  echo "$url" | sed "s|https://github.com/|https://x-access-token:${GH_TOKEN}@github.com/|"
}

# Resolve the branch a submodule should push to when in detached HEAD.
# Order: (1) .gitmodules `branch =` field, (2) remote branch(es) containing HEAD.
# Returns empty string if ambiguous.
infer_push_branch() {
  local subpath="$1"
  local subname="$2"

  # Check .gitmodules for an explicit branch setting
  local cfg_branch
  cfg_branch=$(git -C "$WORKSPACE_ROOT" config --file "$WORKSPACE_ROOT/.gitmodules" \
    "submodule.${subname}.branch" 2>/dev/null || true)
  if [[ -n "$cfg_branch" ]]; then
    echo "$cfg_branch"
    return
  fi

  # Fall back to remote branches that contain HEAD
  local branches
  branches=$(git -C "$subpath" branch -r --contains HEAD 2>/dev/null \
    | grep -v ' -> ' | sed 's|origin/||' | sed 's/^[[:space:]]*//' | sort -u)

  local count
  count=$(echo "$branches" | grep -c . 2>/dev/null || echo 0)

  if [[ "$count" -eq 1 ]]; then
    echo "$branches"
  else
    # Multiple or zero — can't safely pick one
    echo ""
  fi
}

cd "$WORKSPACE_ROOT"

PASS=0
SKIP=0
WARN=0

echo ""
echo "[push-all] checking submodules..."
echo ""

while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  subpath="$WORKSPACE_ROOT/$sub"
  subname=$(basename "$sub")

  echo "--- $subname ---"

  if [[ ! -d "$subpath/.git" && ! -f "$subpath/.git" ]]; then
    echo "  SKIP: not initialized"
    (( SKIP++ )) || true
    continue
  fi

  # Fetch to get up-to-date remote refs (quiet — we just need the ref data)
  git -C "$subpath" fetch --quiet 2>/dev/null || true

  branch=$(git -C "$subpath" branch --show-current 2>/dev/null || true)

  if [[ -n "$branch" ]]; then
    # Attached HEAD — check tracking branch
    tracking=$(git -C "$subpath" for-each-ref --format='%(upstream:short)' \
      "refs/heads/$branch" 2>/dev/null || true)

    if [[ -z "$tracking" ]]; then
      # Named branch but no upstream set — infer remote URL and push
      remote_url=$(git -C "$subpath" remote get-url origin 2>/dev/null || true)
      auth_url=$(authed_url "$remote_url")
      ahead=$(git -C "$subpath" log "origin/${branch}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$ahead" -eq 0 ]]; then
        echo "  OK: on branch '$branch', no unpushed commits"
        (( PASS++ )) || true
      else
        echo "  PUSH: on branch '$branch', $ahead unpushed commit(s) → origin/$branch"
        if [[ "$DRY_RUN" == false ]]; then
          git -C "$subpath" push "$auth_url" "HEAD:$branch"
        fi
        (( PASS++ )) || true
      fi
    else
      # Has tracking branch
      ahead=$(git -C "$subpath" log "${tracking}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$ahead" -eq 0 ]]; then
        echo "  OK: on branch '$branch' tracking '$tracking', up to date"
        (( PASS++ )) || true
      else
        remote_url=$(git -C "$subpath" remote get-url origin 2>/dev/null || true)
        auth_url=$(authed_url "$remote_url")
        echo "  PUSH: on branch '$branch', $ahead unpushed commit(s) → $tracking"
        if [[ "$DRY_RUN" == false ]]; then
          git -C "$subpath" push "$auth_url" "HEAD:$branch"
        fi
        (( PASS++ )) || true
      fi
    fi
  else
    # Detached HEAD — check if commit is reachable from any remote branch
    reachable=$(git -C "$subpath" branch -r --contains HEAD 2>/dev/null | grep -v ' -> ' || true)
    if [[ -n "$reachable" ]]; then
      branches_display=$(echo "$reachable" | sed 's/^[[:space:]]*//' | tr '\n' ' ')
      echo "  OK: detached HEAD already reachable from: $branches_display"
      (( PASS++ )) || true
    else
      # Orphaned commit — need to push somewhere
      target=$(infer_push_branch "$subpath" "$subname")
      if [[ -z "$target" ]]; then
        echo "  WARN: detached HEAD with unpushed commits — cannot infer target branch." >&2
        echo "        Run: cd submodules/$subname && git branch -r --contains HEAD" >&2
        echo "        Then: git push <remote-url> HEAD:<branch>" >&2
        (( WARN++ )) || true
      else
        remote_url=$(git -C "$subpath" remote get-url origin 2>/dev/null || true)
        auth_url=$(authed_url "$remote_url")
        echo "  PUSH: detached HEAD, orphaned commit → inferred branch '$target'"
        if [[ "$DRY_RUN" == false ]]; then
          git -C "$subpath" push "$auth_url" "HEAD:$target"
        fi
        (( PASS++ )) || true
      fi
    fi
  fi

  echo ""

done < <(git submodule foreach --quiet 'echo $sm_path' 2>/dev/null)

# --- parent repo ---
echo "--- parent repo ---"
parent_url=$(git remote get-url origin)
parent_auth=$(authed_url "$parent_url")
parent_branch=$(git branch --show-current)
ahead=$(git log "origin/${parent_branch}..HEAD" --oneline 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ahead" -eq 0 ]]; then
  echo "  OK: '$parent_branch' up to date"
  (( PASS++ )) || true
else
  echo "  PUSH: '$parent_branch', $ahead unpushed commit(s)"
  if [[ "$DRY_RUN" == false ]]; then
    git push "$parent_auth" "$parent_branch"
  fi
  (( PASS++ )) || true
fi

echo ""
echo "[push-all] done — passed: $PASS, skipped: $SKIP, warned: $WARN"
if [[ "$WARN" -gt 0 ]]; then
  echo "[push-all] $WARN submodule(s) need manual attention (see WARN lines above)"
  exit 1
fi
