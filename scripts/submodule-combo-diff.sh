#!/usr/bin/env bash
# combo-diff.sh — Diff across root + all submodules, using git tags
#
# Usage:
#   scripts/submodule-combo-diff.sh <tag-from> <tag-to>
#   scripts/submodule-combo-diff.sh <commit-from> <commit-to>
#   scripts/submodule-combo-diff.sh --today          # today's tag vs yesterday's
#   scripts/submodule-combo-diff.sh --between        # last two tags
#   scripts/submodule-combo-diff.sh --summary        # summary table of all tags
#
# Examples:
#   scripts/submodule-combo-diff.sh v2026-05-13 v2026-05-19
#   scripts/submodule-combo-diff.sh --today
#   scripts/submodule-combo-diff.sh --between

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# ── Resolve submodule commit hash at a given root ref ────
# Uses git ls-tree on the root repo's tree at the given ref.
submodule_hash_at() {
  local path="$1"
  local ref="$2"
  git ls-tree -r "${ref}" -- "${path}" 2>/dev/null | awk '{print $3}' | head -1
}

# ── Build module list: prints "name\tpath" per module ────
# Reads .gitmodules and produces stable name/path pairs.
get_submodules() {
  if [[ ! -f .gitmodules ]]; then return; fi

  local current_name="" current_path=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^\[submodule\ \"(.+)\"\] ]]; then
      # Emit previous module if we have both
      if [[ -n "$current_name" && -n "$current_path" ]]; then
        printf "%s\t%s\n" "$current_name" "$current_path"
      fi
      current_name="${BASH_REMATCH[1]}"
      current_path=""
    elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.+) ]]; then
      current_path="${BASH_REMATCH[1]}"
    fi
  done < .gitmodules

  # Emit last module
  if [[ -n "$current_name" && -n "$current_path" ]]; then
    printf "%s\t%s\n" "$current_name" "$current_path"
  fi
}

# ── Mode: --today ────────────────────────────────────────

do_today() {
  local today
  today=$(date +%Y-%m-%d)
  local today_tag="v${today}"

  if ! git tag -l "$today_tag" >/dev/null 2>&1; then
    echo "No tag for today ($today_tag)"
    return 1
  fi

  # Find yesterday's tag (most recent tag before today)
  local yesterday_tag=""
  while IFS= read -r t; do
    local d="${t#v}"
    if [[ "$d" < "$today" ]]; then
      yesterday_tag="$t"
      break
    fi
  done < <(git tag -l 'v*' --sort=-creatordate)

  if [[ -z "$yesterday_tag" ]]; then
    echo "No prior tag found"
    return 1
  fi

  do_diff "$yesterday_tag" "$today_tag"
}

# ── Mode: --between ─────────────────────────────────────

