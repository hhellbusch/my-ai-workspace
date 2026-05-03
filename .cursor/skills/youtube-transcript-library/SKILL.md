---
name: youtube-transcript-library
description: >-
  Narrow entry skill for YouTube transcript ingestion and library stub creation.
  Use when the user pastes a youtube.com or youtu.be URL and wants a transcript
  saved to disk and/or a library entry created. Fetches captions via
  fetch-transcript.py and walks the 4-step library ingest checklist. For full
  pipeline work (citation verification, multi-source analysis, batch gathering),
  hand off to the research-and-analyze skill after the transcript is on disk.
---

<essential_principles>

### Scope

This skill handles one narrow path: **YouTube URL → transcript on disk → library entry**.

It does **not** run citation verification, claims analysis, or multi-source pipelines. If the user wants those, complete the transcript step here, then route to `research-and-analyze`.

### Script

Use **`fetch-transcript.py`** — located at `.pi/skills/research-and-analyze/scripts/fetch-transcript.py`.

Do **not** use `yt-dlp` directly for captions — the script handles format normalisation and saves structured markdown.

```bash
# Single video
python3 .pi/skills/research-and-analyze/scripts/fetch-transcript.py \
  --url "https://www.youtube.com/watch?v=VIDEO_ID" \
  --out "research/{slug}/sources/"

# Output: research/{slug}/sources/{title-slug}.md  (timestamped transcript)
```

Pick a subject slug that will serve as the research directory name — e.g., `karpathy-software2`, `rich-hickey-simple-made-easy`.

</essential_principles>

<workflow>

## Step 1 — Fetch transcript

Run `fetch-transcript.py` with the user-provided URL. Confirm the output file exists and is non-empty before continuing.

## Step 2 — Gather metadata

From the transcript file or the video, collect:
- Title
- Speaker / channel
- Date published
- URL
- Wing tag (see below)
- One-paragraph summary (synthesise from transcript — do not fabricate)

**Wing tags:**
| Tag | Topics |
|-----|--------|
| `ai-engineering` | agents, harness, context, memory, models, agentic-workflow |
| `philosophy-practice` | zen, karate, flow, solitude, martial arts |
| `devops` | git, openshift, rhacm, aap, ansible |
| `leadership-org` | career, AI organisational impact, team dynamics |

## Step 3 — Library ingest (all four steps required)

**Every ingest must complete all four:**

1. **Create entry file** — `library/{slug}.md`
   - Frontmatter: title, speaker, date, url, wing, tags
   - Body: summary, key ideas, quotes worth keeping, link to transcript in `research/`

2. **Add row to `library/catalog.md`** — slug, title, speaker, date, wing

3. **Add entry block to `library/README.md`** — Enriched Entries table row

4. **Append dated entry to `library/log.md`** — date, slug, one-line description

## Step 4 — Confirm and hand off

Tell the user:
- Transcript saved at: `research/{slug}/sources/…`
- Library entry created at: `library/{slug}.md`
- Offer: "If you want citation verification or claims analysis, I can hand off to the full research-and-analyze pipeline."

</workflow>

<escalation>

Route to **`research-and-analyze`** when the user wants:
- Claim verification against cited sources
- Multi-source or batch gathering
- Full gather → analyze → synthesize pipeline
- Evaluation of the talk with evidence scoring

The transcript file produced here becomes the starting source for that pipeline — no re-fetching needed.

</escalation>
