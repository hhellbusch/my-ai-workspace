# Workflow: Gather Sources

<required_reading>
**Read these before proceeding:**
1. templates/manifest-template.md
2. scripts/fetch-sources.py (understand the interface)
</required_reading>

<process>

## Step 1: Identify the Subject and Create Workspace

Ask the user:
- What article/document are we verifying?
- Where should the research directory live?

Default location: `research/{subject-slug}/` relative to the project root.

Create the directory structure:

```bash
mkdir -p research/{subject-slug}/sources
mkdir -p research/{subject-slug}/findings
```

## Step 2: Extract References from the Source Material

Read the article or document being analyzed. Extract every cited reference into a structured list:
- Reference ID (e.g., `ref-01`, `ref-02`, or the article's own numbering)
- URL (if present)
- What the article claims the reference supports
- Which section of the article cites it

If the article is a URL, fetch it first and save it as `research/{subject}/sources/original-article.md`.

## Step 3: Build the Manifest

Copy `templates/manifest-template.md` to `research/{subject}/manifest.md`.

Fill in the preamble with:
- Article title and URL
- Date of analysis
- Total number of references

Fill in the table with one row per reference, all marked `pending`.

## Step 4: Install Dependencies (if needed)

Check if the Python dependencies are available:

```bash
python3 -c "import requests, bs4, markdownify" 2>/dev/null && echo "OK" || echo "MISSING"
```

If missing:

```bash
pip install requests beautifulsoup4 markdownify
```

## Step 5: Run the Fetcher

Execute the fetch script:

```bash
python3 .cursor/skills/research-and-analyze/scripts/fetch-sources.py research/{subject}/ --stealth
```

**Available flags:**
- `--stealth` — Use browser-mimicry headers (rotating UA, Accept, Sec-Fetch-*). **Recommended for all runs.**
- `--workers N` — Concurrent fetch threads (default: 4). Fetches from different domains run in parallel; same-domain requests are rate-limited.
- `--delay N` — Minimum seconds between requests to the same domain (default: 2.0). Increase for sites that rate-limit aggressively.
- `--proxy URL` — Route through an HTTP or SOCKS5 proxy (e.g., `socks5://127.0.0.1:1080`). Useful when your IP is being rate-limited. Requires `pip install requests[socks]` for SOCKS proxies.
- `--retry-failed` — Re-attempt previously failed fetches.

**Typical invocations:**

```bash
# Standard run with stealth headers and 4 concurrent workers
python3 .cursor/skills/research-and-analyze/scripts/fetch-sources.py research/{subject}/ --stealth

# Retry failures through a VPN/proxy
python3 .cursor/skills/research-and-analyze/scripts/fetch-sources.py research/{subject}/ --retry-failed --stealth --proxy socks5://127.0.0.1:1080

# Conservative: single-threaded, longer delays
python3 .cursor/skills/research-and-analyze/scripts/fetch-sources.py research/{subject}/ --stealth --workers 1 --delay 3.0
```

## Step 6: Review the Manifest

Read the updated manifest. Report to the user:
- How many sources were fetched successfully
- How many failed (and why — timeout, 404, PDF, etc.)
- How many were skipped

For failed sources, consider:
- **Timeout**: May work with a retry (`--retry-failed`)
- **404**: URL may have moved — try a web search for the title
- **PDF**: Note as "manual review needed" — user can download and convert separately
- **Connection error**: Site may be down — retry later

## Step 7: Retry and Fill Gaps

If there are failed fetches:
1. Run `--retry-failed` once for timeouts
2. For persistent failures, use WebSearch to find alternative URLs or mirrors
3. If an alternative is found, manually update the manifest URL and re-run
4. For truly unreachable sources, mark as `unreachable` and note in findings

## Step 8: Checkpoint

Tell the user:
- Research directory location
- Number of sources on disk vs. total
- Recommended next step (usually "analyze claims")

</process>

<success_criteria>
This workflow is complete when:
- [ ] Research directory exists with proper structure
- [ ] Manifest has one entry per reference from the source article
- [ ] Fetch script has been run at least once
- [ ] Failed fetches have been retried or documented
- [ ] User knows the status and recommended next step
</success_criteria>
