# Workflow: Gather Sources

<required_reading>
**Read these before proceeding:**
1. templates/manifest-template.md
2. scripts/fetch-sources.py (understand the interface)
3. scripts/fetch-transcript.py (for YouTube/transcript variant)
</required_reading>

<process>

## Step 1: Identify the Subject and Create Workspace

Confirm with the user (this should already be answered from the intake):
- What is the subject slug? (e.g., `miessler-single-da-thesis`)
- Is this the standard article path or the transcript variant (Step 2T)?

**Directory naming rule: use a meaningful subject slug, never a URL fragment, video ID, or technical identifier.**

Create the directory structure:

```bash
mkdir -p research/{subject-slug}/sources
mkdir -p research/{subject-slug}/findings
```

## Step 2: Extract References from the Source Material

*(Standard path — article with citations. For YouTube/transcript, skip to Step 2T.)*

Read the article or document being analyzed. Extract every cited reference into a structured list:
- Reference ID (e.g., `ref-01`, `ref-02`, or the article's own numbering)
- URL (if present)
- What the article claims the reference supports
- Which section of the article cites it

If the article is a URL, fetch it first and save it as `research/{subject}/sources/original-article.md`.

## Step 2T: Transcript Variant — YouTube Video or Single Source

*(Use this path when the source is a YouTube video, a talk, or any single source with no external citations to verify.)*

**Fetch the transcript:**

```bash
python3 .cursor/skills/research-and-analyze/scripts/fetch-transcript.py \
  "{youtube-url}" \
  research/{subject-slug}/sources/ref-01-transcript.md
```

The script fetches metadata (title, channel, duration) and saves a timestamped markdown file with both timestamped paragraphs and a plain-text section.

**Extract claims for analysis.** A talk has no external citations — the "references" are the assertions made in the talk itself. After fetching, read the transcript and build a claims list in the manifest:
- `C1`, `C2`, ... for each substantive claim
- What the speaker asserts
- Whether it is factual/verifiable, directional/predictive, or personal/framework

For talks, claims fall into these categories:
1. **Factual** — specific numbers, dates, product states (can be verified against external sources)
2. **Architectural** — descriptions of how a system works (verify against repo/docs if public)
3. **Predictive** — directional claims about where things are going (evaluate internal coherence and supporting evidence)
4. **Framework** — proprietary models or terminology (evaluate coherence, not external correctness)
5. **Relational** — connections to other people, companies, events (verify against public record)

Build the manifest with one row per claim. Mark each `pending`. The `analyze-claims.md` workflow handles claim-by-claim evaluation.

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

## Step 8: Phase-Boundary Checkpoint — HARD STOP

**Do not proceed to analysis. Stop here and report to the user.**

Tell the user:
- Research directory location and structure (show the file tree)
- Number of sources on disk vs. total
- For transcript variant: confirm the transcript was saved and show the segment count
- For standard path: fetch success/failure counts

Then ask:

> **Gather phase complete.** Files are on disk at `research/{subject-slug}/`. Ready to move to claim analysis?
> - Yes — proceed to `analyze-claims.md`
> - No — describe what to fix

**Wait for explicit confirmation before starting analysis.**

</process>

<success_criteria>
This workflow is complete when:
- [ ] Research directory exists with proper structure (`sources/`, `findings/`, `manifest.md`)
- [ ] Subject slug is meaningful (not a URL fragment or video ID)
- [ ] Manifest has one entry per reference or claim, all marked `pending`
- [ ] Fetch script has been run at least once and output confirmed
- [ ] Failed fetches have been retried or documented
- [ ] User has explicitly confirmed readiness to proceed to analysis
</success_criteria>
