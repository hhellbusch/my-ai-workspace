#!/usr/bin/env bash
set -euo pipefail

# env-check.sh - fast bootstrap diagnostics for this workspace

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_ok() {
  printf '[OK]   %-18s %s\n' "$1" "$2"
}

print_warn() {
  printf '[WARN] %-18s %s\n' "$1" "$2"
}

print_err() {
  printf '[ERR]  %-18s %s\n' "$1" "$2"
}

check_cmd() {
  local label="$1"
  local cmd="$2"
  local hint="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$("$cmd" --version 2>/dev/null | head -n 1 || true)"
    print_ok "$label" "${version:-installed}"
  else
    print_err "$label" "$hint"
  fi
}

echo "Workspace: $workspace_root"
echo

check_cmd "git" "git" "Install git from your distro package manager."
check_cmd "podman" "podman" "Install podman (or docker) for paude container runtime."
check_cmd "uv" "uv" "Install uv: https://docs.astral.sh/uv/getting-started/installation/"
check_cmd "paude" "paude" "Install from local fork: uv tool install --editable \"$workspace_root/submodules/paude\""
check_cmd "gcloud" "gcloud" "Install Google Cloud CLI: https://cloud.google.com/sdk/docs/install"

if command -v pi >/dev/null 2>&1; then
  print_ok "pi" "$(pi --version 2>/dev/null | head -n 1 || echo "installed")"
else
  print_warn "pi" "Not installed. Needed only for local pi CLI use (paude installs agent in container)."
fi

if [[ -d "$workspace_root/submodules" ]]; then
  total_submodules="$(git -C "$workspace_root" config --file .gitmodules --get-regexp path | wc -l | tr -d ' ')"
  if [[ "$total_submodules" -gt 0 ]]; then
    missing_submodules="$(git -C "$workspace_root" submodule status | grep -c '^-')"
    ready_submodules="$((total_submodules - missing_submodules))"
    if [[ "$missing_submodules" -eq 0 ]]; then
      print_ok "submodules" "$ready_submodules/$total_submodules initialized"
    else
      print_warn "submodules" "$ready_submodules/$total_submodules initialized. Run: git submodule update --init"
    fi
  fi
fi

if command -v gcloud >/dev/null 2>&1; then
  if gcloud auth application-default print-access-token >/dev/null 2>&1; then
    print_ok "gcloud ADC" "configured"
  else
    print_warn "gcloud ADC" "not configured. Run: gcloud auth application-default login"
  fi
fi
