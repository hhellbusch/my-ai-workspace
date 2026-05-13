#!/usr/bin/env bash
# litellm-quota.sh — Check remaining token quota on the OpenAI-compat LiteLLM endpoint.
#
# Usage:
#   litellm-quota.sh                 # one-shot check
#   litellm-quota.sh --watch [N]     # poll every N seconds (default: 60)
#
# Reads OPENAI_COMPAT_BASE_URL and OPENAI_COMPAT_API_KEY (or OPENAI_API_KEY).
# Uses a minimal 1-token request to read response headers without burning quota.

set -euo pipefail

BASE_URL="${OPENAI_COMPAT_BASE_URL:-${OPENAI_BASE_URL:-}}"
API_KEY="${OPENAI_COMPAT_API_KEY:-${OPENAI_API_KEY:-no-key}}"
MODEL="${OPENAI_COMPAT_QUOTA_MODEL:-Qwen3.6-35B-A3B}"
WATCH=false
INTERVAL=60

if [[ $# -gt 0 && "$1" == "--watch" ]]; then
  WATCH=true
  INTERVAL="${2:-60}"
fi

if [[ -z "$BASE_URL" ]]; then
  echo "Error: OPENAI_COMPAT_BASE_URL is not set." >&2
  exit 1
fi

check_quota() {
  local headers
  headers=$(curl -si -X POST "${BASE_URL}/chat/completions" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"${MODEL}\",\"messages\":[{\"role\":\"user\",\"content\":\".\"}],\"max_tokens\":1}" \
    2>/dev/null | head -40)

  local http_status reset_at rate_type retry_after key_spend error_msg
  http_status=$(echo "$headers" | grep -oP 'HTTP/1\.[01] \K[0-9]+' | tail -1)
  reset_at=$(echo "$headers" | grep -i "Reset_at:" | grep -oP 'Reset_at: \K.*' | tr -d '\r')
  rate_type=$(echo "$headers" | grep -i "Rate_limit_type:" | grep -oP 'Rate_limit_type: \K.*' | tr -d '\r')
  retry_after=$(echo "$headers" | grep -i "Retry-After:" | grep -oP 'Retry-After: \K[0-9]+' | tr -d '\r')
  key_spend=$(echo "$headers" | grep -i "X-Litellm-Key-Spend:" | grep -oP 'X-Litellm-Key-Spend: \K.*' | tr -d '\r')
  error_msg=$(echo "$headers" | grep -oP '"message":"\K[^"]+' | head -1)

  local now
  now=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

  echo "=== LiteLLM Quota — ${now} ==="
  echo "Endpoint : ${BASE_URL}"
  echo "Model    : ${MODEL}"
  echo "HTTP     : ${http_status:-unknown}"

  if [[ "$http_status" == "429" ]]; then
    echo "Status   : ⛔ RATE LIMITED"
    [[ -n "$rate_type" ]] && echo "Limit on : ${rate_type}"
    [[ -n "$reset_at" ]] && echo "Resets at: ${reset_at}"
    if [[ -n "$retry_after" ]]; then
      local reset_secs="$retry_after"
      local reset_min=$(( reset_secs / 60 ))
      local reset_sec=$(( reset_secs % 60 ))
      echo "Retry in : ${reset_min}m ${reset_sec}s"
    fi
    [[ -n "$error_msg" ]] && echo "Message  : ${error_msg}"
  elif [[ "$http_status" == "200" ]]; then
    echo "Status   : ✅ OK — quota available"
    [[ -n "$key_spend" ]] && echo "Spent    : \$${key_spend}"
  else
    echo "Status   : ⚠️  unexpected status ${http_status:-unknown}"
    [[ -n "$error_msg" ]] && echo "Message  : ${error_msg}"
  fi

  [[ -n "$key_spend" && "$http_status" != "200" ]] && echo "Spent    : \$${key_spend}"
  echo ""
}

if [[ "$WATCH" == "true" ]]; then
  echo "Watching every ${INTERVAL}s — Ctrl+C to stop"
  echo ""
  while true; do
    check_quota
    sleep "$INTERVAL"
  done
else
  check_quota
fi
