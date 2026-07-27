#!/usr/bin/env bash
# Check internal markdown links in devops/ and docs/.
# Excludes research sources, planning artifacts, and per-guide _meta/ process docs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f .gitmodules ] && git submodule status | grep -q '^-'; then
  git submodule update --init --recursive --depth 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

while IFS= read -r file; do
  links=$(perl -0777 -pe 's/```.*?```//gs' "$file" 2>/dev/null \
    | grep -oP '\]\(\K[^)]+(?=\))' \
    | grep -v '^https\?://' \
    | grep -v '^http' \
    | grep -v '^mailto:' || true)
  if [ -z "$links" ]; then
    continue
  fi
  while IFS= read -r link; do
    [ -z "$link" ] && continue
    dir=$(dirname "$file")
    target="${link%%#*}"
    [ -z "$target" ] && continue
    resolved=$(python3 -c "import os,sys; print(os.path.normpath(os.path.join(sys.argv[1], sys.argv[2])))" "$dir" "$target" 2>/dev/null)
    if [ ! -e "$resolved" ]; then
      echo "BROKEN: $file -> $link"
    fi
  done <<< "$links"
done < <(
  git ls-files 'devops/' 'docs/' \
    | grep '\.md$' \
    | grep -v '^research/.*/sources/' \
    | grep -v '/_meta/' \
    | grep -v '^\.planning/'
) | sort -u | tee "$tmp"

if [ -s "$tmp" ]; then
  echo "Link check failed ($(wc -l < "$tmp") broken links)."
  exit 1
fi

echo "Link check passed (devops/ and docs/, excluding _meta/)."
