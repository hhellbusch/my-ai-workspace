# Argo CD Diff Preview with App-of-Apps (and App-of-App-of-Apps)

Troubleshooting and patterns for using [dag-andersen/argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview) with the app-of-apps and app-of-apps-of-apps patterns.

---

## Executive summary (shareable)

**Problem:** We use [argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview) to show manifest diffs on PRs, but with our **app-of-apps (and app-of-apps-of-apps)** layout it doesn’t show the diffs we expect.

**Root cause:** The tool only looks at **Application/ApplicationSet YAML files that already exist** in the repo. It does **one level** of rendering per app (apply app → get manifests → diff). It does **not**:
- See Applications that are **generated** by our root Helm chart (level-2 apps), or
- Recursively render “apps that appear inside another app’s output” (level-3).

So with a root app that renders level-2 apps (and level-2 apps that may render level-3), the tool never discovers those nested apps unless we **pre-render** and put their YAML into the branch folders before running it.

**Status (updated):** A [pull request](https://github.com/dag-andersen/argocd-diff-preview) has been submitted upstream to add **recursive nested Application discovery** to the tool. When merged, the tool will automatically detect and render Applications that appear in another app's rendered output — no pre-rendering step required. See the [limitations section](#limitations-of-recursive-nested-discovery) below for what is and is not covered.

Until the PR is merged, the workaround is to **pre-render** our Helm chart(s) so that the Application YAMLs for level-2 (and optionally level-3) are written into the base and target branch directories, then run argocd-diff-preview. This doc describes both approaches.

---

## Why it doesn’t “just work” for app-of-apps

### How argocd-diff-preview works

1. **Discovery** – It scans the repo (base and target branch folders) for YAML with `kind: Application` or `kind: ApplicationSet`.
2. **Patch & apply** – For each app it patches `targetRevision` (and a few other fields), applies to an ephemeral Argo CD (or uses an existing cluster).
3. **Render** – It runs `argocd app manifests <app-name>` once per app and diffs that output between base and target.

So it only **renders one level**: whatever manifests each discovered Application produces. It does **not** discover Application resources that appear inside another app’s rendered output and render those recursively.

### What that means for your layout

- **Root app** – Often a single Application that points at a Helm chart (e.g. `charts/argocd-apps`). That Application may not even be a static YAML in the repo; it might live in a different repo or be created by an operator.
- **Level-2 apps** – They are **generated** by the root Helm chart, not committed as separate YAML files. So the tool never sees them unless you put them in the repo (or in the mounted branch dir) before running.
- **Level-3 (leaf) apps** – Same idea: if level-2 apps render more Application CRs, those are only visible to the tool if you pre-render and add them to the branch content.

So for app-of-apps (and app-of-apps-of-apps), the tool will only do what you want if you **pre-render** so that every Application you care about exists as YAML in the base/target branch directories the tool sees.

## Official approach: generated applications

From the [argocd-diff-preview docs](https://dag-andersen.github.io/argocd-diff-preview/generated-applications/):

> If your applications are generated from a Helm chart or Kustomize template, you will have to add a step in the pipeline that **renders the chart/template** and places the result in the branch folder.

So the flow is:

1. Checkout base and target (e.g. `main` and PR branch).
2. For **each** branch folder, run your render (e.g. `helm template` for the root chart) and **write the resulting Application YAMLs into that branch folder** (e.g. `base-branch/rendered-apps.yaml` or `target-branch/rendered-apps.yaml`).
3. Run the Docker image with those folders mounted as `/base-branch` and `/target-branch`. The tool will find the Application YAMLs you wrote and render each one; the diff is then accurate for that set of apps.

Without step 2, the tool only sees whatever static Application/ApplicationSet YAMLs are in the repo (e.g. a root app), and you only get one level of diff.

## Quick start: Docker image + pre-render (level-2)

From the repo root, with base and PR branch checkouts in `main/` and `pull-request/`:

```bash
# 1. Pre-render level-2 Application YAMLs into each branch dir
./argo/examples/github-workflows/argocd-diff-preview-prerender.sh main production
./argo/examples/github-workflows/argocd-diff-preview-prerender.sh pull-request production

# 2. Run argocd-diff-preview (Docker)
docker run --rm \
  --network=host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/main:/base-branch \
  -v $(pwd)/pull-request:/target-branch \
  -v $(pwd)/output:/output \
  -e TARGET_BRANCH=your-pr-branch \
  -e REPO=your-org/your-repo \
  dagandersen/argocd-diff-preview:v0.2.0
```

The tool will find the Application manifests in `main/rendered-apps.yaml` and `pull-request/rendered-apps.yaml` and diff what each app renders. See [argocd-diff-preview-prerender.sh](../github-workflows/argocd-diff-preview-prerender.sh). If your chart lives in a subdirectory (e.g. `argo/examples/charts/argocd-apps`), set `CHART_PATH` before running the script: `CHART_PATH=argo/examples/charts/argocd-apps ./argo/examples/github-workflows/argocd-diff-preview-prerender.sh main production`.

## Options for your app-of-apps-of-apps pattern

### Option A: Pre-render level-2 only (use Docker image)

Use the [dag-andersen/argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview) Docker image and a pre-render step so the tool sees **level-2** Applications.

1. Checkout base and target into two dirs (e.g. `main`, `pull-request`).
2. For each dir, run your root Helm chart and write the rendered Application list into that dir, e.g.:
   - `helm template argocd-apps ./charts/argocd-apps --values ... > main/rendered-apps.yaml`
   - Same for the PR branch with PR values.
3. Run the Docker image with `-v $(pwd)/main:/base-branch` and `-v $(pwd)/pull-request:/target-branch` (and `/output`).
4. The tool will discover the level-2 Application YAMLs in `rendered-apps.yaml`, apply them in the ephemeral Argo CD, and run `argocd app manifests` for each. You get:
   - Diff of level-2 Application definitions.
   - Diff of **what each level-2 app renders** (e.g. level-3 Application CRs or raw resources, depending on that app’s source).

If level-2 apps only render raw resources (Deployments, Services, etc.), this is enough. If they render **level-3** Application CRs, you will see those CRs in the diff, but **not** the resources those level-3 apps would deploy, unless you also pre-render level-3 (Option C).

### Option B: Offline script (no Docker, no cluster)

Use (or extend) the existing **offline** diff script in this repo:

- **[scripts/diff-app-of-apps.sh](../scripts/diff-app-of-apps.sh)** – Renders the root chart for two revisions, extracts level-2 child apps, and for each child runs `helm template` (or plain YAML) from the repo. It produces:
  - Parent diff (level-2 Application CRDs).
  - Per–child-app diff (whatever that child’s source renders: level-3 Application CRs or resources).

It does **not** use Argo CD or the Docker image; it only uses `helm`/`yq`/`git`. So it’s ideal for CI without cluster access. It currently covers **two levels** (root → level-2 apps and their rendered output). For a full **three-level** diff (including level-3 app **resource** diffs), you’d extend the script to:

- Parse the rendered output of each level-2 app for `kind: Application`.
- For each level-3 app, resolve its source (path/repo/revision) and run `helm template` (or kustomize) for that revision.
- Diff those level-3 manifests between old and new revision.

See [scripts/README-diff-app-of-apps.md](../scripts/README-diff-app-of-apps.md) for usage and details.

### Option C: Pre-render all levels, then Docker image

To get **full** app-of-apps-of-apps diff (including level-3 **resource** diffs) from argocd-diff-preview:

1. For each branch folder (base and target):
   - Render the root chart → level-2 Application YAMLs; write them into the branch dir.
   - For each level-2 app, run Argo CD render (or replicate with `helm template` for that app’s source path at the right revision). From that output, extract any `Application` resources (level-3), patch `targetRevision` to the branch, and **also** write those into the branch dir.
2. Run argocd-diff-preview with these two folders. It will discover both level-2 and level-3 Application YAMLs, apply them, and run `argocd app manifests` for each. You then get:
   - Level-2 app definition diffs.
   - Level-2 “manifests” diffs (level-3 Application CRs).
   - Level-3 app definition diffs.
   - Level-3 “manifests” diffs (actual Deployment/Service/etc.).

Implementing Option C usually means a custom script or workflow that:

- Runs in CI with two checkouts (base + target).
- For each checkout: root `helm template` → level-2 apps; for each level-2, `helm template` (or Argo CD) → level-3 Application YAMLs; write all into the branch dir.
- Then runs the Docker image. A custom script or workflow step that runs `helm template` for the root chart and for each level-2 app’s source path (at the correct revision), then writes all Application YAMLs into the branch dir, is the starting point for that pre-render step. The same idea as [argocd-diff-preview-prerender.sh](../github-workflows/argocd-diff-preview-prerender.sh) but extended to also render level-2 app sources and extract level-3 Application YAMLs.

## Summary

| Goal | Approach |
|------|----------|
| Level-2 app diffs + what each level-2 app renders | Option A: Pre-render root chart into branch dirs, run argocd-diff-preview Docker image. |
| Full offline 2-level diff, no cluster | Option B: Use `scripts/diff-app-of-apps.sh` (extend for 3-level if you need level-3 resource diffs). |
| Full 3-level diff with Docker image | Option C: Pre-render root + level-2 outputs so level-2 and level-3 Application YAMLs are in branch dirs, then run Docker image. |

## Feasibility: modifying argocd-diff-preview for app-of-apps-of-apps

Yes, the tool can be extended so that it **analyzes the manifests output by each app** and, when those manifests contain `kind: Application`, treats them as nested apps and renders them too. The change is localized to the **extract** step; discovery and diff generation can stay as they are.

### Where the behavior comes from

1. **Discovery (file-only)**  
   Applications are only discovered from the repo files, not from render output:
   - **[pkg/argoapplication/applications.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/pkg/argoapplication/applications.go)** – `GetApplicationsForBranches` → `getApplications` uses `fileparsing.GetYamlFiles` and `fileparsing.ParseYaml` on the branch folder. Only YAML files on disk are considered.
   - **[pkg/argoapplication/conversion.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/pkg/argoapplication/conversion.go)** – `FromResourceToApplication` / `fromK8sResource` turn parsed resources into `ArgoResource`; only `Application` and `ApplicationSet` are accepted.

2. **Apply → wait → get manifests (single level)**  
   For each discovered app the tool applies it, waits for reconciliation, then gets manifests once:
   - **[pkg/extract/extract.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/pkg/extract/extract.go)** – `RenderApplicationsFromBothBranches` calls `getResourcesFromApps`, which loops over the app list and, for each app, calls `getResourcesFromApp`. There is no second pass over the **output** of those apps.
   - **`getResourcesFromApp`** (same file) – Applies the app YAML, polls until reconciled, then calls **`getManifestsFromApp`**, which uses `argocd.GetManifests(app.Id)` to get the rendered manifests. The result is turned into an `ExtractedApp` and returned. The code never inspects those manifests for nested `Application` resources.
   - **`getManifestsFromApp`** (same file) – Returns `[]unstructured.Unstructured`. This is the right place to add: “filter this list for `kind == Application` (and optionally `ApplicationSet`), convert each to `ArgoResource`, and queue them for the same apply/wait/getManifests flow.”

### Where to implement recursive behavior

- **Primary change: [pkg/extract/extract.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/pkg/extract/extract.go)**  
  After obtaining manifests for an app (in **`getResourcesFromApp`** or **`getResourcesFromApps`**), add a step that:
  1. Scans the returned `[]unstructured.Unstructured` for objects with `kind: Application` (and optionally `ApplicationSet`).
  2. Converts each to `argoapplication.ArgoResource` (same shape as file-discovered apps: `Yaml`, `Kind`, `Id`, `Name`, `FileName`, `Branch`). Use the parent app’s `Branch`; set `FileName` to something like `"<parent-name>/rendered"` for traceability.
  3. Applies the same patching used for file-discovered apps (namespace, project, destination, syncPolicy, etc.) so Argo CD accepts them. Patching logic lives in **[pkg/argoapplication/patching.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/pkg/argoapplication/patching.go)**; you can reuse or factor out a function that takes an `ArgoResource` and patch map.
  4. Appends these nested apps to the list of apps to process, and continues the same apply → wait → getManifests loop (either by pushing onto a queue and draining it, or by doing a second pass over the current level’s extracted manifests before returning).

  To avoid infinite loops and duplicate work:
  - Deduplicate by app ID (and branch) so the same nested app is only rendered once per branch.
  - Optionally cap recursion depth (e.g. 2–3 levels) or allow a flag to enable/disable “nested app discovery.”

- **Data flow**  
  The rest of the pipeline already supports “more apps, more ExtractedApps”: **`getResourcesFromApps`** returns `[]ExtractedApp` per branch; **`diff.GeneratePreview`** in **[cmd/main.go](https://github.com/dag-andersen/argocd-diff-preview/blob/main/cmd/main.go)** takes those slices and produces the diff. So once nested apps are turned into `ExtractedApp` entries (each with its own manifests), the existing diff and output logic will show them as additional apps in the report.

- **Repo-server path**  
  If you use **`reposerverextract.RenderApplicationsFromBothBranches`** (repo server API instead of cluster apply), the same idea applies: wherever that path gets manifests for an app, add a step to parse those manifests for `Application`/`ApplicationSet`, convert to `ArgoResource`, apply the same patching, and feed them into the same rendering pipeline. The repo-server extract logic is in **[pkg/reposerverextract](https://github.com/dag-andersen/argocd-diff-preview/tree/main/pkg/reposerverextract)**.

### Summary

| Goal | Location | Change |
|------|----------|--------|
| Discover nested apps from render output | **pkg/extract/extract.go** | After `getManifestsFromApp` (or inside `getResourcesFromApps`), parse manifests for `Application`/`ApplicationSet`, convert to `ArgoResource`, patch, and add to the set of apps to process. |
| Reuse patching for nested apps | **pkg/argoapplication/patching.go** | Use or extract a function that patches an `ArgoResource` so it can be applied to the ephemeral cluster (namespace, project, destination, etc.). |
| Dedupe / limit recursion | **pkg/extract/extract.go** | Track processed app IDs (and branch); skip already-seen; optionally cap depth. |
| Diff and output | **cmd/main.go**, **pkg/diff** | No change needed; extra `ExtractedApp` entries are already diffed and included in the report. |

So the desired behavior (analyze manifests output by the apps originally picked up, and recursively render nested Applications) is feasible and is achieved by extending the extract step in **pkg/extract/extract.go** and reusing application patching from **pkg/argoapplication/patching.go**.

---

## Limitations of recursive nested discovery

These limitations apply to the upstream PR implementation. They are worth understanding before adopting the feature.

### 1. Cross-repository sources are not branch-aware

For a nested app's rendered content to reflect your **PR branch**, its `spec.source.repoURL` must match the `--repo` parameter passed to the tool (i.e. it must live in the same GitOps repository as your PR).

When an app's `repoURL` points at a **different** repository:
- Its source files are fetched from the remote repository at its specified `targetRevision` (e.g. `HEAD` on `main`), **not** from your PR branch.
- Any nested Applications that app produces are still discovered, but are also rendered from remote content.

**In practice** this is only a problem if your level-2 or level-3 app definitions live in a different repo. The common pattern — all Application manifests in the same GitOps repo — works fully.

| App's `repoURL` | Content rendered | Nested apps discovered? |
|---|---|---|
| Matches `--repo` (PR repo) | Your PR branch content | Yes |
| Different repo | Remote repo at `targetRevision` | Yes, but not from your branch |

### 2. Nested `ApplicationSet` resources are not discovered

Only `kind: Application` is detected in rendered output. Nested `ApplicationSet` resources are not picked up by the recursive discovery step. Top-level ApplicationSets continue to be handled by the existing pre-processing step.

### 3. Depth cap

Recursion is capped at **5 levels**. This covers all known real-world layouts. The cap prevents infinite loops if app sources accidentally create cycles.

---

## References

- [argocd-diff-preview – How it works](https://dag-andersen.github.io/argocd-diff-preview/how-it-works/)
- [argocd-diff-preview – Generated applications](https://dag-andersen.github.io/argocd-diff-preview/generated-applications/)
- [App-of-Apps pattern](./patterns/APP-OF-APPS-PATTERN.md) in this repo
- [diff-app-of-apps script](../scripts/README-diff-app-of-apps.md) in this repo
