---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# ArgoCD Diff Preview Workflow Diagram

## Workflow Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Creates PR                        │
│                  (modifies apps/ or charts/)                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Actions Workflow Triggers                   │
│          (argocd-diff-preview.yml or both workflows)            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  Workflow 1: Template    │  │  Workflow 2: Live Diff   │
│  Comparison (No Cluster) │  │  (Requires Cluster Auth) │
└────────────┬─────────────┘  └────────────┬─────────────┘
             │                              │
             ▼                              ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│ 1. Checkout PR branch    │  │ 1. Checkout PR branch    │
│ 2. Generate PR manifests │  │ 2. Connect to ArgoCD     │
│ 3. Checkout base branch  │  │ 3. Run argocd app diff   │
│ 4. Generate base manifes │  │ 4. Get live differences  │
│ 5. Create unified diff   │  │                          │
└────────────┬─────────────┘  └────────────┬─────────────┘
             │                              │
             ▼                              ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│ Upload Artifacts:        │  │ Upload Artifacts:        │
│ - PR manifests           │  │ - Live diffs             │
│ - Base manifests         │  │ - Summary                │
│ - Unified diffs          │  │                          │
└────────────┬─────────────┘  └────────────┬─────────────┘
             │                              │
             └────────────┬─────────────────┘
                          │
                          ▼
             ┌────────────────────────┐
             │   Post Comment to PR   │
             │   with Diff Preview    │
             └────────────┬───────────┘
                          │
                          ▼
             ┌────────────────────────┐
             │  Reviewer Examines     │
             │  Diff and Approves     │
             └────────────┬───────────┘
                          │
                          ▼
             ┌────────────────────────┐
             │    PR is Merged        │
             └────────────┬───────────┘
                          │
                          ▼
             ┌────────────────────────┐
             │  ArgoCD Auto-Sync      │
             │  Applies Changes       │
             └────────────────────────┘
```

## Workflow 1: Template Comparison (Recommended)

```
PR Branch                                Base Branch
    │                                         │
    ├─> Checkout                              ├─> Checkout
    │                                         │
    ├─> Helm Template                         ├─> Helm Template
    │   - values.yaml                         │   - values.yaml
    │   - values-production.yaml              │   - values-production.yaml
    │                                         │
    ├─> manifests-pr/                         ├─> manifests-base/
    │   └── production.yaml                   │   └── production.yaml
    │                                         │
    └─────────────┬───────────────────────────┘
                  │
                  ▼
            ┌──────────┐
            │   diff   │
            └────┬─────┘
                 │
                 ▼
        ┌────────────────┐
        │  Unified Diff  │
        │  production.diff│
        └────────┬───────┘
                 │
                 ▼
        ┌─────────────────┐
        │  PR Comment +   │
        │  Artifacts      │
        └─────────────────┘
```

## Workflow 2: Live Diff (Advanced)

```
PR Branch                          Live ArgoCD Cluster
    │                                      │
    ├─> Checkout                           │
    │                                      │
    ├─> Login to ArgoCD ──────────────────►│
    │   (using ARGOCD_AUTH_TOKEN)          │
    │                                      │
    ├─> List Applications ◄────────────────┤
    │                                      │
    ├─> For each affected app:             │
    │   │                                  │
    │   ├─> argocd app diff ──────────────►│
    │   │   --revision PR_SHA              │
    │   │                                  │
    │   └─> Get live diff ◄────────────────┤
    │       (compares PR vs cluster)       │
    │                                      │
    └────────┬──────────────────────────────
             │
             ▼
    ┌─────────────────┐
    │  Aggregate diffs│
    │  per app        │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │  PR Comment +   │
    │  Artifacts      │
    └─────────────────┘
