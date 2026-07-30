#!/usr/bin/env python3
"""Load a preflight scenario YAML and emit Ansible extra-vars JSON."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("error: PyYAML required (dnf install python3-pyyaml)", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario", type=Path, help="Path to scenario YAML")
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="Path for preflight_report_path extra var",
    )
    args = parser.parse_args()

    data = yaml.safe_load(args.scenario.read_text())
    if not isinstance(data, dict):
        print("error: scenario root must be a mapping", file=sys.stderr)
        return 1

    extra = {
        "preflight_inputs": data.get("inputs", {}),
        "preflight_validation_mode": data.get("validation_mode", "harness"),
    }
    if args.report:
        extra["preflight_report_path"] = str(args.report)

    json.dump(extra, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
