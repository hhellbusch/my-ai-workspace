---
description: Find and fix missing cross-links for a file or all new files from this session
argument-hint: "[file path | --session]"
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Shell
  - Glob
  - Grep
  - SemanticSearch
---

# Cross-Link — Find and Fix Missing Inbound Links

<objective>
Given a target document, find all related docs in the workspace that discuss similar topics but don't yet link to the target. Report the gaps and fix them on request.

This solves the systematic problem: when a new doc is created, existing docs that should link to it don't automatically get updated. This command makes that check explicit and fast.
</objective>

<process>

### Step 0: Identify targets

Parse `$ARGUMENTS`:

- **File path** (e.g. `docs/ai-engineering/framework-bootstrap.md`) → check cross-links for that one file
- **`--session`** → find all `.md` files committed or added in this session, run cross-link check on each
- **No arguments** → if `/whats-next` triggered this, use the new files list from that context; otherwise ask: "Which file should I check cross-links for?"

For `--session`, discover new files:
```bash
git diff --name-only HEAD~5..HEAD -- '*.md' | grep -v "^\.planning/" | sort -u
```
Filter to files in `docs/`, `research/`, or `.cursor/` — skip generated files, backlog, and transient notes.

---

### Step 1: Read and characterize the target

Read the target file in full. Identify:
- **Primary topic** — one sentence: what is this document about?
- **Key concepts** — 3-5 terms or themes that another doc discussing this would mention
- **Track** — which directory is it in? (`docs/ai-engineering/`, `docs/case-studies/`, etc.)

---

### Step 2: Find semantically related docs

Run SemanticSearch using the primary topic and key concepts as the query. Search the full workspace.

Also check these always-relevant anchor relationships:
- If the target is in `docs/ai-engineering/` → check all other `docs/ai-engineering/` docs for topic overlap
- If the target discusses a named framework or system → check `docs/ai-engineering/README.md`, `session-framework.md`, and `framework-bootstrap.md` (if it's not those files itself)
- If the target is a case study → check the relevant essays it demonstrates

Limit to top 10 semantically related candidates.

---

### Step 3: Check which candidates already link to the target

For each candidate doc found in Step 2:

```bash
grep -l "target-filename\|target-title-words" candidate-doc.md
```

Categorize each:
- ✅ **Already linked** — skip
- ❌ **Not linked** — candidate for addition
- ➖ **Unlikely to need it** — related but not a natural cross-link (e.g. a tangential essay that happens to use similar language)

For each ❌, determine:
1. Does the candidate have a **Related Reading** section? → add there
2. Does it have a **Starting Points** or **Further Reading** table? → add there
3. Does it discuss the target topic directly in prose? → add inline on first mention
4. No natural place? → skip (don't force a link that doesn't fit)

---

### Step 4: Report gaps

Present findings:

```
## Cross-link gaps for: [target filename]

**Topic:** [one-sentence characterization]

### Already linked ✅
- `docs/ai-engineering/session-framework.md`

### Missing links ❌ — proposed additions

**`docs/ai-engineering/sparring-and-shoshin.md`**
→ Add to Starting Points table:
| [target title] | [relative link] | [one-line description] |

**`docs/ai-engineering/the-meta-development-loop.md`**
→ Add to Related Reading table:
| [target title] | [relative link] | [one-line description] |

### Skipped (related but not a natural link)
- `docs/philosophy/ego-ai-and-the-zen-antidote.md` — shares themes but adding would be a stretch
```

---

### Step 5: Fix on request

After reporting, ask: "Fix all? Fix specific ones? Or review first?"

If fixing:
1. For each ❌ with a clear insertion point, use StrReplace to add the link to the correct section
2. After all fixes, run a quick check: `grep -l "target-filename" updated-files` to confirm links were added
3. Summarize: "Added N links to M files"

Do **not** fix without asking first. The report is always shown; fixing is opt-in.

---

### Step 6: Check the reverse direction

After fixing inbound links, also check: does the target itself have a Related Reading section? Does it link back to the docs that now link to it? If the target is missing obvious outbound links, surface them:

> "While I was checking, I noticed `[target]` doesn't link back to `[candidate]` — want me to add that too?"

</process>

<success_criteria>
- Every candidate doc checked programmatically (not guessed)
- Report distinguishes already-linked / missing / skipped with reasoning
- Proposed additions include exact insertion point and formatted link text
- No links added without user confirmation
- Reverse direction checked: target's own Related Reading is complete
- Fast: should run in one agent turn for a single file
</success_criteria>
