# Fleet Management Framework — Operator's Guide

A learning path and operations manual for system administrators and operators
managing OpenShift clusters through this GitOps framework.

**No coding experience required.** This guide starts from first principles and
builds up to real-world operations step by step.

> **AI Disclosure:** This guide was created with AI assistance.

---

## Table of Contents

- [Learning Path Overview](#learning-path-overview)
- [Part 1: Understanding GitOps](#part-1-understanding-gitops)
  - [1.1 The Old Way vs. The GitOps Way](#11-the-old-way-vs-the-gitops-way)
  - [1.2 The Core GitOps Principles](#12-the-core-gitops-principles)
  - [1.3 Why GitOps for Cluster Management](#13-why-gitops-for-cluster-management)
  - [1.4 Key Vocabulary](#14-key-vocabulary)
- [Part 2: Git for Operators](#part-2-git-for-operators)
  - [2.1 What Is Git (And Why Should You Care)](#21-what-is-git-and-why-should-you-care)
  - [2.2 Setup and First Steps](#22-setup-and-first-steps)
  - [2.3 The Daily Git Workflow](#23-the-daily-git-workflow)
  - [2.4 Branches — The Key to Safe Changes](#24-branches--the-key-to-safe-changes)
  - [2.5 Pull Requests — Your Change Request](#25-pull-requests--your-change-request)
  - [2.6 Resolving Mistakes](#26-resolving-mistakes)
- [Part 3: Understanding the Framework](#part-3-understanding-the-framework)
  - [3.1 The Big Picture](#31-the-big-picture)
  - [3.2 How the Pieces Connect](#32-how-the-pieces-connect)
  - [3.3 The Value Cascade (How Settings Are Resolved)](#33-the-value-cascade-how-settings-are-resolved)
  - [3.4 YAML — The Configuration Language](#34-yaml--the-configuration-language)
  - [3.5 Understanding the File Structure](#35-understanding-the-file-structure)
- [Part 4: Day-to-Day Operations](#part-4-day-to-day-operations)
  - [4.1 Changing a Setting on One Cluster](#41-changing-a-setting-on-one-cluster)
  - [4.2 Changing a Setting Across All Production Clusters](#42-changing-a-setting-across-all-production-clusters)
  - [4.3 Enabling an App on a Cluster](#43-enabling-an-app-on-a-cluster)
  - [4.4 Disabling an App on a Cluster](#44-disabling-an-app-on-a-cluster)
  - [4.5 Adding a Worker Node to a Bare Metal Cluster](#45-adding-a-worker-node-to-a-bare-metal-cluster)
  - [4.6 Onboarding a New Cluster](#46-onboarding-a-new-cluster)
  - [4.7 Promoting Changes Through Environments](#47-promoting-changes-through-environments)
  - [4.8 Rolling Back a Bad Change](#48-rolling-back-a-bad-change)
  - [4.9 Handling an Emergency Hotfix](#49-handling-an-emergency-hotfix)
- [Part 5: Troubleshooting](#part-5-troubleshooting)
  - [5.1 My Change Isn't Showing Up](#51-my-change-isnt-showing-up)
  - [5.2 ArgoCD Shows "OutOfSync"](#52-argocd-shows-outofsync)
  - [5.3 The CI Pipeline Failed](#53-the-ci-pipeline-failed)
  - [5.4 A Cluster Isn't Getting an App](#54-a-cluster-isnt-getting-an-app)
  - [5.5 Values Aren't What I Expected](#55-values-arent-what-i-expected)
- [Quick Reference Card](#quick-reference-card)

---

## Learning Path Overview

This guide is structured as a learning path. If you are new to Git and GitOps,
start from Part 1 and work through sequentially. If you already understand Git
but are new to this framework, skip to Part 3.

```
Your experience level:              Start here:
─────────────────────────────────────────────────
Never used Git                       Part 1 (GitOps concepts)
Used Git, new to GitOps              Part 1, Section 1.2
Familiar with GitOps, new here       Part 3 (Framework)
Know the framework, need reference   Part 4 (Operations)
Something is broken                  Part 5 (Troubleshooting)
Just need the commands               Quick Reference Card
```

---

## Part 1: Understanding GitOps

### 1.1 The Old Way vs. The GitOps Way

**The Old Way (imperative):**

You log into a server or console and run commands to make changes. You might
SSH into a machine, run `oc label`, edit a ConfigMap, or click through a web
console. The problem? Nobody knows exactly what changed, when, or why. If
something breaks at 2 AM, you are digging through shell histories and hoping
someone documented what they did.

Think of it like renovating a house by just showing up and doing work without
blueprints. It might work — until you need to explain what you did, undo a
mistake, or have someone else pick up where you left off.

**The GitOps Way (declarative):**

Instead of running commands, you describe the **desired state** of your systems
in files, store those files in Git, and let automation make reality match the
files. You never touch the live system directly. If you want to change
something, you change the file and let the system converge.

Think of it like updating the blueprint first, then having a contractor
(ArgoCD) automatically build what the blueprint says. The blueprint is always
the truth. If someone makes an unauthorized change to the building, the
contractor notices and reverts it.

```
THE OLD WAY                          THE GITOPS WAY
───────────                          ──────────────
1. SSH into cluster                  1. Edit a YAML file in Git
2. Run oc command                    2. Commit the change
3. Hope it works                     3. Open a Pull Request
4. Try to remember what you did      4. Reviewers approve
5. Document it... maybe              5. Merge the PR
                                     6. ArgoCD applies automatically
                                     7. Full audit trail forever
```

### 1.2 The Core GitOps Principles

There are four principles. You do not need to memorize them, but understanding
them will help everything else click.

**1. Declarative Configuration**

You describe *what* you want, not *how* to get there. Instead of saying "run
these 12 commands to install monitoring," you write a file that says "monitoring
should be enabled with 30 days of retention." The tooling figures out the how.

**2. Versioned and Immutable**

Every change is a Git commit with a timestamp, author, and message. You can see
who changed what, when, and why — going back to the beginning of time. You
cannot secretly change the past. This is your audit trail.

**3. Pulled Automatically**

ArgoCD continuously watches the Git repository. When it sees a change, it pulls
it and applies it. You do not need to push or trigger anything manually. Commit
to Git and walk away — the system converges.

**4. Continuously Reconciled**

ArgoCD does not just apply changes once. It continuously compares the live
state of the cluster against what Git says it should be. If someone manually
changes something on a cluster (drift), ArgoCD detects it and reverts the
change back to what Git says. Git is always the truth.

```
This loop runs continuously:

    ┌──── Git Repository ◄────── You edit files here
    │         │
    │         │  ArgoCD watches
    │         ▼
    │    ArgoCD compares
    │    Git state vs. Live state
    │         │
    │         │  Different? Apply changes.
    │         │  Same? Do nothing.
    │         ▼
    └──── Live Cluster ──────── Self-heals automatically
```

### 1.3 Why GitOps for Cluster Management

When you manage 5, 50, or 500 clusters, GitOps solves real problems:

| Problem                               | GitOps Solution                                        |
|---------------------------------------|--------------------------------------------------------|
| "Who changed the production config?"  | Git log shows every change with author and timestamp   |
| "Can we undo the last change?"        | Revert the Git commit — ArgoCD rolls back automatically |
| "Is staging the same as production?"  | Compare Git branches — they are the source of truth    |
| "We need to apply this to all clusters" | Edit one group file — all clusters pick it up         |
| "Someone manually changed a cluster"  | ArgoCD detects drift and reverts it automatically      |
| "New team member needs to learn"      | Everything is in readable YAML files, not in someone's head |

### 1.4 Key Vocabulary

You will see these terms throughout this guide and in team discussions.

| Term                   | Plain English                                                      |
|------------------------|--------------------------------------------------------------------|
| **Repository (repo)**  | A folder tracked by Git. Contains all your config files.           |
| **Commit**             | A saved snapshot of changes. Like a checkpoint in a video game.    |
| **Branch**             | A parallel version of the repo. Like a draft copy you can edit without affecting the original. |
| **Pull Request (PR)**  | A proposal to merge your branch into another. This is how changes get reviewed and approved. |
| **Merge**              | Accepting a PR — the changes from your branch are applied to the target branch. |
| **ArgoCD**             | The tool that watches Git and applies changes to clusters.         |
| **RHACM**              | Red Hat Advanced Cluster Management. Manages the fleet of clusters from one hub. |
| **Hub cluster**        | The central cluster that runs ArgoCD and RHACM. The brain.        |
| **Spoke cluster**      | A managed cluster. Does not run ArgoCD — receives config from the hub. |
| **ApplicationSet**     | An ArgoCD resource that generates one Application per cluster.     |
| **Helm**               | A templating tool for Kubernetes YAML. Like mail merge for cluster config. |
| **Values file**        | A YAML file that provides variables to a Helm template.            |
| **Cascade**            | The priority order in which values files are merged. Cluster > Group > App defaults. |
| **Sync**               | When ArgoCD applies the Git state to the live cluster.             |
| **Drift**              | When the live cluster state differs from what Git says. ArgoCD fixes this. |
| **Reconciliation**     | The process of comparing Git to live state and fixing differences. |

---

## Part 2: Git for Operators

### 2.1 What Is Git (And Why Should You Care)

Git is a version control system. It tracks every change to every file over time.
Think of it as an unlimited, automatic changelog for your configuration files.

**You already understand the concept.** If you have ever:
- Saved a file as `config-backup-2024-01-15.yaml` before editing it
- Kept a running log of changes you made to a system
- Wished you could see what a config looked like last Tuesday

Then you understand why Git exists. Git does all of this automatically, for
every file, forever, with zero effort after the initial setup.

**What you actually interact with:**
- A folder on your computer containing the framework files
- A few commands to save and share your changes
- A web interface (GitHub/GitLab) for reviewing and approving changes

### 2.2 Setup and First Steps

**First-time setup** (do this once):

```bash
# Tell Git who you are (use your real name and company email)
git config --global user.name "Jane Smith"
git config --global user.email "jane.smith@example.com"

# Clone (download) the repository to your computer
git clone https://github.com/YOUR-ORG/YOUR-REPO.git
cd YOUR-REPO
```

You now have a local copy of all the framework files. This is your workspace.

**Verify it worked:**

```bash
# Show the current state — should say "nothing to commit, working tree clean"
git status

# Show recent changes by others
git log --oneline -10
```

### 2.3 The Daily Git Workflow

Every time you sit down to make a change, follow this pattern:

```
Step 1: Pull         Get the latest changes from the team
Step 2: Branch       Create a working copy for your change
Step 3: Edit         Make your changes to the YAML files
Step 4: Commit       Save a snapshot with a description
Step 5: Push         Upload your changes to the server
Step 6: PR           Open a Pull Request for review
Step 7: Merge        After approval, merge the PR
```

Here is each step in detail:

**Step 1: Pull the latest changes**

Always start by pulling. This ensures you are working with the latest version.

```bash
git checkout main
git pull origin main
```

*What this does:* Switches you to the main branch and downloads any changes
others have made since you last pulled.

**Step 2: Create a branch for your work**

Never edit `main` directly. Always create a branch.

```bash
git checkout -b feature/add-silence-for-xyz
```

*What this does:* Creates a new branch called `feature/add-silence-for-xyz`
based on the latest `main`, and switches to it. Your changes will live on this
branch until you are ready to merge them.

**Branch naming suggestions:**
- `feature/add-monitoring-retention` — adding something new
- `fix/correct-storage-class-prod-east` — fixing a problem
- `update/ocp-415-prometheus-version` — updating a value
- `onboard/new-cluster-west-2` — adding a new cluster

**Step 3: Edit the files**

Use any text editor you are comfortable with. VS Code, vim, nano — whatever
works for you. The files are plain text YAML.

```bash
# Open a file in your editor
vim clusters/example-prod-east-1/values.yaml
```

**Step 4: Commit your changes**

A commit is a saved snapshot. Always include a meaningful message.

```bash
# See what you changed
git status

# See the actual line-by-line changes
git diff

# Stage the files you want to include in this commit
git add clusters/example-prod-east-1/values.yaml

# Save the commit with a message
git commit -m "update: increase monitoring retention to 30d on prod-east-1"
```

**Writing good commit messages:**

| Good                                          | Bad                       |
|-----------------------------------------------|---------------------------|
| "update: increase monitoring retention to 30d" | "fixed stuff"            |
| "fix: correct storage class for prod-east-1"  | "changes"                |
| "feat: enable cert-manager on dev-1"           | "updated values"         |
| "onboard: add new cluster prod-west-2"         | "new file"               |

The message should answer: *"If I read this in 6 months, will I understand
what changed and why?"*

**Step 5: Push your branch to the server**

```bash
git push origin feature/add-silence-for-xyz
```

*What this does:* Uploads your branch and commits to the shared server
(GitHub/GitLab) where others can see it.

**Step 6: Open a Pull Request**

Go to the GitHub/GitLab web interface, or use the command line:

```bash
gh pr create \
  --base main \
  --head feature/add-silence-for-xyz \
  --title "Update: increase monitoring retention on prod-east-1" \
  --body "Increasing retention from 15d to 30d per CHANGE-1234."
```

*What this does:* Creates a formal proposal to merge your changes into `main`.
Others can review your changes, leave comments, and approve.

**Step 7: After approval, merge**

Once approved, click "Merge" in the web interface (or use `gh pr merge`).
Your changes are now on `main` and ArgoCD will pick them up on the lab
environment automatically.

### 2.4 Branches — The Key to Safe Changes

Branches are what make GitOps safe. Think of them as parallel drafts of the
configuration.

```
main (lab)                Your branch
    │                         │
    │  ┌── You branch off ────┘
    │  │
    │  │   You make changes on your branch
    │  │   (main is unaffected)
    │  │
    │  │   You open a PR
    │  │   Others review
    │  │
    │  └── Merge back ────────┐
    │                         │
    ▼                         ▼
  main now has your changes
```

**Why branches matter:**
- Your half-finished changes never affect the live system
- Multiple people can work on different changes simultaneously
- You can abandon a bad idea by simply deleting the branch
- Every change gets reviewed before it reaches any cluster

**The environment branches:**

This framework uses branches to control which environment sees which changes:

```
main                    = Lab environment (experimentation)
release/dev             = Dev environment (integration testing)
release/staging         = Staging environment (pre-production soak)
release/production      = Production environment (live fleet)
```

A change on `main` is invisible to production. It only reaches production
when you promote it through each stage via Pull Requests.

### 2.5 Pull Requests — Your Change Request

A Pull Request (PR) is the GitOps equivalent of a change request. It is where:

- Your changes are displayed as a readable diff (what was added/removed)
- Automated tests (CI) validate your YAML and Helm templates
- Team members review and comment on your changes
- Approvals are tracked (1 for staging, 2 for production)
- The merge is recorded permanently

**Anatomy of a good PR:**

```
Title:   "Update: increase monitoring retention to 30d on prod-east-1"
Body:    "Per CHANGE-1234, the platform team needs 30 days of metrics
          retention on prod-east-1 for capacity planning.

          Changed:
          - clusters/example-prod-east-1/values.yaml: retention 15d → 30d

          Tested in: lab ✓, dev ✓
          Risk: Low — only affects one cluster's retention setting"
```

**Reviewing a PR (for reviewers):**

1. Read the description — does the "why" make sense?
2. Check the diff — do the file changes match what the description says?
3. Look at CI results — did the automated tests pass?
4. If it is a staging/production promotion, verify it has been tested in the
   previous environment first
5. Approve or request changes

### 2.6 Resolving Mistakes

Everyone makes mistakes. Git makes fixing them safe.

**"I committed to the wrong branch"**

```bash
# You are on main but should have been on a feature branch
# First, undo the commit (keep the changes)
git reset --soft HEAD~1

# Create the correct branch
git checkout -b feature/my-actual-branch

# Re-commit on the correct branch
git add . && git commit -m "your message"
```

**"I need to undo my last commit"**

```bash
# Undo the last commit but keep the file changes
git reset --soft HEAD~1

# If you also want to undo the file changes
git reset --hard HEAD~1
```

**"I want to throw away all my local changes and start fresh"**

```bash
git checkout main
git pull origin main
# Delete your branch if you do not need it
git branch -D feature/my-abandoned-branch
```

**"I pushed something bad and it is on main"**

Do not panic. Open a PR that reverts the change. See
[Section 4.8: Rolling Back a Bad Change](#48-rolling-back-a-bad-change).

---

## Part 3: Understanding the Framework

### 3.1 The Big Picture

This framework manages a fleet of OpenShift clusters from a single control
point (the RHACM hub). Here is the entire system in one picture:

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Git Repository                             │
│                                                                     │
│   groups/         clusters/          apps/          pipelines/      │
│   (shared         (per-cluster       (what gets     (CI/CD          │
│    settings)       identity +         deployed)      automation)    │
│                    overrides)                                       │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                    ArgoCD watches Git
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    RHACM Hub Cluster                                 │
│                                                                     │
│   ArgoCD reads the config from Git and generates one Application    │
│   per cluster per app. RHACM provides the cluster inventory.        │
│                                                                     │
│   Think of the hub as the "control tower" — it sees everything      │
│   and sends instructions to each cluster.                           │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
               ArgoCD deploys to each spoke
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                     ▼
    ┌──────────┐       ┌──────────┐          ┌──────────┐
    │ Cluster  │       │ Cluster  │          │ Cluster  │
    │ prod-e-1 │       │ prod-w-1 │          │ dev-1    │
    │          │       │          │          │          │
    │ Receives │       │ Receives │          │ Receives │
    │ its apps │       │ its apps │          │ its apps │
    └──────────┘       └──────────┘          └──────────┘
```

**The key insight:** You never log into a spoke cluster to configure it. You
edit files in Git, and the hub automatically applies the right configuration to
the right clusters.

### 3.2 How the Pieces Connect

There are four major directories you will work with:

**`clusters/`** — One folder per cluster. Contains:
- `cluster.yaml` — Who is this cluster? What groups is it in? What apps does it get?
- `values.yaml` — What are this specific cluster's unique settings?

**`groups/`** — Shared settings for groups of clusters:
- `all/values.yaml` — Every cluster gets these defaults
- `env-production/values.yaml` — All production clusters share these settings
- `ocp-4.15/values.yaml` — All 4.15 clusters share these settings

**`apps/`** — The applications that get deployed:
- `cert-manager/` — TLS certificate management
- `cluster-monitoring/` — Prometheus, Alertmanager, metrics
- `baremetal-hosts/` — Worker node management for bare metal clusters
- etc.

**`pipelines/`** — CI/CD automation:
- Validates your changes before they go live
- Handles promotion between environments

```
YOU WORK HERE:                    THE SYSTEM HANDLES:
──────────────                    ───────────────────
clusters/<name>/cluster.yaml      → Labels on the cluster
clusters/<name>/values.yaml       → Cluster-specific settings
groups/<group>/values.yaml        → Shared settings for a group
                                  → Merging values in the right order
                                  → Deploying the right apps
                                  → Detecting and reverting drift
```

### 3.3 The Value Cascade (How Settings Are Resolved)

This is the most important concept in the framework. When a setting needs to
be determined for a cluster, the system looks at multiple files in a specific
order. **The last file to define a value wins.**

Think of it like getting dressed in layers:

```
Layer 1 (innermost):  App defaults        "Monitoring retention is 7 days"
Layer 2:              All-cluster group    "Actually, make it 7 days" (same)
Layer 3:              Environment group    "For production, make it 30 days"
Layer 4:              OCP version group    (does not override retention)
Layer 5:              Infrastructure group (does not override retention)
Layer 6 (outermost):  Cluster-specific    "For THIS cluster, make it 15 days"
```

**Result for this cluster: 15 days** (the cluster-specific value wins).

**Practical example:**

Imagine `monitoring.retention` for cluster `prod-east-1`:

| File                                  | Sets retention to | Wins? |
|---------------------------------------|-------------------|-------|
| `apps/cluster-monitoring/values.yaml` | 7d                | No    |
| `groups/all/values.yaml`              | 7d                | No    |
| `groups/env-production/values.yaml`   | 30d               | No    |
| `groups/ocp-4.15/values.yaml`         | _(not set)_       | —     |
| `clusters/prod-east-1/values.yaml`    | 15d               | **Yes** |

The cluster file has the final say. If the cluster file did not set retention,
the production group value (30d) would win. If that was also absent, the
all-clusters default (7d) would win.

**The golden rule:** Set common values in groups. Set exceptions in the cluster
file. Only add something to the cluster file if it is different from what the
groups already define.

### 3.4 YAML — The Configuration Language

All configuration in this framework is written in YAML. YAML is a plain-text
format designed to be human-readable. Here is everything you need to know:

**Basic structure — key-value pairs:**

```yaml
name: prod-east-1
environment: production
region: us-east
```

*Translation:* "The name is prod-east-1, the environment is production, the
region is us-east."

**Nested values (indentation matters):**

```yaml
cluster:
  name: prod-east-1
  ocp:
    version: "4.15"
    infrastructure: baremetal
```

*Translation:* "The cluster's name is prod-east-1. The cluster's OCP version
is 4.15 and infrastructure is baremetal."

YAML uses **spaces for indentation** (not tabs). Always use 2 spaces per level.

**Lists (arrays):**

```yaml
workers:
  - name: worker-0
    role: worker
  - name: worker-1
    role: worker
  - name: gpu-worker-0
    role: gpu
```

*Translation:* "There are three workers. The first two are regular workers,
the third is a GPU worker."

**Booleans (true/false):**

```yaml
features:
  certManager:
    enabled: true
  logging:
    enabled: false
```

**Strings that look like numbers — use quotes:**

```yaml
ocp:
  version: "4.15"    # Quotes keep this as text, not the number 4.15
```

**Common YAML mistakes:**

| Mistake                          | Fix                                    |
|----------------------------------|----------------------------------------|
| Used tabs instead of spaces      | Use only spaces (2 per indent level)   |
| Forgot a colon after a key       | `name: value` not `name value`         |
| Wrong indentation                | Children are exactly 2 spaces deeper   |
| Forgot quotes around version     | `version: "4.15"` not `version: 4.15`  |
| Trailing spaces after a value    | Delete invisible trailing whitespace   |

**How to check your YAML before committing:**

```bash
# Install yamllint (one-time)
pip install yamllint

# Check a file
yamllint clusters/prod-east-1/values.yaml
```

The CI pipeline also checks YAML syntax automatically when you open a PR.

### 3.5 Understanding the File Structure

Here is a guided tour of what matters to you as an operator. Files marked
with **(you edit this)** are the ones you will touch day-to-day. Files marked
with **(do not edit)** are managed by automation or the platform team.

```
framework/
│
├── clusters/                          ← YOUR PRIMARY WORKSPACE
│   ├── _template/                     (you edit this) template for new clusters
│   │   ├── cluster.yaml               (you edit this) fill in cluster identity + labels
│   │   └── values.yaml                (you edit this) fill in cluster settings
│   ├── example-prod-east-1/
│   │   ├── cluster.yaml               (you edit this) cluster identity + labels
│   │   └── values.yaml                (you edit this) cluster-specific settings
│   └── example-nonprod-dev-1/
│       ├── cluster.yaml               (you edit this)
│       └── values.yaml                (you edit this)
│
├── groups/                            ← SHARED SETTINGS
│   ├── all/values.yaml                (you edit this) defaults for every cluster
│   ├── env-production/values.yaml     (you edit this) production-specific settings
│   ├── env-non-production/values.yaml (you edit this) non-production settings
│   ├── ocp-4.14/values.yaml           (you edit this) 4.14-specific settings
│   ├── ocp-4.15/values.yaml           (you edit this) 4.15-specific settings
│   └── infra-baremetal/values.yaml    (you edit this) bare metal cluster settings
│
├── apps/                              ← WHAT GETS DEPLOYED
│   ├── cert-manager/                  (platform team manages)
│   ├── cluster-monitoring/            (platform team manages)
│   ├── cluster-logging/               (platform team manages)
│   ├── external-secrets/              (platform team manages)
│   ├── baremetal-hosts/               (platform team manages)
│   └── nvidia-gpu-operator/           (platform team manages)
│
├── hub/                               ← HUB INFRASTRUCTURE
│   ├── bootstrap/                     (do not edit) initial setup
│   ├── applicationsets/               (do not edit) auto-managed
│   └── rhacm/                         (do not edit) RHACM config
│
├── pipelines/                         ← CI/CD AUTOMATION
│   ├── promotion/README.md            (reference) promotion procedure
│   └── github-actions/                (do not edit) pipeline definitions
│
├── automation/                        ← ANSIBLE PLAYBOOKS
│   └── ansible/                       (advanced) onboarding automation
│
└── docs/
    └── OPERATORS-GUIDE.md             ← YOU ARE HERE
```

---

## Part 4: Day-to-Day Operations

This section covers the operations you will perform most frequently. Each
operation is a complete, copy-paste-ready procedure.

### 4.1 Changing a Setting on One Cluster

**Scenario:** You need to change the monitoring retention on `prod-east-1`
from 15 days to 30 days.

**Which file to edit:** `clusters/example-prod-east-1/values.yaml`
(cluster-specific values always go in the cluster's `values.yaml`)

**Procedure:**

```bash
# Step 1: Get the latest code
git checkout main
git pull origin main

# Step 2: Create a branch for your change
git checkout -b update/prod-east-1-retention

# Step 3: Edit the file
```

Open `clusters/example-prod-east-1/values.yaml` and find the monitoring
section. Change the retention value:

```yaml
# Before
  features:
    monitoring:
      retention: 15d

# After
  features:
    monitoring:
      retention: 30d
```

```bash
# Step 4: Check what you changed
git diff

# Step 5: Commit
git add clusters/example-prod-east-1/values.yaml
git commit -m "update: increase monitoring retention to 30d on prod-east-1

Per CHANGE-1234, capacity planning requires 30 days of metrics."

# Step 6: Push
git push origin update/prod-east-1-retention

# Step 7: Open a PR
gh pr create --base main \
  --title "Update: monitoring retention 30d on prod-east-1" \
  --body "Per CHANGE-1234. Changes only prod-east-1 retention."
```

After the PR is merged to `main`, the change is live in the lab environment.
Then promote it through dev, staging, and production
(see [Section 4.7](#47-promoting-changes-through-environments)).

### 4.2 Changing a Setting Across All Production Clusters

**Scenario:** You need to increase the default monitoring retention for all
production clusters from 30 days to 45 days.

**Which file to edit:** `groups/env-production/values.yaml`
(changes to all clusters in a group go in the group's `values.yaml`)

**Procedure:**

```bash
git checkout main && git pull origin main
git checkout -b update/production-retention-45d
```

Edit `groups/env-production/values.yaml`:

```yaml
# Before
  features:
    monitoring:
      retention: 30d

# After
  features:
    monitoring:
      retention: 45d
```

```bash
git add groups/env-production/values.yaml
git commit -m "update: increase production monitoring retention to 45d"
git push origin update/production-retention-45d
gh pr create --base main \
  --title "Update: production monitoring retention to 45d"
```

**Important:** Any cluster that has `monitoring.retention` set in its own
`clusters/<name>/values.yaml` will keep its cluster-specific value. The group
change only affects clusters that do not have a cluster-level override.

### 4.3 Enabling an App on a Cluster

**Scenario:** You want to enable `cert-manager` on `example-nonprod-dev-1`.

This requires two changes: the label (which tells ArgoCD to deploy the app)
and the feature flag (which tells the chart to render resources).

**Files to edit:**
1. `clusters/example-nonprod-dev-1/cluster.yaml` — add the label
2. `clusters/example-nonprod-dev-1/values.yaml` — enable the feature

**Procedure:**

```bash
git checkout main && git pull origin main
git checkout -b feature/enable-cert-manager-dev-1
```

Edit `clusters/example-nonprod-dev-1/cluster.yaml`:

```yaml
# Add to the apps.enabled section:
  apps:
    enabled:
      cert-manager: true         # ← add this line
      cluster-logging: true

# Add to managedClusterLabels:
  managedClusterLabels:
    # ... existing labels ...
    app.enabled/cert-manager: "true"    # ← add this line
```

Edit `clusters/example-nonprod-dev-1/values.yaml`:

```yaml
# Add or update the features section:
  features:
    certManager:
      enabled: true              # ← enable the feature
      issuer: letsencrypt-staging
      email: platform-team@example.com
```

Then regenerate the label aggregation, commit, and open a PR:

```bash
# Regenerate the aggregated labels
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework

git add clusters/example-nonprod-dev-1/
git add hub/rhacm/cluster-labels/values.yaml
git commit -m "feat: enable cert-manager on example-nonprod-dev-1"
git push origin feature/enable-cert-manager-dev-1
gh pr create --base main --title "Enable cert-manager on dev-1"
```

### 4.4 Disabling an App on a Cluster

**Scenario:** You want to stop `cluster-monitoring` (an opt-out app that is on
by default) on `example-nonprod-dev-1`.

**Files to edit:**
1. `clusters/example-nonprod-dev-1/cluster.yaml` — add the disable label
2. Optionally: `clusters/example-nonprod-dev-1/values.yaml` — set enabled: false

**Procedure:**

Edit `cluster.yaml` — add to `apps.disabled` and `managedClusterLabels`:

```yaml
  apps:
    disabled:
      cluster-monitoring: true

  managedClusterLabels:
    # ... existing labels ...
    app.disabled/cluster-monitoring: "true"
```

Regenerate labels, commit, PR — same flow as enabling an app.

### 4.5 Adding a Worker Node to a Bare Metal Cluster

**Scenario:** A new Dell R750 server arrived for `prod-east-1`. You need to
add it as `worker-5` with iDRAC at `10.20.1.15`.

**Prerequisites:**
- BMC credentials must be provisioned in Vault (the onboarding playbook does this,
  or your vault admin can add them manually at
  `secret/fleet/bmc/example-prod-east-1/worker-5`)
- The server must be physically racked, cabled, and powered on

**File to edit:** `clusters/example-prod-east-1/values.yaml`

**Procedure:**

```bash
git checkout main && git pull origin main
git checkout -b feature/add-worker-5-prod-east-1
```

Edit `clusters/example-prod-east-1/values.yaml`. Find the `workers:` list and
add the new entry at the end:

```yaml
    workers:
      # ... existing workers ...

      - name: worker-5
        role: worker
        hardwareProfile: dell-r750
        bmc:
          address: "idrac-virtualmedia+https://10.20.1.15/redfish/v1/Systems/System.Embedded.1"
          disableCertificateVerification: true
        bootMACAddress: "AA:BB:CC:01:00:05"
        rootDeviceHints:
          deviceName: "/dev/sda"
```

Make sure to also provision the BMC credentials in Vault:

```bash
# Run the Ansible playbook to provision the BMC secret
ansible-playbook automation/ansible/onboard-cluster.yaml \
  -e cluster_name=example-prod-east-1 \
  -e '{"baremetal_hosts": [{"name": "worker-5", "bmc_address": "10.20.1.15"}]}' \
  --tags bmc
```

Or ask your vault admin to create the secret at:
`secret/fleet/bmc/example-prod-east-1/worker-5`
with keys: `username: root`, `password: <the-idrac-password>`

Then commit and PR:

```bash
git add clusters/example-prod-east-1/values.yaml
git commit -m "feat: add worker-5 to prod-east-1

New Dell R750 in RACK-42, iDRAC at 10.20.1.15"
git push origin feature/add-worker-5-prod-east-1
gh pr create --base main --title "Add worker-5 to prod-east-1"
```

After the PR is merged and promoted to production, ArgoCD will:
1. Create the ExternalSecret (pulls BMC creds from Vault)
2. Create the BareMetalHost resource
3. Metal3 operator contacts iDRAC and begins provisioning the node

### 4.6 Onboarding a New Cluster

**Automated method (recommended):**

Go to GitHub Actions, select the **Onboard New Cluster** workflow, and click
**Run workflow**. Fill in the form:

| Field              | Example Value                                     |
|--------------------|---------------------------------------------------|
| Cluster name       | `prod-west-2`                                     |
| Environment        | `production`                                      |
| OCP version        | `4.15`                                            |
| Region             | `us-west`                                         |
| Server URL         | `https://api.prod-west-2.example.com:6443`        |
| Infrastructure     | `baremetal`                                        |
| Ingress domain     | `apps.prod-west-2.example.com`                    |
| Storage class      | `ocs-storagecluster-ceph-rbd`                     |
| Enabled apps       | `cert-manager,external-secrets,baremetal-hosts`    |

The pipeline creates all the files, provisions Vault secrets, and opens a PR.
You review, merge, and promote through environments.

**Manual method:** See the cluster README at `clusters/README.md` for the
step-by-step CLI procedure.

### 4.7 Promoting Changes Through Environments

Changes on `main` only affect the lab environment. To move them to production,
you promote through each stage.

**The simple version:**

```
Lab (main) → Dev → Staging → Production
```

Each promotion is a Pull Request from one branch to the next.

**Using the automated Promote workflow:**

1. Go to GitHub Actions
2. Select **Promote to Environment**
3. Choose the target environment (dev, staging, or production)
4. Optionally select "Dry run" to preview what would be promoted
5. Click **Run workflow**
6. The pipeline creates a PR. Review and merge.

**Manual promotion:**

```bash
# Promote from main (lab) to dev:
gh pr create --base release/dev --head main \
  --title "Promote to dev: <describe changes>" \
  --body "Changes tested in lab. Ready for dev."

# After dev testing, promote from dev to staging:
gh pr create --base release/staging --head release/dev \
  --title "Promote to staging: <describe changes>" \
  --body "Validated in dev. Ready for staging soak."

# After staging soak, promote from staging to production:
gh pr create --base release/production --head release/staging \
  --title "Promote to production: <describe changes>" \
  --body "Soaked in staging for X days. Ready for production."
```

**Approval requirements:**
- Lab and Dev: No approvals (CI must pass)
- Staging: 1 reviewer must approve
- Production: 2 reviewers must approve

### 4.8 Rolling Back a Bad Change

If a change causes problems after being merged:

**Step 1: Identify the bad PR** — find it in the GitHub/GitLab PR history.

**Step 2: Create a revert:**

```bash
# Find the merge commit hash from the PR
git log --oneline -10

# Create a revert commit
git checkout main
git pull origin main
git checkout -b revert/bad-change
git revert <merge-commit-hash>
git push origin revert/bad-change

# Open a PR to merge the revert
gh pr create --base main \
  --title "Revert: roll back <describe what went wrong>"
```

**Step 3: Fast-track to production** — if the bad change is already in
production, the revert PR must be promoted to `release/production` immediately.
Use the standard promotion path but flag it as urgent to get faster reviews.

ArgoCD picks up the revert and rolls back the affected clusters automatically.
No SSH needed. No manual commands. The revert is just another commit.

### 4.9 Handling an Emergency Hotfix

For critical production issues that cannot wait for the full promotion cycle:

```bash
# Branch directly from production (not from main)
git fetch origin
git checkout -b hotfix/critical-fix origin/release/production

# Make the minimal fix
vim clusters/prod-east-1/values.yaml

# Commit and push
git add . && git commit -m "hotfix: disable feature X causing outage"
git push origin hotfix/critical-fix

# PR directly to production (still requires 2 approvals, but team knows to expedite)
gh pr create --base release/production --head hotfix/critical-fix \
  --title "HOTFIX: disable feature X causing outage"
```

**After the hotfix is merged to production, back-port to main:**

```bash
git checkout main && git pull origin main
git cherry-pick <hotfix-commit-hash>
git push origin main
```

This ensures the fix is in all environments, not just production.

---

## Part 5: Troubleshooting

### 5.1 My Change Isn't Showing Up

**Checklist:**

1. **Did you merge the PR?** Changes on a branch do not affect anything until
   the PR is merged.

2. **Which branch did you merge to?** If you merged to `main`, the change is
   only in lab. Promote to the target environment.

3. **Did ArgoCD sync?** Check the ArgoCD web console on the hub. The
   Application should show "Synced" and "Healthy."
   ```bash
   oc get applications -n openshift-gitops | grep <app-name>
   ```

4. **Is `ignoreMissingValueFiles` set?** If a value file path references a
   label that does not exist on the cluster, the file is silently skipped.
   Check that the cluster has the right labels.

5. **Is the value being overridden?** A higher-priority file might be setting
   the same value. Check the cascade order (Section 3.3).

### 5.2 ArgoCD Shows "OutOfSync"

"OutOfSync" means the live cluster state differs from what Git says.

**Common causes:**
- ArgoCD has not synced yet (wait a minute, or click "Sync" manually)
- Someone made a manual change on the cluster (ArgoCD will revert it
  automatically if `selfHeal` is enabled)
- The Helm template is producing resources that differ from what is on the
  cluster (check the ArgoCD diff view)

**To investigate:**

```bash
# Check the Application status
oc get application <app-name> -n openshift-gitops -o yaml | grep -A 5 status

# Check ArgoCD events
oc get events -n openshift-gitops --sort-by='.lastTimestamp' | tail -20
```

### 5.3 The CI Pipeline Failed

The CI pipeline validates your changes before they are merged. Common failures:

| Error                              | Meaning                                    | Fix                                      |
|------------------------------------|--------------------------------------------|------------------------------------------|
| **YAML lint failed**               | Syntax error in your YAML                  | Check indentation, colons, quotes        |
| **Helm lint failed**               | Invalid Helm chart                         | Usually a template issue — ask platform team |
| **Cluster config validation failed** | Missing required field in cluster.yaml   | Check that name, env, ocpVersion are set |
| **Name mismatch**                  | cluster.name does not match directory name  | Ensure they are identical                |
| **Label mismatch**                 | managedClusterLabels does not match groups | Make labels consistent with groups/apps  |

### 5.4 A Cluster Isn't Getting an App

**Check 1: Does the cluster have the right label?**

For opt-in apps, the cluster needs `app.enabled/<app>: "true"` in its
`cluster.yaml` and `managedClusterLabels`.

```bash
# Check labels on the ManagedCluster
oc get managedcluster <cluster-name> --show-labels
```

**Check 2: Was the label aggregation run?**

After editing `cluster.yaml`, you must regenerate the label aggregation:

```bash
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework
```

**Check 3: Is the ApplicationSet seeing the cluster?**

```bash
# List all Applications generated by the ApplicationSet
oc get applications -n openshift-gitops -l app=<app-name>
```

### 5.5 Values Aren't What I Expected

When a value is not what you expect, trace the cascade:

```bash
# Template the chart with all value files in cascade order to see the result
helm template <app-name> apps/<app-name>/ \
  --values apps/<app-name>/values.yaml \
  --values groups/all/values.yaml \
  --values groups/env-production/values.yaml \
  --values groups/ocp-4.15/values.yaml \
  --values clusters/<cluster-name>/values.yaml
```

This shows you the final rendered YAML. Search for the value you are
investigating to see what it resolved to.

**Remember:** For map values (key-value pairs), Helm deep-merges — a deeper
file's keys override shallower ones. For lists (arrays of items like workers),
Helm **replaces** the entire list — the last file to define the list wins
completely.

---

## Quick Reference Card

Print this page and keep it at your desk.

### Everyday Commands

```bash
# Start of day — get latest code
git checkout main && git pull origin main

# Create a branch for your change
git checkout -b <type>/<short-description>

# See what you changed
git status                    # which files changed
git diff                      # line-by-line changes

# Commit your changes
git add <file>                # stage a file
git commit -m "message"       # save the snapshot

# Push and create PR
git push origin <branch-name>
gh pr create --base main --title "Title" --body "Description"

# Regenerate labels after editing cluster.yaml
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework
```

### Which File Do I Edit?

| I want to change...                        | Edit this file                              |
|--------------------------------------------|---------------------------------------------|
| A setting on one specific cluster          | `clusters/<name>/values.yaml`               |
| A setting on all production clusters       | `groups/env-production/values.yaml`          |
| A setting on all clusters                  | `groups/all/values.yaml`                     |
| A setting on all 4.15 clusters             | `groups/ocp-4.15/values.yaml`                |
| A setting on all bare metal clusters       | `groups/infra-baremetal/values.yaml`         |
| Which apps a cluster gets                  | `clusters/<name>/cluster.yaml`               |
| Which group a cluster belongs to           | `clusters/<name>/cluster.yaml`               |
| Add a worker to a bare metal cluster       | `clusters/<name>/values.yaml` (workers list) |

### Promotion Cheat Sheet

```
main (lab) ──PR──▶ release/dev ──PR──▶ release/staging ──PR──▶ release/production
  0 approvals       0 approvals        1 approval            2 approvals
```

### Branch Naming

```
feature/  — adding something new
update/   — changing an existing setting
fix/      — correcting a problem
onboard/  — adding a new cluster
hotfix/   — emergency production fix
revert/   — undoing a bad change
```

### Commit Message Format

```
<type>: <what changed>

<why it changed — ticket number, context>
```

Examples:
- `update: increase monitoring retention to 30d on prod-east-1`
- `feat: enable cert-manager on dev-1`
- `fix: correct storage class for prod-west-2`
- `onboard: add new cluster prod-west-2`
- `hotfix: disable feature X causing outage`
