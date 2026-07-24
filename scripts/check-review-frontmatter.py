#!/usr/bin/env python3
"""Verify review: YAML frontmatter on devops/ and docs/ markdown.

CI (--ci): fail if changed scoped markdown in the commit range lacks review metadata.
Local default: same for staged, unstaged, and untracked scoped markdown.
Pre-commit (--staged): only staged scoped markdown (for .githooks/pre-commit).
Audit (--all): report every scoped file missing review frontmatter.

See rules/review-tracking.md for the required shape.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]

# Machine-generated indexes — no author review metadata.
EXEMPT_REL_PATHS = {
    "devops/SYMPTOM-INDEX.md",
    "devops/EXAMPLE-INDEX.md",
}

SKIP_DIR_NAMES = {"_meta", "install", ".git"}


def is_scoped_markdown(path: Path) -> bool:
    rel = path.as_posix()
    if not rel.endswith(".md"):
        return False
    if not (rel.startswith("devops/") or rel.startswith("docs/")):
        return False
    if rel in EXEMPT_REL_PATHS:
        return False
    parts = path.parts
    if any(part in SKIP_DIR_NAMES for part in parts):
        return False
    if "research" in parts and "sources" in parts:
        return False
    if rel.startswith(".planning/"):
        return False
    return True


def iter_scoped_files() -> list[Path]:
    files: list[Path] = []
    for base in ("devops", "docs"):
        root = ROOT / base
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.md")):
            if is_scoped_markdown(path.relative_to(ROOT)):
                files.append(path)
    return files


def extract_frontmatter(text: str) -> str | None:
    if not text.startswith("---"):
        return None
    match = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.DOTALL)
    return match.group(1) if match else None


def has_review_frontmatter(path: Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    fm_text = extract_frontmatter(text)
    if fm_text is None:
        return False
    try:
        data = yaml.safe_load(fm_text)
    except yaml.YAMLError:
        return False
    if not isinstance(data, dict):
        return False
    review = data.get("review")
    if not isinstance(review, dict):
        return False
    status = review.get("status")
    return isinstance(status, str) and bool(status.strip())


def git_output(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return ""
    return result.stdout


def changed_paths_for_ci() -> list[Path]:
    event = os.environ.get("GITHUB_EVENT_NAME", "")
    if event == "pull_request":
        base = os.environ.get("GITHUB_BASE_REF", "main").removeprefix("origin/")
        git_output("fetch", "origin", base, "--depth=1")
        diff_range = f"origin/{base}...HEAD"
    elif event == "push":
        before = os.environ.get("GITHUB_EVENT_BEFORE", "")
        after = os.environ.get("GITHUB_SHA", "HEAD")
        if before and before != "0" * 40:
            diff_range = f"{before}...{after}"
        else:
            diff_range = "HEAD~1...HEAD"
    else:
        diff_range = "HEAD"

    names = git_output("diff", "--name-only", "--diff-filter=ACMR", diff_range).splitlines()
    untracked = git_output("ls-files", "--others", "--exclude-standard").splitlines()
    paths: list[Path] = []
    for name in sorted(set(names) | set(untracked)):
        path = ROOT / name
        if path.is_file() and is_scoped_markdown(path.relative_to(ROOT)):
            paths.append(path)
    return paths


def changed_paths_staged() -> list[Path]:
    names = git_output("diff", "--cached", "--name-only", "--diff-filter=ACMR").splitlines()
    paths: list[Path] = []
    for name in names:
        path = ROOT / name
        if path.is_file() and is_scoped_markdown(path.relative_to(ROOT)):
            paths.append(path)
    return paths


def changed_paths_local() -> list[Path]:
    names = set(
        git_output("diff", "--name-only", "--diff-filter=ACMR").splitlines()
        + git_output("diff", "--cached", "--name-only", "--diff-filter=ACMR").splitlines()
        + git_output("ls-files", "--others", "--exclude-standard").splitlines()
    )
    paths: list[Path] = []
    for name in sorted(names):
        path = ROOT / name
        if path.is_file() and is_scoped_markdown(path.relative_to(ROOT)):
            paths.append(path)
    return paths


def check_paths(paths: list[Path]) -> list[Path]:
    return [path for path in paths if not has_review_frontmatter(path)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all",
        action="store_true",
        help="Audit every scoped markdown file (not just changed files).",
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="Check only staged scoped markdown (for pre-commit hooks).",
    )
    parser.add_argument(
        "--ci",
        action="store_true",
        help="Use GitHub Actions event context to select changed files.",
    )
    parser.add_argument(
        "files",
        nargs="*",
        help="Explicit file paths to check (must be scoped markdown).",
    )
    args = parser.parse_args()

    if args.files:
        paths = []
        for name in args.files:
            path = (ROOT / name).resolve()
            rel = path.relative_to(ROOT)
            if not path.is_file() or not is_scoped_markdown(rel):
                print(f"SKIP (out of scope): {name}", file=sys.stderr)
                continue
            paths.append(path)
    elif args.all:
        paths = iter_scoped_files()
    elif args.ci:
        paths = changed_paths_for_ci()
    elif args.staged:
        paths = changed_paths_staged()
    else:
        paths = changed_paths_local()

    if not paths:
        print("Review frontmatter check: no scoped markdown files to check.")
        return 0

    missing = check_paths(paths)
    if missing:
        print(
            "Review frontmatter check failed — add a review: block with status: "
            "(see rules/review-tracking.md):",
            file=sys.stderr,
        )
        for path in missing:
            print(f"  {path.relative_to(ROOT)}", file=sys.stderr)
        print(
            f"\n{len(missing)} of {len(paths)} checked file(s) missing review frontmatter.",
            file=sys.stderr,
        )
        return 1

    print(f"Review frontmatter check passed ({len(paths)} file(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
