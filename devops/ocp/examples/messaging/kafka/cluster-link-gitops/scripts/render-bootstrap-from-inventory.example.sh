#!/usr/bin/env bash
# Render comma-separated bootstrapEndpoint from rollout inventory (static broker IPs).
# Usage: render-bootstrap-from-inventory.example.sh <inventory.yaml> [replicationPort]
#
# Requires: python3 + PyYAML (same as render-config.py) or yq v4.
# Example output: 10.200.1.21:9095,10.200.1.22:9095,10.200.1.23:9095

set -euo pipefail

inventory="${1:?inventory yaml path required}"
port="${2:-9095}"

if command -v yq >/dev/null 2>&1; then
  mode="$(yq -r '.workload.brokerIpam.mode // "whereabouts"' "$inventory")"
  if [[ "$mode" != "static" ]]; then
    echo "render-bootstrap-from-inventory: workload.brokerIpam.mode must be static (got ${mode})" >&2
    echo "For whereabouts, collect REPLICATION IPs after brokers attach to Multus — see BROKER-IPAM.md" >&2
    exit 1
  fi
  yq -r ".workload.brokers[] | .replIp + \":${port}\"" "$inventory" | paste -sd, -
  exit 0
fi

python3 - "$inventory" "$port" <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Missing PyYAML — install python3-pyyaml or use yq", file=sys.stderr)
    sys.exit(1)

inv_path = Path(sys.argv[1])
port = sys.argv[2]
inv = yaml.safe_load(inv_path.read_text(encoding="utf-8"))
wl = inv.get("workload", {})
mode = wl.get("brokerIpam", {}).get("mode", "whereabouts")
if mode != "static":
    print(
        f"render-bootstrap-from-inventory: workload.brokerIpam.mode must be static (got {mode})",
        file=sys.stderr,
    )
    print("For whereabouts, collect REPLICATION IPs after brokers attach — see BROKER-IPAM.md", file=sys.stderr)
    sys.exit(1)
brokers = wl.get("brokers") or []
if not brokers:
    print("render-bootstrap-from-inventory: workload.brokers is empty", file=sys.stderr)
    sys.exit(1)
print(",".join(f"{b['replIp']}:{port}" for b in brokers))
PY
