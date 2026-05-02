#!/usr/bin/env bash
# PostToolUse hook: runs after Write or StrReplace on .py files.
# Checks AST integrity and prints the top-level function inventory so
# silent deletions surface immediately rather than at commit time.
set -euo pipefail

INPUT=$(cat)

# Extract the file path from tool_input (works for both Write and StrReplace)
FILE_PATH=$(python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('path', ''))
" <<< "$INPUT" 2>/dev/null || echo "")

# Only process .py files
[[ "$FILE_PATH" == *.py ]] || exit 0
[[ -n "$FILE_PATH" ]] || exit 0

# Resolve relative path
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="${CLAUDE_PROJECT_DIR:-$(pwd)}/$FILE_PATH"
fi

[[ -f "$FILE_PATH" ]] || exit 0

SYNTAX_OK=true
SYNTAX_MSG=""

# Check 1: AST parse
if ! python3 -c "import ast; ast.parse(open('$FILE_PATH').read())" 2>/tmp/py_ast_err; then
  SYNTAX_OK=false
  SYNTAX_MSG=$(cat /tmp/py_ast_err)
fi

# Check 2: top-level function inventory
DEF_LIST=$(grep -n "^def " "$FILE_PATH" 2>/dev/null || echo "(none)")
DEF_COUNT=$(echo "$DEF_LIST" | grep -c "^" || echo 0)

# Build the context message
if [[ "$SYNTAX_OK" == false ]]; then
  CONTEXT="⚠ SYNTAX ERROR in $FILE_PATH — fix before git add.\n$SYNTAX_MSG\nTop-level defs ($DEF_COUNT):\n$DEF_LIST"
else
  CONTEXT="Python edit OK — $FILE_PATH\nTop-level defs ($DEF_COUNT):\n$DEF_LIST"
fi

python3 -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': msg
  }
}))
" "$CONTEXT"
