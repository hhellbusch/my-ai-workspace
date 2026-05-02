#!/usr/bin/env python3
"""
fetch-sources.py — Batch URL fetcher for research workflows.

Reads a manifest file, fetches each URL marked as 'pending', saves content
to the sources/ directory, and updates the manifest with results.

Usage:
    python3 fetch-sources.py <research-dir>
    python3 fetch-sources.py <research-dir> --workers 4 --stealth
    python3 fetch-sources.py <research-dir> --retry-failed --proxy socks5://127.0.0.1:1080

Where <research-dir> contains:
    manifest.md   — source manifest with URLs and status
    sources/      — directory for fetched content (created if missing)

The manifest uses this format (one entry per source):
    | ref-id | url | status | file | notes |

Status values: pending, fetched, failed, skipped

Dependencies:
    Required: requests, beautifulsoup4, markdownify
    Optional: requests[socks] (for SOCKS5 proxy), pdfplumber (for PDF extraction)
"""

import sys
import re
import os
import io
import time
import random
import argparse
import threading
from pathlib import Path
from urllib.parse import urlparse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import requests
    from bs4 import BeautifulSoup
    from markdownify import markdownify as md
except ImportError:
    print("Missing dependencies. Install with:")
    print("  pip install requests beautifulsoup4 markdownify")
    sys.exit(1)


TIMEOUT = 30
MAX_CONTENT_BYTES = 500_000
MIN_USEFUL_CHARS = 200

USER_AGENTS = [
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:128.0) Gecko/20100101 Firefox/128.0",
]

STEALTH_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
    "Cache-Control": "max-age=0",
}

ARTICLE_SELECTORS = [
    "article",
    "main",
    '[role="main"]',
    ".post-content",
    ".article-content",
    ".entry-content",
    ".content-body",
    "#content",
    ".markdown-body",
    ".prose",
]

DOMAIN_SELECTORS = {
    "developers.redhat.com": [".assembly", ".rh-article", '[data-analytics-category="article"]'],
    "medium.com": [".meteredContent", "article"],
    "arxiv.org": [".ltx_document", "#content"],
    "docs.redhat.com": [".doc-content", "#doc-content", "main"],
    "learn.microsoft.com": [".content", "main"],
    "ai-on-openshift.io": [".md-content", "article"],
}

_domain_locks = defaultdict(threading.Lock)
_domain_last_request = defaultdict(float)


def parse_manifest(manifest_path: Path) -> list[dict]:
    """Parse markdown table rows from manifest into list of dicts."""
    entries = []
    with open(manifest_path) as f:
        lines = f.readlines()

    in_table = False
    headers = []
    for line in lines:
        line = line.strip()
        if not line.startswith("|"):
            in_table = False
            continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if not in_table:
            headers = [h.lower().replace(" ", "_") for h in cells]
            in_table = True
            continue
        if all(c.startswith("-") or c.startswith(":") for c in cells):
            continue
        entry = {}
        for i, header in enumerate(headers):
            entry[header] = cells[i] if i < len(cells) else ""
        entries.append(entry)
    return entries


def write_manifest(manifest_path: Path, entries: list[dict], preamble: str):
    """Write entries back as a markdown table, preserving preamble text."""
    if not entries:
        return
    headers = list(entries[0].keys())
    header_line = "| " + " | ".join(headers) + " |"
    sep_line = "| " + " | ".join("---" for _ in headers) + " |"

    with open(manifest_path, "w") as f:
        f.write(preamble)
        f.write(header_line + "\n")
        f.write(sep_line + "\n")
        for entry in entries:
            row = "| " + " | ".join(str(entry.get(h, "")) for h in headers) + " |"
            f.write(row + "\n")


def extract_preamble(manifest_path: Path) -> str:
    """Extract all text before the first markdown table."""
    with open(manifest_path) as f:
        lines = f.readlines()
    preamble_lines = []
    for line in lines:
        if line.strip().startswith("|"):
            break
        preamble_lines.append(line)
    return "".join(preamble_lines)


def sanitize_filename(ref_id: str) -> str:
    """Convert a ref ID to a safe filename."""
    return re.sub(r"[^a-zA-Z0-9_-]", "-", ref_id).strip("-").lower()


def domain_throttle(url: str, min_delay: float):
    """Enforce per-domain rate limiting across threads."""
    domain = urlparse(url).netloc
    with _domain_locks[domain]:
        elapsed = time.time() - _domain_last_request[domain]
        if elapsed < min_delay:
            time.sleep(min_delay - elapsed)
        _domain_last_request[domain] = time.time()


