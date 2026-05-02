# Fetcher Architecture and Anti-Bot Notes

Reference for understanding and extending `scripts/fetch-sources.py`.

<architecture>
## How the Fetcher Works

The fetcher uses `concurrent.futures.ThreadPoolExecutor` to fetch multiple URLs simultaneously, with per-domain rate limiting to avoid triggering anti-bot protections on any single site.

```
manifest.md (pending entries)
    │
    ├─ Thread 1: ref-01 (arxiv.org)      ─┐
    ├─ Thread 2: ref-02 (redhat.com)      ─┤ concurrent, different domains
    ├─ Thread 3: ref-03 (redhat.com)      ─┤ Thread 3 waits for Thread 2's
    │                                       │ domain lock to release
    └─ Thread 4: ref-04 (thenewstack.io)  ─┘
    │
    ▼
sources/ directory (one .md file per successful fetch)
manifest.md (updated with status, file paths, notes)
```

**Domain-aware throttling:** Each domain has a threading lock and a timestamp. Before fetching, a thread acquires the lock for its domain and sleeps if the last request to that domain was less than `--delay` seconds ago. This means requests to *different* domains run in parallel while requests to the *same* domain are serialized with the configured delay.
</architecture>

<anti_bot>
## Why Sources Return 403

Sites like `developers.redhat.com` and `medium.com` use several layers of bot detection:

1. **IP reputation:** Rapid sequential requests from one IP get flagged. The concurrent fetcher with domain throttling helps, but the IP itself may already be flagged from prior sessions.

2. **User-Agent filtering:** Old or obviously fake UAs get blocked. The `--stealth` flag rotates through 5 current browser UA strings.

3. **Missing browser headers:** Real browsers send `Accept`, `Accept-Language`, `Sec-Fetch-*`, etc. Bot requests typically omit these. The `--stealth` flag adds a full set of browser-mimicry headers.

4. **JavaScript challenge pages:** Cloudflare and similar CDNs serve a JS challenge page that `requests` can't execute. This is the hardest to bypass without a real browser.

5. **Cookie/session requirements:** Some sites require an initial page load to set cookies before the article URL works. `requests` handles cookies within a session but doesn't execute JS-based cookie setters.
</anti_bot>

<proxy_usage>
## Using a Proxy / VPN

When your IP is flagged (403s on sites that normally work, or your regular browsing slows down after a fetch session):

**Option A: SOCKS5 proxy through VPN**
If your VPN exposes a SOCKS5 proxy (most do, e.g., on `127.0.0.1:1080`):

```bash
pip install "requests[socks]"
python3 fetch-sources.py research/subject/ --retry-failed --stealth --proxy socks5://127.0.0.1:1080
```

**Option B: System-wide VPN**
Turn on your VPN before running the fetcher. All traffic routes through the VPN tunnel:

```bash
# VPN already active
python3 fetch-sources.py research/subject/ --retry-failed --stealth
```

**Option C: HTTP proxy**
If you have an HTTP proxy available:

```bash
python3 fetch-sources.py research/subject/ --retry-failed --stealth --proxy http://proxy-host:8080
```

**Split-tunneling tip:** If your VPN supports split tunneling, route only the fetch script through the VPN while keeping your browser on your normal connection. This prevents both from being rate-limited simultaneously.
</proxy_usage>

<browser_fallback>
## Future: Headless Browser Fallback

For sites with aggressive JS-based bot protection (Cloudflare challenges, JS-rendered content), a headless browser fallback could handle the cases `requests` cannot.

**Approach:** A separate script (`fetch-sources-browser.py`) that:
1. Reads the manifest for entries with `status: failed` and `notes: HTTP 403`
2. Launches headless Chromium via `playwright`
3. Navigates to each URL, waits for JS to render, extracts content
4. Saves to the same `sources/` directory and updates the manifest

**Dependencies:**
```bash
pip install playwright
playwright install chromium
```

**Why separate:** Playwright is a heavy dependency (~150 MB for Chromium). Keeping it in a separate script means the main fetcher stays lightweight and the browser fallback is opt-in.

**Trade-offs:**
- Much slower (2-5 seconds per page vs. 0.5-1s with `requests`)
- Higher resource usage (headless Chromium process)
- But handles JS challenges, cookie-gated pages, and client-side-rendered content
- Not needed if proxy + stealth headers resolve the 403s

This is not yet implemented. If proxy + stealth doesn't achieve >85% capture rate, implementing this fallback is the next step.
</browser_fallback>

<pdf_support>
## PDF Extraction

The fetcher detects `application/pdf` responses and extracts text using `pdfplumber` (optional dependency). Each page is separated by a horizontal rule. If `pdfplumber` is not installed, PDFs are logged as failures with an install hint.

```bash
pip install pdfplumber
```

Limitations:
- Scanned/image PDFs won't extract text (would need OCR)
- Complex table layouts may not preserve structure
- Very large PDFs are truncated to 500K characters
</pdf_support>

<content_extraction>
## HTML Content Extraction Strategy

The fetcher uses a three-tier extraction strategy to find the main article content:

1. **Domain-specific selectors:** Known CSS selectors for common domains (Red Hat docs, Medium, arXiv, Microsoft Learn). Checked first because they're most accurate.

2. **Generic article selectors:** Common patterns like `<article>`, `<main>`, `[role="main"]`, `.post-content`, etc. Covers most well-structured sites.

3. **Body fallback:** If neither of the above produces >= 200 chars of useful text, falls back to the full `<body>`.

If the final extracted text is under 200 characters, the fetcher marks it as `low-content` in the manifest notes. This flags pages that returned mostly navigation or JavaScript placeholders.

To add support for a new domain, add an entry to `DOMAIN_SELECTORS` in the script.
</content_extraction>
