---
review:
  status: unreviewed
  notes: "AI-generated 2026-09-03. Draft for team discussion — AAP render artifact storage and viewing strategies for ACM bare-metal provisioning."
---

# Bare-Metal Cluster Manifest Artifacts — Storage and Viewing Strategies

> **Audience:** Platform engineers running AAP playbooks that render ACM bare-metal provisioning manifests (Jinja → `ClusterDeployment`, `InfraEnv`, `AgentClusterInstall`, etc.)
> **Purpose:** Compare options for storing and viewing rendered manifests from AAP jobs for troubleshooting and audit — without treating renders as Git source of truth

---

## Problem statement

Today an AAP playbook renders ACM provisioning manifests from Jinja templates and inventory (`host_vars` / `group_vars`), then applies them to the hub.
Operators need to inspect what was rendered for a given job — especially when provisioning fails or when auditing who applied what and when.

**Constraint:** Git remains the source of truth for **inputs** (templates, inventory, vars).
Rendered manifests are **build artifacts** — like compiled output in a CI pipeline — not something to commit back to the fleet repo.

---

## Mental model

```
Git (source of truth)          AAP job (build)                 Artifact store (audit)
─────────────────────          ───────────────                 ──────────────────────
templates/*.j2          →      render + validate        →      immutable snapshot
host_vars / group_vars         apply to hub (optional)         indexed by job / cluster
inventory                      job metadata                    retention + search
```

| Layer | Answers |
|-------|---------|
| **Git** | What inputs produced this render? |
| **Artifact store** | What exactly did job N render at time T? |
| **Hub (live CRs)** | What is on the cluster right now? |

All three can differ.
A complete troubleshooting story often needs the artifact (intent at apply time) plus live hub state (what survived or drifted).

---

## On this page

