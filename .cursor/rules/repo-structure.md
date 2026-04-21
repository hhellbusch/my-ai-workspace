# Repository Structure Conventions

This rule defines where content belongs in this repository. Follow these conventions when creating new files, moving existing files, or suggesting organizational changes.

## Directory Map

Content is organized by **product/technology**, then by **content type** within each product directory.

### DevOps / technical reference (`devops/`)

All product-specific technical reference material lives under `devops/`. This keeps the repo root clean for the content that serves the widest audience.

| Directory | Content types | Convention |
|---|---|---|
| `devops/ansible/examples/` | Runnable Ansible playbooks demonstrating patterns | Numbered dirs: `NNN_description/`, each with `README.md` and playbook |
| `devops/ansible/troubleshooting/` | Ansible/AAP troubleshooting guides | Named dirs: `topic-slug/README.md` following symptom → cause → fix structure |
| `devops/argo/examples/` | ArgoCD configurations, app-of-apps patterns, GitOps workflows | Subdirs: `apps/`, `charts/`, `scripts/`, `docs/`, `infrastructure/`, `examples/` |
| `devops/argo/labs/` | Hands-on ArgoCD/GitOps lab exercises | Named dirs: `lab-description/` with `LAB-GUIDE.md` or session files |
| `devops/coreos/examples/` | CoreOS/Ignition/Butane configurations | Named dirs with Butane configs and READMEs |
| `devops/ocp/examples/` | OpenShift configuration examples and templates | Named dirs with configs and READMEs |
| `devops/ocp/troubleshooting/` | OpenShift troubleshooting guides | Named dirs: `topic-slug/README.md`, same structure as ansible/troubleshooting |
| `devops/ocp/notes/` | Informal OpenShift quick references and command references | Markdown files, loosely organized |
| `devops/ocp/install/` | Local OCP install working directory (**gitignored**) | Not committed; local use only |
| `devops/rhacm/examples/` | Red Hat Advanced Cluster Management configurations | Named dirs with configs and READMEs |
| `devops/vault/integration/` | HashiCorp Vault integration patterns | Configs and playbooks |

### Cross-cutting directories

| Directory | Purpose | Convention |
|---|---|---|
| `docs/` | Essays and guides organized by track | Three subdirs: `ai-engineering/`, `philosophy/`, `case-studies/`, each with its own `README.md`; master index at `docs/README.md` |
| `library/` | Personal reference library — books, talks, articles with AI-enriched summaries | One `.md` per reference, indexed in `library/README.md`; managed via `/reference` |
| `examples/` | Standalone scripts and artifacts referenced by docs | Named dirs: `topic-slug/` (e.g., `gif-recoloring/`) |
| `git-projects/` | External git repos cloned for exploration and upstream contributions (**gitignored**) | Clone repos directly; not committed to this repo |
| `.prompts/` | Structured AI prompt templates for repeatable tasks | Numbered files: `NNN-description.md`; completed outputs go in `completed/` |
| `research/` | Research workspaces — fetched sources, analysis findings, assessments | One dir per topic: `research/{topic}/` with `manifest.md`, `sources/`, `findings/`, `assessment.md` |
| `.planning/` | Multi-session project planning — briefs, roadmaps, style guides, evolution logs | One dir per project: `.planning/{project}/` with `BRIEF.md`, `ROADMAP.md`, optional `STYLE.md`, `CHANGELOG.md` |

## Placement Rules

