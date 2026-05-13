# Research — Workspace Conventions

This file defines discipline for `research/` directories: what belongs there,
how working directories are structured, and how research material flows into
articles and library entries.

---

## Mental model

`research/` is a **workshop** — a place for working material that informs
writing. It is not a permanent home. Material that stays here permanently
either became a library entry, fed a docs article, or is actively in use.

The outputs of research live elsewhere:
- Synthesis, essays → `docs/`
- Reference wiki entries → `library/`
- Operational artifacts → `devops/`

---

## Directory structure

Every `research/<topic>/` directory must have a `README.md` that declares:

```markdown
# <Topic>

**Purpose:** What question or task this research supports.
**Status:** In progress | Complete | Archived
**Output:** What was produced and where it lives (link).
```

A directory with files and no README is incomplete. Name the working
directory, declare its purpose, and say where the output went.

---

## Subdirectory naming

| Subdir | Contents |
|--------|----------|
| `sources/` | Raw fetched content — scraped pages, transcripts, downloaded docs. Used to inform writing. **Not linked from articles or library entries.** Save as `.txt`, not `.md` (see below). |
| `findings/` | Intermediate analysis — notes, excerpts, structured summaries from sources. |

Do not use `resources/` — that name is ambiguous between "things I read" and
"things a reader would use." Use `sources/` for raw material.

### Save fetched sources as `.txt`, not `.md`

The `fetch-sources.py` script saves fetched content as `.md` by default. **Rename
fetched files to `.txt` before committing.** This prevents the `relative-link-guard`
from scanning web-relative URLs in scraped content (e.g. `/en/products`,
`install-guide.html`) and generating false positives.

```bash
# After fetching
cd research/<topic>/sources/
for f in *.md; do mv "$f" "${f%.md}.txt"; done
```

The `.txt` extension signals clearly that this is raw scraped material, not
authored markdown. Internal links in scraped content are relative to the source
website's domain — they are not repository-relative paths.

---

## Linking — use the original URL

If you want to cite a reference in a `docs/` article or library entry, link
to the **original source URL**, not a local copy under `research/sources/`.

```text
✓ [GPU Driver Upgrades](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-driver-upgrades.html)
✗ [GPU Driver Upgrades](../../research/<topic>/sources/<scraped-file>.md)
```

**Rationale:** Local copies of external content become stale and are not
human-readable in the way the original is. Readers following a reference
expect the canonical source, not a scraper artifact. The local copy served
its purpose during writing; it doesn't need to survive into the published
reference.

**Exception:** Transcripts of videos or podcasts that have no stable URL
(YouTube auto-captions, private recordings) may live in `sources/` and be
linked from library entries when there is no better canonical form.

---

## Operational artifacts

YAML templates, config files, Helm values, runbooks, and other files a
practitioner would apply against a system are **operational artifacts** —
they belong in `devops/`, not `research/`.

```
devops/ocp/gpu/        ← GPU Operator YAMLs
devops/vault/          ← Vault config templates
research/openshift-gpu/ ← working directory; sources used to write the guide
```

If a research session produces operational artifacts as a side effect, move
them to `devops/` as part of completing the work.

---

## When research feeds a docs article (not a library entry)

AGENTS.md describes the pipeline as `research/ → library/`. But some
research directly produces a `docs/` essay. When that happens:

- Link the article from the research directory's README as the output
- The article is the finding — an `assessment.md` is not required
- Sources stay in `research/<topic>/sources/` as working material, not as
  article references (see "Linking" above)

---

## Lifecycle

| Stage | What to do |
|-------|-----------|
| Starting | Create `research/<topic>/README.md` with purpose and status = "In progress" |
| During | Put raw fetched content in `sources/`. Keep notes in `findings/`. |
| Finishing | Write the output (library entry or docs article). Update README: status = "Complete", output = link. |
| Cleanup | Remove dead-weight sources (nav-only scrapes, wrong-platform content, exact duplicates). Move operational artifacts to `devops/`. |
