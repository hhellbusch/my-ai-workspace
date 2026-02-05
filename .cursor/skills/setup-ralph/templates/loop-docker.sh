#!/bin/bash
# Ralph Docker Loop
# Runs Claude in isolated container, backup/git runs on HOST

set -e

# Configuration
IMAGE_NAME="ralph-loop"
PROJECT_DIR="$(pwd)"
PROJECT_NAME=$(basename "$PROJECT_DIR")
BACKUP_ENABLED="${RALPH_BACKUP:-true}"
MODEL="${RALPH_MODEL:-opus}"

# Validate model against whitelist (security: prevents command injection)
validate_model() {
  local model="$1"
  case "$model" in
    opus|sonnet|haiku) return 0 ;;
    *)
      echo "Error: Invalid model '$model'. Allowed: opus, sonnet, haiku"
      exit 1
      ;;
  esac
}
validate_model "$MODEL"
PLAN_FILE="IMPLEMENTATION_PLAN.md"
LOG_FILE="ralph.log"

# SAFETY: Verify PROJECT_DIR is safe to mount
if [ -z "$PROJECT_DIR" ] || [ "$PROJECT_DIR" = "/" ] || [ "$PROJECT_DIR" = "$HOME" ]; then
  echo "FATAL: Refusing to mount unsafe directory: $PROJECT_DIR"
  echo "Run this script from inside a project directory, not ~ or /"
  exit 1
fi

# Verify we're in a Ralph project
if [ ! -f "PROMPT_build.md" ] && [ ! -f "PROMPT_plan.md" ]; then
  echo "FATAL: Not a Ralph project directory (no PROMPT_*.md files)"
  echo "Run /setup-ralph first or cd into a Ralph project"
  exit 1
fi

# Load OAuth token (with security checks)
TOKEN_FILE="$HOME/.claude-oauth-token"
if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
  if [ -f "$TOKEN_FILE" ]; then
    # Security: Check file permissions (should be 600 or more restrictive)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      TOKEN_PERMS=$(stat -f %Lp "$TOKEN_FILE" 2>/dev/null)
    else
      TOKEN_PERMS=$(stat -c %a "$TOKEN_FILE" 2>/dev/null)
    fi

    if [ -n "$TOKEN_PERMS" ] && [ "$((TOKEN_PERMS % 100))" -ne 0 ]; then
      echo "⚠️  Security warning: $TOKEN_FILE has insecure permissions ($TOKEN_PERMS)"
      echo "   Run: chmod 600 $TOKEN_FILE"
      echo ""
    fi

    CLAUDE_CODE_OAUTH_TOKEN=$(cat "$TOKEN_FILE")
  else
    echo "Error: No OAuth token found"
    echo "Run 'claude setup-token' and save to ~/.claude-oauth-token"
    echo "Then: chmod 600 ~/.claude-oauth-token"
    exit 1
  fi
fi

# Handle --build-image flag
if [ "$1" = "--build-image" ]; then
  echo "Building Docker image..."
  docker build -t "$IMAGE_NAME" .
  echo "Image built: $IMAGE_NAME"
  exit 0
fi

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "Docker image not found. Building..."
  docker build -t "$IMAGE_NAME" .
fi

# Parse arguments
MODE="build"
LIMIT=""
while [[ $# -gt 0 ]]; do
  case $1 in
    plan) MODE="plan"; shift ;;
    [0-9]*) LIMIT=$1; shift ;;
    --model) MODEL=$2; validate_model "$MODEL"; shift 2 ;;
    *) shift ;;
  esac
done

# ============================================================================
# REMOTE BACKUP (runs on HOST with your gh auth)
# ============================================================================