1. **Troubleshooting guides** go in `devops/{product}/troubleshooting/`, never in `docs/`. If a new product needs a troubleshooting section, create `devops/{product}/troubleshooting/`.
2. **Product-specific examples** go in `devops/{product}/examples/`, not in the top-level `examples/` directory.
3. **Research and analysis output** goes in `research/{topic}/`, never in `docs/` or a standalone `analyses/` directory.
4. **Scripts that support a doc or example** live alongside that doc or example, not in the repo root.
5. **The repo root** should only contain repo-level files and the top-level content directories: `README.md`, `AI-DISCLOSURE.md`, `BACKLOG.md`, `BACKLOG-ARCHIVE.md`, `.gitignore`, `.cursorrules`, `.actrc`, `.actrc.example`, `.secrets`, plus `docs/`, `research/`, `library/`, `devops/`, `examples/`, `.cursor/`, `.planning/`. Note: `git-projects/` and `devops/ocp/install/` exist locally but are gitignored.
6. **New products/technologies** go under `devops/{product}/` with appropriate content type subdirectories. For cross-cutting content, prefer fitting into the existing structure.
7. **The `docs/` folder** contains curated essay tracks organized into subdirectories: `ai-engineering/` (skills, workflows, risks), `philosophy/` (martial arts, Zen, applied practice), and `case-studies/` (documented meta-development patterns). Each track has its own `README.md` with a reading order. `docs/README.md` is the master index linking into all tracks. New essays go in their track directory, not in `docs/` root.
8. **The top-level `examples/` folder** is for doc-supporting artifacts (e.g., scripts referenced by essays in `docs/`), not for product-specific examples.
9. **Planning projects** (`.planning/{project}/`) should include a `CHANGELOG.md` that captures *why* scope or framing changed — not just what changed. Git history records the diffs; the changelog captures the user's reasoning and which documents were updated as a set. Format: `## YYYY-MM-DD — [Change title]` with `What changed`, `Why`, and `Documents updated` fields.

## Naming Conventions

- **Product directories:** short lowercase names (`ansible`, `ocp`, `argo`, not `openshift-container-platform`)
- **Content type directories:** lowercase, descriptive (`examples`, `troubleshooting`, `integration`)
- **Leaf directories:** lowercase, hyphen-separated (`aap-controller-token-404`, not `AAP_Controller_Token_404`)
- **Every non-trivial directory** gets a `README.md`
- **Ansible examples** use a numeric prefix: `NNN_description/` (e.g., `devops/ansible/examples/013_smb_to_vault/`)
- **Troubleshooting dirs** use descriptive slugs: `bare-metal-node-inspection-timeout/`, not `issue-47/`
- **Research dirs** use descriptive topic names: `openshift-ai-llm-deployment/`, not `research-1/`

## When Creating New Content

Before writing a new file, ask:

1. Does a product directory for this technology already exist?
2. Does the content type (troubleshooting, example, essay, research) match the subdirectory's purpose?
3. Will the file be discoverable — is it linked from the appropriate README?
4. Is it in the repo root? If so, it probably shouldn't be.

## When Moving Directories (`git mv`)

Path-based `.gitignore` rules break silently on directory moves. After any `git mv`:

1. **Check `git status` before committing** — look for newly-tracked files in directories that should be ignored. Unexpected files appearing are a signal that a `.gitignore` rule stopped matching.
2. **Update the root `.gitignore`** if it has path-based rules for the moved directory.
3. **Prefer local `.gitignore` files** for sensitive or large-file directories — a `.gitignore` inside a directory travels with it on `git mv`, so the rule survives future moves regardless of the parent path.

Any directory containing credentials, kubeconfigs, pull secrets, ISOs, or other sensitive/large files should have a local `.gitignore` as the primary protection. The root `.gitignore` is a secondary layer.

See: [`docs/case-studies/directory-move-gitignore-drift.md`](../../docs/case-studies/directory-move-gitignore-drift.md)

### Internal link depth drift

When a directory is moved one level deeper (e.g. `ocp/` → `devops/ocp/`), every relative link inside that subtree that points *upward* (using `../`) becomes off by one level. This is silent — the files commit cleanly, but the links break.

After any directory move, run a link check on the moved subtree before committing:

```bash
# Replace MOVED_DIR with the destination path, e.g. devops/ocp
find MOVED_DIR -name "*.md" | while read f; do
  dir=$(dirname "$f")
  grep -oP '\]\(\K[^)]+(?=\))' "$f" | grep -v '^https\?://' | grep -v '^http' | while read link; do
    target="${link%%#*}"
    [ -z "$target" ] && continue
    resolved=$(python3 -c "import os,sys; print(os.path.normpath(os.path.join(sys.argv[1],sys.argv[2])))" "$dir" "$target" 2>/dev/null)
    [ ! -e "$resolved" ] && echo "BROKEN: $f -> $link"
  done
done
```

**Key patterns to fix after a one-level-deeper move:**
- Links to `AI-DISCLOSURE.md` (lives at repo root) — each moved file needs one extra `../`
- Sibling-directory cross-links — `../sibling/` becomes `../../sibling/` after adding a level
- Track-crossing links — verify the hop count still reaches the right directory

The `/audit` Layer 1 catches these retrospectively. Run it after any structural reorganization, or scope the check to the moved subtree immediately post-move.
