#!/usr/bin/env bash
set -euo pipefail

# Sync shared command bodies from .commands/ into platform wrappers.
#
# Source of truth: .commands/*.md (body only, no frontmatter)
# Wrappers:       .cursor/commands/*.md, .claude/commands/*.md
#                 (YAML frontmatter + <!-- body: --> marker + body)
#
# The script preserves each wrapper's frontmatter and replaces
# everything after the <!-- body: --> marker with the current
# .commands/ content. Wrappers without a body marker are skipped
# (Cursor-only commands that have no shared body).

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="$REPO_ROOT/.commands"
CURSOR_DIR="$REPO_ROOT/.cursor/commands"
CLAUDE_DIR="$REPO_ROOT/.claude/commands"

changed=0
errors=0

sync_wrapper() {
    local wrapper="$1"
    local body_src="$2"
    local name="$3"
    local platform="$4"

    if [[ ! -f "$wrapper" ]]; then
        echo "  SKIP  $platform/$name (no wrapper — create manually with frontmatter)"
        return
    fi

    if ! grep -q '<!-- body:' "$wrapper"; then
        echo "  SKIP  $platform/$name (no body marker — not a shared command)"
        return
    fi

    local marker_line
    marker_line=$(grep -n '<!-- body:' "$wrapper" | head -1 | cut -d: -f1)

    local head_content
    head_content=$(head -n "$marker_line" "$wrapper")

    local new_content
    new_content="$head_content
$(cat "$body_src")"

    if diff -q <(echo "$new_content") "$wrapper" > /dev/null 2>&1; then
        echo "  OK    $platform/$name (up to date)"
        return
    fi

    echo "$new_content" > "$wrapper"
    echo "  SYNC  $platform/$name"
    ((changed++)) || true
}

echo "Syncing .commands/ → platform wrappers..."
echo ""

for body_file in "$COMMANDS_DIR"/*.md; do
    name=$(basename "$body_file")
    echo "$name:"
    sync_wrapper "$CURSOR_DIR/$name" "$body_file" "$name" ".cursor/commands"
    sync_wrapper "$CLAUDE_DIR/$name" "$body_file" "$name" ".claude/commands"
done

echo ""
if (( changed > 0 )); then
    echo "Updated $changed wrapper(s). Review with: git diff .cursor/commands .claude/commands"
else
    echo "All wrappers up to date."
fi

if (( errors > 0 )); then
    echo "$errors error(s) — see above."
    exit 1
fi
