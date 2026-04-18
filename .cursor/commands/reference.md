---
description: Add, search, or enrich entries in the personal reference library
argument-hint: "[add <title> | search <term> | enrich <entry> | list]"
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Shell
  - Glob
  - Grep
  - WebSearch
  - WebFetch
---

# Reference — Personal Library Management

<objective>
Manage the personal reference library in `library/`. This persistent collection stores books, talks, articles, videos, and other sources with AI-enriched context, so any future session or project can draw from them.
</objective>

<context>
- Library directory: `library/`
- Library index: @library/README.md
- Current date: !`date "+%Y-%m-%d"`
</context>

<process>
Parse `$ARGUMENTS` to determine the subcommand. If empty or unrecognized, default to **list**.

---

### Subcommand: `list` (default)

1. Read `library/README.md`
2. Display the index table
3. Count total entries by type (Book, Talk, Article, etc.)

---

### Subcommand: `add <title and details>`

1. From the description and conversation context, extract:
   - **Title**
   - **Author** (if provided)
   - **Type**: Book / Talk / Article / Video / Course / Website
   - **URL** (if provided)
   - **Tags**: relevant keywords
   - **Why it matters**: user's stated reason or infer from context

2. Generate a filename: lowercase, hyphenated version of the title (e.g., `zen-way-martial-arts.md`)

3. **Enrich the entry** (this is the key step):
   - Search the web for summaries, reviews, chapter outlines, and key themes
   - For books: find book reviews, practitioner analyses, publisher descriptions
   - For talks/videos: find transcripts or detailed summaries
   - For articles: fetch the article content if possible
   - Fetch the best 2-3 sources and synthesize into the "Key Themes" and "Notable Ideas" sections
   - Cache the source URLs in the "Sources" section

4. Create the entry file from the template in `library/README.md`, filling in:
   - All metadata fields
   - "Why This Matters" section with user's notes (or a placeholder prompting them to add)
   - "Key Themes" section from AI enrichment
   - "Notable Ideas" section highlighting concepts most likely to be referenced
   - "Sources" section with the URLs used for enrichment

5. Update the index table in `library/README.md`

6. **Check project relevance**: Read `BACKLOG.md` and scan `.planning/` for active projects. If the new reference is relevant to any project, suggest adding it to that project's curated reading list.

7. Confirm:
   ```
   Added to library: <title>
   Type: <type> | Tags: <tags>
   Enriched from: <N sources>
   Relevant to: <project suggestions or "no active project matches">
   ```

---

### Subcommand: `search <term>`

1. Search across all `library/*.md` files for the term (title, tags, themes, notable ideas)
2. Display matching entries with the relevant context snippet
3. If no matches, suggest broadening the search

---

### Subcommand: `enrich <entry>`

Re-run enrichment on an existing entry:

1. Read the specified entry file
2. Search for additional or updated sources
3. Expand the "Key Themes" and "Notable Ideas" sections
4. Add any new sources to the "Sources" section
5. Report what was added

This is useful when:
- The original enrichment was thin
- You want to go deeper on a specific reference
- New online sources have become available

---

### Subcommand: `link <entry> <project>`

Connect a library entry to a project's curated reading list:

1. Read the library entry
2. Find the project's curated reading list (e.g., `research/{project}/curated-reading.md`)
3. Add the reference with a link back to the library entry
4. Update the library entry's "Projects" metadata field
</process>

<success_criteria>
- Every new entry has metadata, AI-enriched themes, and source attribution
- Library README index stays current
- Relevant project connections suggested on add
- Enrichment draws from reliable sources (practitioner analyses, publisher pages, reputable review sites)
- User's personal notes preserved and clearly separated from AI-enriched content
</success_criteria>