do_between() {
  local tags=()
  while IFS= read -r t; do tags+=("$t"); done < <(git tag -l 'v*' --sort=-creatordate)

  if [[ ${#tags[@]} -lt 2 ]]; then
    echo "Only ${#tags[@]} tag(s) found — need at least 2"
    return 1
  fi
  do_diff "${tags[1]}" "${tags[0]}"
}

# ── Mode: --summary ─────────────────────────────────────

do_summary() {
  echo "=== Tag Summary ==="
  echo ""
  printf "%-16s  %-10s  %s\n" "Tag" "Root" "Submodules"
  printf "%-16s  %-10s  %s\n" "---" "----" "----------"

  local prev=""
  while IFS= read -r tag; do
    if [[ -z "$prev" ]]; then
      prev="$tag"
      continue
    fi

    # Root stats
    local root_stats
    root_stats=$(git diff --shortstat "$prev..$tag" 2>/dev/null || true)

    # Submodule commit counts (resolve via root tree at each tag)
    local submod_detail=""
    while IFS=$'\t' read -r name path; do
      local hash_from hash_to
      hash_from=$(submodule_hash_at "$path" "$prev")
      hash_to=$(submodule_hash_at "$path" "$tag")

      if [[ -n "$hash_from" && -n "$hash_to" && "$hash_from" != "$hash_to" ]]; then
        local count
        count=$(git -C "$path" log --oneline "${hash_from}..${hash_to}" 2>/dev/null | wc -l)
        if [[ "$count" -gt 0 ]]; then
          submod_detail+=" ${name}($count)"
        fi
      fi
    done < <(get_submodules)

    local root_ins root_del
    root_ins=$(echo "$root_stats" | grep -oP '\d+\s+insertion' || echo "")
    root_del=$(echo "$root_stats" | grep -oP '\d+\s+deletion' || echo "")

    printf "%-16s  %-10s  %s\n" "$tag" "$root_ins $root_del" "$submod_detail"

    prev="$tag"
  done < <(git tag -l 'v*' --sort=-creatordate | tac)
}

# ── Mode: diff between two refs ─────────────────────────

do_diff() {
  local from="$1"
  local to="$2"

  # Validate refs
  if ! git rev-parse --verify "$from" >/dev/null 2>&1; then
    echo "Error: cannot resolve '$from'" >&2
    return 1
  fi

  if ! git rev-parse --verify "$to" >/dev/null 2>&1; then
    echo "Error: cannot resolve '$to'" >&2
    return 1
  fi

  echo "=== Diff: $from → $to ==="
  echo ""

  # ── Root repo ──
  local root_count root_files
  root_count=$(git diff --stat "$from..$to" 2>/dev/null | tail -1 || echo "0 files changed, 0 insertions(+), 0 deletions(-)")
  root_files=$(git diff --stat --name-only "$from..$to" 2>/dev/null | wc -l)

  if [[ "$root_files" -gt 0 ]]; then
    echo "── ROOT ($root_count) ─────────────────────────────────"
    # Show file tree grouping (exclude .git, submodules dir)
    git diff --stat --name-only "$from..$to" 2>/dev/null | \
      grep -v '^submodules/' | \
      awk -F/ '{print $1}' | sort | uniq -c | sort -rn | \
      while read -r count dir; do
        [[ -z "$dir" ]] && continue
        printf "  %-20s %3d files\n" "${dir}/" "$count"
      done

    # Show submodule pointer bumps
    local sub_bumps
    sub_bumps=$(git diff --name-only "$from..$to" 2>/dev/null | grep '^submodules/' || true)
    if [[ -n "$sub_bumps" ]]; then
      echo ""
      echo "── Module bumps ──"
      while IFS= read -r bump; do
        local sub_name
        sub_name=$(basename "$bump")
        printf "  %s\n" "$sub_name"
      done <<< "$sub_bumps"
    fi
    echo ""
  fi

  # ── Submodules ──
  local has_any_sub=false
  while IFS=$'\t' read -r name path; do
    # Resolve the submodule commit hash at each ref from root's tree
    local from_commit to_commit
    from_commit=$(submodule_hash_at "$path" "$from")
    to_commit=$(submodule_hash_at "$path" "$to")

    # If same hash or couldn't resolve, skip
    if [[ -z "$from_commit" || -z "$to_commit" || "$from_commit" == "$to_commit" ]]; then
      continue
    fi

    local sub_commits
    sub_commits=$(git -C "$path" log --oneline --no-merges "${from_commit}..${to_commit}" 2>/dev/null | wc -l)

    if [[ "$sub_commits" -gt 0 ]]; then
      if ! $has_any_sub; then
        echo ""
        has_any_sub=true
      fi
      echo "── $name ($sub_commits commits) ───────────────────────"
      git -C "$path" log --oneline --no-merges "${from_commit}..${to_commit}" 2>/dev/null | head -20
      if [[ "$sub_commits" -gt 20 ]]; then
        echo "  ... and $((sub_commits - 20)) more"
      fi
    fi
  done < <(get_submodules)

  if ! $has_any_sub; then
    echo ""
    echo "── No submodule changes between these refs ──"
  fi
}

# ── Main ─────────────────────────────────────────────────

case "${1:-}" in
  --today)
    do_today
    ;;
  --between)
    do_between
    ;;
  --summary)
    do_summary
    ;;
  *)
    if [[ $# -lt 2 ]]; then
      echo "Usage: $0 <tag-from> <tag-to>"
      echo "       $0 --today          (today vs yesterday's tag)"
      echo "       $0 --between        (last two tags)"
      echo "       $0 --summary        (table of all tag diffs)"
      echo ""
      echo "Tags: $(git tag -l 'v*' --sort=-creatordate | head -10 | tr '\n' ' ')"
      exit 1
    fi
    do_diff "$1" "$2"
    ;;
esac