```

## Detailed Step-by-Step: Template Comparison

```
Step 1: Trigger
───────────────
    Event: pull_request
    Conditions:
      ✓ Target branch: main/master/develop
      ✓ Changed paths: apps/**, infrastructure/**, charts/**

Step 2: Detect Environment
───────────────────────────
    Check which values files changed:
      - values-development.yaml → test development
      - values-staging.yaml     → test staging
      - values-production.yaml  → test production
    
    If apps/** changed → test all environments

Step 3: Generate PR Manifests
──────────────────────────────
    For each environment:
      helm template argocd-apps ./charts/argocd-apps \
        --values values.yaml \
        --values values-${env}.yaml \
        > manifests-pr/${env}.yaml

Step 4: Generate Base Manifests
────────────────────────────────
    git checkout origin/${base_branch}
    
    For each environment:
      helm template argocd-apps ./charts/argocd-apps \
        --values values.yaml \
        --values values-${env}.yaml \
        > manifests-base/${env}.yaml
    
    git checkout ${pr_branch}

Step 5: Generate Diffs
──────────────────────
    For each environment:
      diff -u \
        manifests-base/${env}.yaml \
        manifests-pr/${env}.yaml \
        > diffs/${env}.diff

Step 6: Create Comment
──────────────────────
    Format:
      ## 🔍 ArgoCD Diff Preview
      
      ### Environment: production
      <details>
        <summary>View diff (N lines)</summary>
        ```diff
        ... diff content ...
        ```
      </details>

Step 7: Upload Artifacts
────────────────────────
    Artifact: argocd-diff-preview
      ├── manifests-pr/
      │   ├── development.yaml
      │   ├── staging.yaml
      │   └── production.yaml
      ├── manifests-base/
      │   ├── development.yaml
      │   ├── staging.yaml
      │   └── production.yaml
      ├── diffs/
      │   ├── development.diff
      │   ├── staging.diff
      │   └── production.diff
      └── diff-summary.md
```

## Environment Detection Logic

```
┌─────────────────────────────────────┐
│    Changed Files in PR              │
└────────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────┐
    │ values-dev.yaml?    │─ Yes ─► Check development
    └─────────┬───────────┘
              │ No
              ▼
    ┌─────────────────────┐
    │ values-staging.yaml?│─ Yes ─► Check staging
    └─────────┬───────────┘
              │ No
              ▼
    ┌─────────────────────┐
    │ values-prod.yaml?   │─ Yes ─► Check production
    └─────────┬───────────┘
              │ No
              ▼
    ┌─────────────────────┐
    │ apps/** or          │
    │ infrastructure/** or│─ Yes ─► Check all environments
    │ charts/**?          │
    └─────────┬───────────┘
              │ No
              ▼
    ┌─────────────────────┐
    │ Skip workflow       │
    │ (no relevant changes)│
    └─────────────────────┘
```

## Integration with GitOps Flow

```
Developer Workflow:
──────────────────

1. Developer makes changes
   └─> git checkout -b feature/update-app
   └─> Edit apps/my-app/deployment.yaml
   └─> git commit -m "Update app to v2.0"
   └─> git push origin feature/update-app

2. Create Pull Request
   └─> PR opened on GitHub
   └─> GitHub Actions triggered

3. Review Process
   ├─> CI/CD runs tests
   ├─> ArgoCD diff preview generated ◄── THIS WORKFLOW
   ├─> Security scans run
   └─> Team reviews PR + diff

4. Approval & Merge
   └─> Reviewer approves
   └─> PR merged to main

5. ArgoCD Sync (Auto)
   ├─> ArgoCD detects Git change (within ~3 min)
   ├─> Compares desired state vs actual state
   ├─> Applies changes to cluster
   └─> Updates app status

6. Monitoring
   └─> Team monitors deployment
   └─> ArgoCD shows sync status
   └─> Apps become healthy
```

## Comparison: Template vs Live Diff

```
┌──────────────────────┬────────────────────┬─────────────────────┐
│     Aspect           │  Template Diff     │    Live Diff        │
├──────────────────────┼────────────────────┼─────────────────────┤
│ Cluster Access       │ ❌ Not required    │ ✅ Required         │
│ ArgoCD Credentials   │ ❌ Not required    │ ✅ Required         │
│ Speed                │ ⚡ Fast (~30s)     │ 🐢 Slower (~60s)    │
│ Setup Complexity     │ ⭐ Simple          │ ⭐⭐⭐ Complex      │
│ Security Risk        │ ✅ Very low        │ ⚠️  Medium          │
│ Accuracy             │ 📊 Template-based  │ 🎯 Actual state     │
│ Offline Testing      │ ✅ Yes             │ ❌ No               │
│ Shows Drift          │ ❌ No              │ ✅ Yes              │
│ Multi-Environment    │ ✅ Yes             │ ✅ Yes              │
│ Recommended For      │ 🎯 Most teams      │ Advanced use cases  │
└──────────────────────┴────────────────────┴─────────────────────┘
```

## Error Handling Flow

```
┌─────────────────────────────────────┐
│  Workflow Execution                 │
└────────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────┐
    │ Helm template fails?│─ Yes ─┐
    └─────────┬───────────┘       │
              │ No                 │
              ▼                    ▼
    ┌─────────────────────┐   ┌────────────────┐
    │ Diff generation     │   │ Post error to  │
    │ successful?         │   │ PR comment     │
    └─────────┬───────────┘   │ Show logs      │
              │ No             │ Mark as failed │
              │ Yes            └────────────────┘
              ▼
    ┌─────────────────────┐
    │ No changes detected?│─ Yes ─┐
    └─────────┬───────────┘       │
              │ No                 │
              ▼                    ▼
    ┌─────────────────────┐   ┌────────────────┐
    │ Diff > 500 lines?   │   │ Post "No       │
    └─────────┬───────────┘   │ changes"       │
              │ Yes            │ message        │
              │ No             └────────────────┘
              ▼
    ┌─────────────────────┐
    │ Truncate in comment │
    │ Full diff in artifact│
    └─────────┬───────────┘
              │
              ▼
    ┌─────────────────────┐
    │ Post complete       │
    │ comment to PR       │
    └─────────────────────┘
```

## Security Model

```
GitHub Secrets (Encrypted)
────────────────────────────
    ARGOCD_AUTH_TOKEN
    ARGOCD_SERVER
          │
          ├─> Only accessible during workflow execution
          ├─> Not visible in logs
          └─> Not accessible to forks (for security)
          
Workflow Permissions
────────────────────
    ├─> contents: read      (read Git repo)
    ├─> pull-requests: write (post comments)
    └─> None for cluster operations (template workflow)

ArgoCD Service Account (Live Diff)
──────────────────────────────────
    ├─> Read-only access to applications
    ├─> Cannot modify cluster state
    ├─> Cannot access secrets
    └─> Limited to 'argocd' namespace
```

---

## Key Takeaways

✅ **Workflow 1 (Template)** is recommended for most use cases
- No cluster access required
- Fast and secure
- Easy to set up

⚡ **Workflow 2 (Live)** is for advanced scenarios
- Shows real-time cluster diff
- Accounts for manual changes
- Requires additional setup

🔒 **Security First**
- Use read-only tokens
- Minimize permissions
- Rotate credentials regularly

📊 **Review Before Merge**
- Always check the diff preview
- Download artifacts for detailed review
- Test in lower environments first

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