- [Strategy comparison](#strategy-comparison)
- [Recommended combination](#recommended-combination)
- [Implementation patterns](#implementation-patterns)
- [Anti-patterns](#anti-patterns)
- [Decision checklist](#decision-checklist)
- [Related reading](#related-reading)

---

## Strategy comparison

| # | Strategy | Best for | Infra cost | Audit depth | Viewing experience |
|---|----------|----------|------------|-------------|---------------------|
| 1 | Object storage (S3 / MinIO / ODF) | Long-term audit, disconnected fleets | Medium | High | Download or custom viewer |
| 2 | AAP-native artifacts (`set_stats`, job files) | Day-to-day troubleshooting | None | Low–medium | AAP job UI |
| 3 | Render-only job template | Pre-provision review, safe debugging | None | N/A (preview) | Same as 1 or 2 |
| 4 | Hub CRs as post-apply truth | Live state debugging | None | Partial | ACM console / `oc get` |
| 5 | Structured output + external viewer | Team wants multi-file YAML UI | Medium–high | High | Dedicated web UI |
| 6 | Render vs live diff | Drift and partial-apply diagnosis | Low | Medium | AAP job output |
| 7 | Event-driven capture (EDA / webhook) | Decouple storage from playbook | Medium | High | Depends on sink |

---

## Strategy 1 — Object storage (recommended baseline)

Write rendered manifests to object storage during the playbook.
Upload a tarball or per-file tree keyed by cluster and job ID.

### Flow

```text
render to /tmp/<cluster>/
  → validate (optional: kubeconform, yamllint)
  → archive (tar.gz)
  → upload to s3://acm-cluster-artifacts/<cluster>/<job_id>/
  → apply to hub (if not render-only)
  → emit link in job output / notification
```

### Metadata to attach

Every bundle should carry provenance — without this, artifacts are hard to audit:

| Field | Source |
|-------|--------|
| `cluster_name` | inventory / extra_vars |
| `job_id` | `tower_job_id` or `ansible_job_id` |
| `job_template` | `tower_job_template_name` |
| `git_sha` | env var or `git rev-parse` in playbook |
| `rendered_at` | `ansible_date_time.iso8601` |
| `launched_by` | AAP job user |

### Playbook sketch

```yaml
- name: Render manifest bundle
  ansible.builtin.template:
    src: "{{ item.src }}"
    dest: "/tmp/render/{{ cluster_name }}/{{ item.dest }}"
  loop: "{{ manifest_templates }}"

- name: Archive rendered bundle
  ansible.builtin.archive:
    path: "/tmp/render/{{ cluster_name }}"
    dest: "/tmp/{{ cluster_name }}-{{ tower_job_id | default(ansible_job_id) }}.tar.gz"

- name: Upload to object store
  amazon.aws.s3_object:   # or MinIO / rclone equivalent
    bucket: acm-cluster-artifacts
    object: "{{ cluster_name }}/{{ tower_job_id }}/manifests.tar.gz"
    src: "/tmp/{{ cluster_name }}-{{ tower_job_id }}.tar.gz"
    metadata:
      cluster: "{{ cluster_name }}"
      job_id: "{{ tower_job_id | default('') }}"
      git_sha: "{{ git_commit_sha | default('unknown') }}"
```

### Pros

- Immutable, versioned storage with lifecycle policies (30d troubleshooting vs multi-year compliance)
- Git stays clean — no rendered YAML in PRs
- Works disconnected with on-cluster MinIO or ODF
- Searchable by cluster, job ID, timestamp

### Cons

- Requires bucket provisioning, RBAC, and retention policy decisions
- Viewing requires download or a thin viewer layer on top

---

## Strategy 2 — AAP-native artifacts

AAP can surface artifacts from job results without external infrastructure.

### Option A — `set_stats`

```yaml
- name: Capture rendered manifests for job UI
  ansible.builtin.set_stats:
    data:
      cluster_name: "{{ cluster_name }}"
      rendered_manifests:
        infraenv: "{{ lookup('template', 'infraenv.yaml.j2') }}"
        agent_cluster_install: "{{ lookup('template', 'agentclusterinstall.yaml.j2') }}"
    aggregate: true
```

### Option B — Files under runner artifact path

Write rendered files to a path AAP collects automatically as job artifacts.

### Pros

- Zero new infrastructure
- Artifacts visible on the job record in AAP UI
- Fast to adopt alongside existing playbooks

### Cons

- Large multi-file bundles are awkward in the AAP UI
- Retention tied to AAP database / cleanup policies
- Not ideal as the sole long-term audit store at scale

**Use for:** operator troubleshooting.
**Pair with Strategy 1** when audit retention matters.

---

## Strategy 3 — Render-only job template

Split provisioning into two job templates sharing the same Ansible role:

| Job template | Behavior |
|--------------|----------|
| `render-cluster-manifests` | Render + publish artifacts; **no** `kubernetes.core.k8s` apply |
| `provision-baremetal-cluster` | Render + publish + apply |

Alternatively, gate apply with a survey extra var: `dry_run: true`.

### Why this helps

- Operators inspect output before triggering provisioning
- Failed renders are debugged without touching hub CRs
- Same Jinja and inventory as production — no drift between "preview" and "real"

---

## Strategy 4 — Hub CRs as post-apply truth

Once applied, the hub holds live state:

```bash
oc get clusterdeployment,infraenv,agentclusterinstall -n <namespace> -o yaml
```

ACM console and `oc get` are effective for **current** state.

### Gaps

- No record of the exact pre-apply render if templates or inventory changed since
- Secrets may be redacted or transformed on apply
- Partial apply failures leave ambiguous "what was intended vs what landed"

**Use for:** live troubleshooting.
**Do not rely on alone** for point-in-time audit.

---

## Strategy 5 — Structured output + external viewer

Combine object storage (Strategy 1) with a small index file and a viewer:

1. Upload tarball to object storage
2. Write `index.json` alongside it:

```json
{
  "cluster": "prod-bm-01",
  "job_id": 4521,
  "artifact_url": "https://artifacts.example/acm/prod-bm-01/4521/manifests.tar.gz",
  "files": ["infraenv.yaml", "agentclusterinstall.yaml", "clusterdeployment.yaml"],
  "git_sha": "abc123",
  "rendered_at": "2026-09-03T15:00:00Z"
}
```

3. Surface the URL via AAP notification, `set_stats`, or a custom link on the job template
4. Viewer options: internal static app (Monaco / CodeMirror), OpenShift Dev Spaces, or any YAML-aware editor fetching from the bucket

### When to invest

Worth it when AAP job UI is insufficient and the team reviews manifests regularly — not for occasional one-off debugging.

---

## Strategy 6 — Diff against live hub

After render (or on a schedule), compare rendered output to live hub CRs:

```yaml
- name: Fetch live InfraEnv from hub
  kubernetes.core.k8s_info:
    api_version: agent-install.openshift.io/v1beta1
    kind: InfraEnv
    name: "{{ cluster_name }}"
    namespace: "{{ cluster_namespace }}"
  register: live_infraenv

# Diff rendered template output against live_infraenv.resources[0]
```

Surfaces three-way drift: **rendered → applied → live**.
High value when someone hand-edited a CR or a re-run changed template output.

---

## Strategy 7 — Event-driven capture

On AAP job success or failure, Event-Driven Ansible (or a webhook receiver) copies artifacts to long-term storage and writes an audit record (ServiceNow, Elastic, Postgres, etc.).

The playbook only writes to a well-known path; storage logic lives outside the role.

### Pros

- Decouples retention policy from playbook changes
- Central audit sink for multiple job templates

### Cons

- Additional moving parts (EDA rulebook, receiver service)
- Harder to trace end-to-end than inline upload in the playbook

---

## Recommended combination

For troubleshooting **and** audit with Git as input SoT:

| Layer | Choice |
|-------|--------|
| **Inputs** | Git — templates, inventory, `host_vars` / `group_vars` (unchanged) |
| **Preview** | Render-only job template (Strategy 3) |
| **Short-term view** | AAP artifacts (Strategy 2) |
| **Long-term audit** | Object storage with metadata (Strategy 1) |
| **Job linkage** | `set_stats` or notification with artifact URL |
| **Live debug** | Hub CRs / ACM console (Strategy 4) |
| **Drift** | Optional render-vs-live diff (Strategy 6) |

```text
                    ┌─────────────────┐
                    │  Git (inputs)   │
                    └────────┬────────┘
                             │ webhook / manual launch
                             ▼
              ┌──────────────────────────────┐
              │  AAP: render-cluster-manifests │  ← dry run, no apply
              └──────────────────────────────┘
                             │
              ┌──────────────────────────────┐
              │  AAP: provision-baremetal    │  ← render + apply
              └──────────┬───────────────────┘
                         │
           ┌─────────────┼─────────────┐
           ▼             ▼             ▼
    AAP job artifacts  Object store   Hub CRs
    (troubleshoot)     (audit)        (live state)
```

---

## Implementation patterns

### Secrets in rendered output

Rendered manifests often reference Secret names or contain sensitive values from Vault lookups.
Before upload:

- **Redact** values in the artifact copy (keep structure, replace values with `<redacted>`)
- Or **split**: public manifests to object storage; sensitive fragments to Vault with a pointer in metadata
- Never commit renders to Git — same leakage risk applies to poorly scoped artifact ACLs

### Retention

| Tier | Retention | Storage |
|------|-----------|---------|
| Troubleshooting | 30–90 days | AAP artifacts + object storage lifecycle rule |
| Audit / compliance | 1–7 years | Object storage with versioning; WORM if required |

### Disconnected environments

Use on-cluster MinIO or ODF S3-compatible storage.
Same playbook logic; only endpoint and credentials change.

### Idempotency

Rendering from the same Git SHA and inventory should produce the same output.
Record `git_sha` on every artifact bundle so operators can correlate render changes with input changes.

---

## Anti-patterns

| Anti-pattern | Why avoid |
|--------------|-----------|
| Commit renders to Git | Blurs source of truth; PR noise; secret leakage |
| Rely on AAP stdout alone | Unreadable for multi-document YAML; truncated logs |
| Store only on execution node | Ephemeral; lost after job cleanup |
| Git LFS for renders | Still Git; same SoT confusion |
| Hub CRs as sole audit record | Misses pre-apply intent and partial failures |

---

## Decision checklist

Use this when choosing a final design with the team:

1. **Retention** — troubleshooting window (days) vs compliance (years)?
2. **Secrets** — redact in artifacts, or store sensitive fragments separately?
3. **Network** — connected (external S3) or disconnected (on-cluster MinIO)?
4. **Audience** — platform engineers only, or broader ops needing a UI?
5. **Apply gate** — render-only template required before first provision?
6. **Notifications** — who gets the artifact link on success/failure?

---

## Related reading

| Topic | Location |
|-------|----------|
| AAP renders ACM CRs from Jinja | [library: Automate OCP cluster deployment with RHACM and AAP](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md) |
| External pipeline (discover → render → apply) | [bare-metal-lifecycle-hook-patterns.md](./bare-metal-lifecycle-hook-patterns.md) |
| Native ACM → AAP integration | [acm-ansible-integration.md](./acm-ansible-integration.md) |
| Generated vs hand-authored in Git | [git-driven-configuration.md](../git-driven-configuration.md) |
| CIM hub prerequisites | [cim-hub-setup.md](./cim-hub-setup.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