setup_remote_backup() {
  if [ "$BACKUP_ENABLED" != "true" ]; then
    echo "Remote backup: disabled (set RALPH_BACKUP=true to enable)"
    return 0
  fi

  if [ ! -d ".git" ]; then
    echo "Initializing git..."
    git init
    git add -A
    git commit -m "Initial commit" 2>/dev/null || true
  fi

  if git remote get-url origin &>/dev/null; then
    echo "Remote backup: $(git remote get-url origin)"
    return 0
  fi

  if ! command -v gh &>/dev/null; then
    echo "Warning: gh CLI not found. Backup disabled."
    BACKUP_ENABLED="false"
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    echo "Warning: gh not authenticated. Backup disabled."
    BACKUP_ENABLED="false"
    return 1
  fi

  local repo_name="${PROJECT_NAME}-ralph-backup"
  echo "Creating private backup: $repo_name"

  if gh repo create "$repo_name" --private --source=. --push 2>/dev/null; then
    echo "Remote backup: https://github.com/$(gh api user -q .login)/$repo_name"
  else
    echo "Warning: Could not create repo. Backup disabled."
    BACKUP_ENABLED="false"
  fi
}

push_to_backup() {
  if [ "$BACKUP_ENABLED" = "true" ]; then
    git add -A 2>/dev/null || true
    git diff --quiet HEAD 2>/dev/null || git commit -m "Auto-save after iteration $ITERATION" 2>/dev/null || true
    git push origin HEAD 2>/dev/null && echo "Pushed to backup" || echo "Push failed (continuing)"
  fi
}

# ============================================================================
# COMPLETION DETECTION (runs on HOST)
# ============================================================================

check_complete() {
  if [ ! -f "$PLAN_FILE" ]; then
    return 1
  fi

  local incomplete=$(grep -c '^\s*- \[ \]' "$PLAN_FILE" 2>/dev/null || echo "0")
  if [ "$incomplete" -eq 0 ]; then
    local completed=$(grep -c '^\s*- \[x\]' "$PLAN_FILE" 2>/dev/null || echo "0")
    [ "$completed" -gt 0 ] && return 0
  fi
  return 1
}

# ============================================================================
# MAIN
# ============================================================================

# Select prompt
if [ "$MODE" = "plan" ]; then
  PROMPT_FILE="PROMPT_plan.md"
  echo "Ralph Planning Mode (Docker)"
else
  PROMPT_FILE="PROMPT_build.md"
  echo "Ralph Building Mode (Docker)"
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: $PROMPT_FILE not found"
  exit 1
fi

echo "Project: $PROJECT_DIR"
echo "Model: $MODEL"
[ -n "$LIMIT" ] && echo "Limit: $LIMIT" || echo "Limit: until complete"
echo ""

setup_remote_backup
echo ""
echo "Starting loop..."
echo "---"

echo "=== Ralph Docker $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"

ITERATION=0
while true; do
  ITERATION=$((ITERATION + 1))

  echo ""
  echo "Iteration $ITERATION - $(date '+%H:%M:%S')"

  # Check completion (build mode only)
  if [ "$MODE" = "build" ] && check_complete; then
    echo "ALL TASKS COMPLETE"
    push_to_backup
    exit 0
  fi

  # Check limit
  if [ -n "$LIMIT" ] && [ "$ITERATION" -gt "$LIMIT" ]; then
    echo "Reached limit ($LIMIT)"
    push_to_backup
    exit 0
  fi

  # Run single iteration in Docker
  # Container runs ONE iteration, then exits
  # Backup runs on HOST after container exits
  # Note: MODEL is already validated against whitelist above
  if docker run --rm \
    -v "$PROJECT_DIR:/workspace" \
    -w /workspace \
    -e "CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_CODE_OAUTH_TOKEN" \
    "$IMAGE_NAME" \
    bash -c "cat '$PROMPT_FILE' | claude --model '$MODEL' -p --dangerously-skip-permissions --output-format text" \
    2>&1 | tee -a "$LOG_FILE"; then

    echo "Iteration $ITERATION complete"

    # Push to backup ON HOST (has gh auth)
    push_to_backup
  else
    echo "Claude exited with error"
    push_to_backup
    exit 1
  fi

  sleep 1
done
