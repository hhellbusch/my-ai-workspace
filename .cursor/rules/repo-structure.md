# Repository Structure Conventions

This rule defines where content belongs in this repository. Follow these conventions when creating new files, moving existing files, or suggesting organizational changes.

## Directory Map

| Directory | Purpose | New content convention |
|---|---|---|
| `ansible-examples/` | Runnable Ansible playbooks demonstrating patterns | Numbered dirs: `NNN_description/`, each with `README.md` and playbook |
| `ansible-troubleshooting/` | Ansible/AAP troubleshooting guides | Named dirs: `topic-slug/README.md` following symptom → cause → fix structure |
| `argo-examples/` | ArgoCD configurations, app-of-apps patterns, GitOps workflows | Subdirs: `apps/`, `charts/`, `scripts/`, `docs/`, `infrastructure/`, `examples/` |
| `coreos-examples/` | CoreOS/Ignition/Butane configurations | Named dirs with Butane configs and READMEs |
| `docs/` | AI-assisted engineering essays and guides — a cohesive documentation suite | Markdown files linked from `docs/README.md`; no troubleshooting guides here |
| `examples/` | Standalone scripts and artifacts referenced by docs | Named dirs: `topic-slug/` (e.g., `gif-recoloring/`) |
| `git-projects/` | External git repos cloned for exploration and upstream contributions (**gitignored**) | Clone repos directly; not committed to this repo |
| `labs/` | Hands-on lab exercises | Named dirs: `lab-description/` |
| `notes/` | Informal notes and quick references | Markdown files, loosely organized |
| `prompts/` | Structured AI prompt templates for repeatable tasks | Numbered files: `NNN-description.md`; completed outputs go in `completed/` |
| `ocp-examples/` | OpenShift configuration examples and templates | Named dirs with configs and READMEs |
| `ocp-install/` | Local OCP install working directory — contains pull secrets and kubeconfigs (**gitignored**) | Not committed; local use only |
| `ocp-troubleshooting/` | OpenShift troubleshooting guides | Named dirs: `topic-slug/README.md`, same structure as ansible-troubleshooting |
| `research/` | Research workspaces — fetched sources, analysis findings, assessments | One dir per topic: `research/{topic}/` with `manifest.md`, `sources/`, `findings/`, `assessment.md` |
| `rhacm-examples/` | Red Hat Advanced Cluster Management configurations | Named dirs with configs and READMEs |
| `tools/` | Utility scripts not tied to a specific example | Scripts with usage comments |
| `vault-integration/` | HashiCorp Vault integration patterns | Configs and playbooks |

## Placement Rules

1. **Troubleshooting guides** go in `{technology}-troubleshooting/`, never in `docs/`. If a new technology needs a troubleshooting section, create `{tech}-troubleshooting/`.
2. **Research and analysis output** goes in `research/{topic}/`, never in `docs/` or a standalone `analyses/` directory.
3. **Scripts that support a doc or example** live alongside that doc or example, not in the repo root.
4. **The repo root** should only contain repo-level files: `README.md`, `AI-DISCLOSURE.md`, `.gitignore`, `.cursorrules`, `.actrc`, `.actrc.example`, `.secrets`. Note: `git-projects/` and `ocp-install/` exist locally but are gitignored — they hold external clones and sensitive install configs respectively.
5. **New top-level directories** need a clear reason. Prefer fitting content into the existing structure before creating a new directory.
6. **The `docs/` folder** is specifically for the AI-assisted engineering documentation suite. It is a curated, ordered reading list — not a dumping ground for all markdown files.

## Naming Conventions

- **Directory names:** lowercase, hyphen-separated (`aap-controller-token-404`, not `AAP_Controller_Token_404`)
- **Every non-trivial directory** gets a `README.md`
- **Ansible examples** use a numeric prefix: `NNN_description/` (e.g., `013_smb_to_vault/`)
- **Troubleshooting dirs** use descriptive slugs: `bare-metal-node-inspection-timeout/`, not `issue-47/`
- **Research dirs** use descriptive topic names: `openshift-ai-llm-deployment/`, not `research-1/`

## When Creating New Content

Before writing a new file, ask:

1. Does a directory for this topic area already exist?
2. Does the file type (troubleshooting, example, essay, research) match the directory's purpose?
3. Will the file be discoverable — is it linked from the appropriate README?
4. Is it in the repo root? If so, it probably shouldn't be.