def build_headers(stealth: bool) -> dict:
    """Build request headers, optionally with stealth browser-mimicry headers."""
    headers = {"User-Agent": random.choice(USER_AGENTS)}
    if stealth:
        headers.update(STEALTH_HEADERS)
    return headers


def extract_article_content(soup: BeautifulSoup, url: str) -> str:
    """
    Extract the main article content from a parsed HTML page.
    Uses domain-specific selectors first, then generic article selectors,
    then falls back to <body>.
    """
    domain = urlparse(url).netloc.replace("www.", "")

    for base_domain, selectors in DOMAIN_SELECTORS.items():
        if base_domain in domain:
            for sel in selectors:
                el = soup.select_one(sel)
                if el:
                    text = md(str(el), heading_style="ATX", strip=["img"])
                    if len(text.strip()) >= MIN_USEFUL_CHARS:
                        return text.strip()

    for sel in ARTICLE_SELECTORS:
        el = soup.select_one(sel)
        if el:
            text = md(str(el), heading_style="ATX", strip=["img"])
            if len(text.strip()) >= MIN_USEFUL_CHARS:
                return text.strip()

    body = soup.find("body")
    if body:
        return md(str(body), heading_style="ATX", strip=["img"]).strip()

    return md(str(soup), heading_style="ATX", strip=["img"]).strip()


def fetch_pdf(content_bytes: bytes) -> tuple[str, str]:
    """Extract text from PDF bytes. Returns (text, error)."""
    try:
        import pdfplumber
    except ImportError:
        return "", "PDF — install pdfplumber for PDF support"

    try:
        with pdfplumber.open(io.BytesIO(content_bytes)) as pdf:
            pages = []
            for page in pdf.pages:
                text = page.extract_text()
                if text:
                    pages.append(text)
            full_text = "\n\n---\n\n".join(pages)
            return full_text[:MAX_CONTENT_BYTES], ""
    except Exception as e:
        return "", f"PDF extraction failed: {str(e)[:100]}"


def fetch_url(url: str, stealth: bool = False, proxies: dict = None) -> tuple[str, str]:
    """
    Fetch a URL and return (content_as_markdown, error_or_empty).
    Converts HTML to markdown, extracts PDF text, handles plain text and JSON.
    """
    try:
        headers = build_headers(stealth)
        resp = requests.get(
            url,
            timeout=TIMEOUT,
            headers=headers,
            allow_redirects=True,
            proxies=proxies,
        )
        resp.raise_for_status()

        content_type = resp.headers.get("content-type", "")

        if "application/pdf" in content_type:
            return fetch_pdf(resp.content)

        if "text/html" in content_type or "application/xhtml" in content_type:
            html = resp.text[:MAX_CONTENT_BYTES]
            soup = BeautifulSoup(html, "html.parser")
            for tag in soup(["script", "style", "nav", "footer", "header", "aside"]):
                tag.decompose()

            text = extract_article_content(soup, url)

            if len(text) < MIN_USEFUL_CHARS:
                return text, f"low-content ({len(text)} chars)"

            return text, ""

        if "text/plain" in content_type or "text/markdown" in content_type:
            return resp.text[:MAX_CONTENT_BYTES].strip(), ""

        if "application/json" in content_type:
            return resp.text[:MAX_CONTENT_BYTES].strip(), ""

        return "", f"Unsupported content-type: {content_type}"

    except requests.exceptions.Timeout:
        return "", "Timeout"
    except requests.exceptions.ConnectionError:
        return "", "Connection error"
    except requests.exceptions.HTTPError as e:
        return "", f"HTTP {e.response.status_code}"
    except Exception as e:
        return "", str(e)[:200]


def process_entry(entry: dict, sources_dir: Path, stealth: bool,
                  proxies: dict, domain_delay: float) -> dict:
    """Fetch a single entry and update its status. Thread-safe."""
    url = entry.get("url", "").strip()
    ref_id = entry.get("ref_id", entry.get("ref-id", "unknown"))

    if not url or url == "-":
        entry["status"] = "skipped"
        entry["notes"] = "No URL"
        return entry

    domain_throttle(url, domain_delay)

    filename = sanitize_filename(ref_id) + ".md"
    filepath = sources_dir / filename

    content, error = fetch_url(url, stealth=stealth, proxies=proxies)

    if error and not content:
        entry["status"] = "failed"
        entry["notes"] = error
        entry["file"] = "-"
    elif content:
        source_header = f"# Source: {ref_id}\n\n"
        source_header += f"**URL:** {url}\n"
        source_header += f"**Fetched:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        source_header += "---\n\n"

        with open(filepath, "w") as f:
            f.write(source_header + content)

        status = "fetched"
        notes = f"{len(content)} chars"
        if error:
            notes += f" ({error})"
        entry["status"] = status
        entry["file"] = f"sources/{filename}"
        entry["notes"] = notes
    else:
        entry["status"] = "failed"
        entry["notes"] = error or "Empty response"
        entry["file"] = "-"

    return entry


