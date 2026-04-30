#!/usr/bin/env bash
set -euo pipefail

# audit-library-gaps.sh
#
# Scans research/ directories and library/ entries for structural gaps:
#   1. Research directories with no library/log.md entry (orphaned sources)
#   2. Library entry files with no corresponding log.md entry (silent additions)
#
# Usage:
#   ./scripts/audit-library-gaps.sh           # report gaps
#   ./scripts/audit-library-gaps.sh --verbose  # show matched entries too
#
# Exit code 0 = no gaps found. Exit code 1 = gaps found.

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$WORKSPACE_DIR/library/log.md"
RESEARCH_DIR="$WORKSPACE_DIR/research"
LIBRARY_DIR="$WORKSPACE_DIR/library"

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

gaps_found=0

echo "=== audit-library-gaps ==="
echo "Workspace: $WORKSPACE_DIR"
echo ""

# ─── Check 1: Research directories with no log.md entry ───────────────────────
echo "── Check 1: Research directories → library/log.md ──"

while IFS= read -r -d '' dir; do
  slug=$(basename "$dir")

  # Honour .library-exempt marker — directory is internal infrastructure, not a source
  if [[ -f "$dir/.library-exempt" ]]; then
    $VERBOSE && echo "  – research/$slug/ (exempt)"
    continue
  fi

  if grep -q "$slug" "$LOG_FILE" 2>/dev/null; then
    $VERBOSE && echo "  ✓ research/$slug/"
  else
    echo "  ✗ GAP: research/$slug/ — not referenced in library/log.md"
    # Show what's in sources/ to hint what needs logging
    if [[ -d "$dir/sources" ]] && [[ -n "$(ls -A "$dir/sources" 2>/dev/null)" ]]; then
      ls "$dir/sources/" | sed 's/^/      source: /'
    elif [[ -d "$dir" ]]; then
      ls "$dir/" | head -5 | sed 's/^/      file: /'
    fi
    gaps_found=$((gaps_found + 1))
  fi
done < <(find "$RESEARCH_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

echo ""

# ─── Check 2: Library entry files with no log.md entry ────────────────────────
echo "── Check 2: Library entry files → library/log.md ──"

SKIP_FILES=("README.md" "catalog.md" "log.md")

while IFS= read -r -d '' file; do
  filename=$(basename "$file")

  # Skip infrastructure files
  skip=false
  for skip_file in "${SKIP_FILES[@]}"; do
    [[ "$filename" == "$skip_file" ]] && skip=true && break
  done
  $skip && continue

  stem="${filename%.md}"

  if grep -q "$stem" "$LOG_FILE" 2>/dev/null; then
    $VERBOSE && echo "  ✓ library/$filename"
  else
    echo "  ✗ GAP: library/$filename — not referenced in library/log.md"
    gaps_found=$((gaps_found + 1))
  fi
done < <(find "$LIBRARY_DIR" -maxdepth 1 -name "*.md" -print0 | sort -z)

echo ""

# ─── Summary ──────────────────────────────────────────────────────────────────
if [[ $gaps_found -eq 0 ]]; then
  echo "✓ No gaps found."
  exit 0
else
  echo "✗ $gaps_found gap(s) found. Each research directory should have at least one"
  echo "  library/log.md entry referencing it. Each library/*.md should appear in log.md."
  echo ""
  echo "  To add a missing entry, append to library/log.md:"
  echo "    ## [YYYY-MM-DD] ingest | Title"
  echo "    - **Entry:** [filename.md](filename.md)"
  echo "    - **Wing:** {wing}"
  echo "    - **Source:** {type} / research/{slug}/sources/"
  exit 1
fi
