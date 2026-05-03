#!/usr/bin/env bash
# Smoke-test an OpenAI-compatible server (RamaLama, vLLM, Ollama /v1, etc.).
# Usage:
#   OPENAI_BASE_URL=http://127.0.0.1:8080/v1 ./scripts/smoke-local-openai-api.sh
#   ./scripts/smoke-local-openai-api.sh http://llm.lan:8080/v1
set -euo pipefail

base="${1:-${OPENAI_BASE_URL:-}}"
if [[ -z "${base}" ]]; then
  echo "usage: OPENAI_BASE_URL=http://host:port/v1 $0" >&2
  echo "   or: $0 http://host:port/v1" >&2
  exit 1
fi

# Normalize: strip trailing slashes, ensure /v1 style path works with /models
base="${base%/}"
url="${base}/models"

echo "GET ${url}" >&2
exec curl -fsS "${url}"