def main():
    parser = argparse.ArgumentParser(
        description="Batch-fetch URLs from a research manifest"
    )
    parser.add_argument("research_dir", help="Path to research directory")
    parser.add_argument(
        "--retry-failed", action="store_true",
        help="Re-attempt previously failed fetches"
    )
    parser.add_argument(
        "--delay", type=float, default=2.0,
        help="Minimum seconds between requests to the same domain (default: 2.0)"
    )
    parser.add_argument(
        "--workers", type=int, default=4,
        help="Number of concurrent fetch threads (default: 4)"
    )
    parser.add_argument(
        "--stealth", action="store_true",
        help="Use browser-mimicry headers (rotating UA, Accept, Sec-Fetch-*)"
    )
    parser.add_argument(
        "--proxy",
        help="HTTP or SOCKS5 proxy URL (e.g., socks5://127.0.0.1:1080, http://proxy:8080)"
    )

    args = parser.parse_args()

    research_dir = Path(args.research_dir)
    manifest_path = research_dir / "manifest.md"
    sources_dir = research_dir / "sources"

    if not manifest_path.exists():
        print(f"Error: {manifest_path} not found")
        sys.exit(1)

    sources_dir.mkdir(exist_ok=True)

    if args.proxy and "socks" in args.proxy.lower():
        try:
            import socks  # noqa: F401
        except ImportError:
            print("SOCKS proxy requires PySocks. Install with:")
            print("  pip install requests[socks]")
            sys.exit(1)

    proxies = None
    if args.proxy:
        proxies = {"http": args.proxy, "https": args.proxy}
        print(f"Using proxy: {args.proxy}")

    if args.stealth:
        print("Stealth mode: rotating UA + browser-mimicry headers")

    preamble = extract_preamble(manifest_path)
    entries = parse_manifest(manifest_path)

    if not entries:
        print("No entries found in manifest table.")
        sys.exit(1)

    to_fetch = []
    for entry in entries:
        status = entry.get("status", "").lower()
        if status == "pending":
            to_fetch.append(entry)
        elif status == "failed" and args.retry_failed:
            to_fetch.append(entry)

    total = len(entries)
    fetch_count = len(to_fetch)
    print(f"Found {total} total entries, {fetch_count} to fetch "
          f"(workers={args.workers}, domain_delay={args.delay}s).")

    if fetch_count == 0:
        print("Nothing to fetch.")
        return

    fetched = 0
    failed = 0
    completed = 0

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_entry = {}
        for entry in to_fetch:
            future = executor.submit(
                process_entry, entry, sources_dir,
                args.stealth, proxies, args.delay
            )
            future_to_entry[future] = entry

        for future in as_completed(future_to_entry):
            entry = future_to_entry[future]
            ref_id = entry.get("ref_id", entry.get("ref-id", "?"))
            completed += 1

            try:
                result = future.result()
                status = result.get("status", "failed")
                notes = result.get("notes", "")

                if status == "fetched":
                    fetched += 1
                    print(f"  [{completed}/{fetch_count}] {ref_id}: OK — {notes}")
                elif status == "skipped":
                    print(f"  [{completed}/{fetch_count}] {ref_id}: SKIPPED — {notes}")
                else:
                    failed += 1
                    print(f"  [{completed}/{fetch_count}] {ref_id}: FAILED — {notes}")
            except Exception as e:
                failed += 1
                entry["status"] = "failed"
                entry["notes"] = f"Thread error: {str(e)[:100]}"
                entry["file"] = "-"
                print(f"  [{completed}/{fetch_count}] {ref_id}: ERROR — {e}")

    write_manifest(manifest_path, entries, preamble)
    print(f"\nDone. Fetched: {fetched}, Failed: {failed}, Total: {total}")
    print(f"Manifest updated: {manifest_path}")


if __name__ == "__main__":
    main()
