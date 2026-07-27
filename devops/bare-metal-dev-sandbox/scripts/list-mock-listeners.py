#!/usr/bin/env python3
"""Print host:port endpoints that should have mock TCP listeners for a scenario."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def endpoints_from_extra(extra: dict) -> list[str]:
    mode = extra.get("preflight_validation_mode", "harness")
    checks = (
        extra.get("preflight_inputs", {})
        .get("network", {})
        .get("firewall_checks", [])
    )
    endpoints: list[str] = []

    for check in checks:
        targets = check.get("targets") or []
        if mode == "harness":
            # Back-compat: start listeners for state:open (optional visual; probes still simulated)
            if check.get("state") != "open":
                continue
        elif mode in ("hybrid", "live"):
            if not check.get("mock_listener", False):
                continue
        else:
            continue

        for target in targets:
            host = target.get("host")
            port = target.get("port")
            if host and port:
                endpoints.append(f"{host}:{port}")

    return endpoints


def main() -> int:
    extra_path = Path(sys.argv[1])
    extra = json.loads(extra_path.read_text())
    for endpoint in endpoints_from_extra(extra):
        print(endpoint)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
