---
name: youtube-transcript-library
description: >-
  Fetches YouTube captions to timestamped markdown and ingests into this repo’s
  reference library (research sources + library stub, catalog, log). Use when the
  user pastes a youtube.com or youtu.be URL, asks for a video transcript, captions,
  subtitles, “pull the transcript”, save a talk or video to the library, add a
  YouTube to research, or references a watch?v= link as a source to keep. Uses
  youtube-transcript-api via fetch-transcript.py — not yt-dlp alone for captions.
---

# YouTube → transcript → library

## When this applies

Any request that implies **captions from YouTube saved into this workspace** or **a YouTube video as a durable reference** matches this skill — even if the user does not name “research-and-analyze”.

## Do this first (mandatory)

1. **Read** this file (you are here), then run **`fetch-transcript.py`** below. Do **not** substitute `yt-dlp` for transcript text unless `fetch-transcript.py` fails and the user agrees to a lossy fallback.
2. **Dependency:** `pip install youtube-transcript-api` (and `requests` for metadata). If import fails, install then retry.
3. **Network:** transcript + oembed need outbound HTTPS; if DNS fails in a sandbox, re-run with full permissions.

## Fetch script (canonical path)

From the **repository root**:

```bash
python3 .cursor/skills/research-and-analyze/scripts/fetch-transcript.py \
  "<youtube-url>" \
  research/<subject>/sources/youtube-<VIDEO_ID>-transcript.md
```

On this repo, `.pi/skills` is a symlink to `.cursor/skills`, so the same path works as `python3 .pi/skills/research-and-analyze/scripts/fetch-transcript.py` if you prefer that spelling.

**Default subject bucket** when the user does not name one: `youtube-sources-apr2026` (path `research/youtube-sources-apr2026/sources/`). For a themed project (e.g. zen-karate), use `research/<their-slug>/sources/` instead.

**Naming:** `youtube-<11-char-video-id>-transcript.md` keeps glob and catalog greps predictable.

## After a successful fetch (library ingest)

Complete the ingest so transcripts are not orphaned:

1. **`library/<slug>.md`** — stub or enriched entry; link to the transcript under `research/...`.
2. **`library/catalog.md`** — add a row under **YouTube / Video** (or correct section).
3. **`library/README.md`** — add a row to **Enriched Entries** if the entry has its own file (even a stub).
4. **`library/log.md`** — append dated `ingest` block.

Slug: derive a short kebab-case from the video title (e.g. `level1techs-ai-you-against-machine-local`).

Full pipeline (claims extraction, manifest, analysis) lives in **`research-and-analyze`** → `workflows/gather-sources.md` Step **2T** onward. Use that skill when the user wants verification or multi-source research, not only a transcript file.
