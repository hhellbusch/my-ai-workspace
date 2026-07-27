#!/usr/bin/env python3
"""Assert a preflight run matches scenario expectations."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("error: PyYAML required", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scenario", type=Path)
    parser.add_argument("report", type=Path)
    parser.add_argument("exit_code", type=int)
    args = parser.parse_args()

    scenario = yaml.safe_load(args.scenario.read_text())
    expect = scenario.get("expect", {})
    expected_exit = expect.get("exit_code", 0)
    expected_ids = {item["id"] for item in expect.get("blocking", [])}

    if args.exit_code != expected_exit:
        print(
            f"FAIL exit code: expected {expected_exit}, got {args.exit_code}",
            file=sys.stderr,
        )
        return 1

    if not args.report.exists():
        if expected_ids:
            print(f"FAIL report missing: {args.report}", file=sys.stderr)
            return 1
        print("PASS (no report, none expected)")
        return 0

    report = json.loads(args.report.read_text())
    actual_ids = {item["id"] for item in report.get("blocking", [])}

    if actual_ids != expected_ids:
        print(
            f"FAIL finding IDs: expected {sorted(expected_ids)}, got {sorted(actual_ids)}",
            file=sys.stderr,
        )
        for item in report.get("blocking", []):
            print(f"  BLOCKING: {item['id']}: {item['message']}", file=sys.stderr)
        return 1

    forbidden_ids = set()
    for item in expect.get("not_blocking", []):
        if isinstance(item, dict):
            forbidden_ids.add(item["id"])
        else:
            forbidden_ids.add(str(item))

    overlap = forbidden_ids & actual_ids
    if overlap:
        print(
            f"FAIL unexpected blocking IDs: {sorted(overlap)}",
            file=sys.stderr,
        )
        return 1

    print(f"PASS {scenario.get('name', args.scenario.stem)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
