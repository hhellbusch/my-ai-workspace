#!/usr/bin/env python3
"""Merge a live preflight config with environment secrets and emit Ansible extra-vars."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

PLACEHOLDER_MARKERS = (
    "FROM_ENV",
    "BMC_IP",
    "BOOTSTRAP",
    "NODE_IP",
    "PLACEHOLDER",
)


def looks_like_placeholder(value: str) -> bool:
    upper = value.upper()
    return any(marker in upper for marker in PLACEHOLDER_MARKERS)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path, help="Live vars JSON (see examples/)")
    parser.add_argument("--report", type=Path, required=True, help="preflight_report_path")
    parser.add_argument("-o", "--output", type=Path, help="Write merged JSON here")
    args = parser.parse_args()

    if not args.config.is_file():
        print(f"error: config not found: {args.config}", file=sys.stderr)
        return 1

    data = json.loads(args.config.read_text())
    if not isinstance(data, dict):
        print("error: config root must be a JSON object", file=sys.stderr)
        return 1

    data["preflight_validation_mode"] = "live"
    data["preflight_report_path"] = str(args.report)

    inputs = data.setdefault("preflight_inputs", {})
    creds = inputs.setdefault("bmc", {}).setdefault("credentials", {})

    env_user = os.environ.get("BMC_USERNAME") or os.environ.get("BMC_USER")
    env_pass = os.environ.get("BMC_PASSWORD")
    if env_user:
        creds["username"] = env_user
    if env_pass:
        creds["password"] = env_pass

    username = (creds.get("username") or "").strip()
    password = creds.get("password") or ""
    if not username or not password or looks_like_placeholder(username):
        print(
            "error: set bmc.credentials in config or export BMC_USERNAME and BMC_PASSWORD",
            file=sys.stderr,
        )
        return 1

    probe_from = inputs.get("network", {}).get("probe_from", "local")
    if probe_from not in ("", "local", "localhost") and not os.environ.get("INVENTORY"):
        print(
            f"hint: probe_from={probe_from!r} requires bastion in inventory — "
            "set INVENTORY=path/to/inventory.ini",
            file=sys.stderr,
        )

    payload = json.dumps(data, indent=2) + "\n"
    if args.output:
        args.output.write_text(payload)
    else:
        sys.stdout.write(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
