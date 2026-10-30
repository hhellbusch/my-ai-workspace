---
review:
  status: unreviewed
  notes: "Drafted 2026-10-15. Cutover preview: hand-authored manifest tree to a rendered tree, compared to live objects with argocd app diff --local. Commands not run against a cluster in this session."
---

# Rendered-manifest cutover — diff the new tree against live state

> **Audience:** Platform engineers moving an Argo CD fleet from a hand-authored manifest tree to a second tree that CI renders from Helm (or similar) and commits as plain YAML.
>
> **Purpose:** Choose how to see what the first sync will change on the cluster before an Application's source path moves.

---

## The situation

Two trees exist during the migration.

`clusters/` is what Argo CD syncs today.
Most of it was written by hand.
Applications point at paths under that tree.

`clusters-fleet-managed/` is the replacement.
A Helm chart renders it, and CI writes the YAML into Git.
After cutover, Argo CD applies those files as a directory source.

The directory names are examples.
The same preview applies whenever the new desired state is already-rendered YAML at a different path or repo than the Application currently tracks.

The comparison that decides the cutover is the new tree against the objects the cluster is running.
A diff of the two Git trees answers whether the renderer reproduced the old files.
Live objects drift from those files, and the first sync writes that drift.

---

## Which question this answers

Nearby questions use different tools.
Mixing them up produces a clean diff for the wrong pair of states.

| Question | What you compare | Tool |
|---|---|---|
| What does this pull request change in Git? | New desired state vs current desired state | [argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview), or a structural diff of the two trees. See [diffing and visibility](examples/helm-component-pattern/docs/diffing-and-visibility.md). |
| Which apps are out of sync with the path they already track? | Live objects vs the Git path on the Application today | `argocd app list`, the Argo CD UI |
| What will the replacement tree change on the cluster before we retarget the Application? | Live objects vs the new rendered tree | `argocd app diff --local` on the existing Application |

This note is the third row.

---

## Why the usual diff misses the new tree

`argocd app diff <app> --revision <ref>` swaps the git ref.
The path, repo URL, and include rules stay on the live Application, so the command keeps reading `clusters/`.
A values-file or path change that exists only in a new revision of the Application spec has the same limit ([argo-cd#6942](https://github.com/argoproj/argo-cd/issues/6942), written up under [multiple sources](examples/docs/patterns/MULTIPLE-SOURCES-PATTERN.md#understanding-argocd-app-diff---local)).

A second Application pointed at `clusters-fleet-managed/`, with sync left off, shares the live objects with the existing app.
Tracking annotations disagree.
When the old app has self-heal, the new app's UI is a poor preview.

`kubectl diff` and a recursive diff of the two directories compare YAML to the API, or to the old files, without Argo CD's normalizer.
Ignore rules and resource tracking stay out of that result.
Use them as a second opinion.

---

## Preview with the existing Application

Keep the existing Application.
Point only the desired side of the diff at a local checkout of the rendered tree.

```bash
argocd app diff my-cluster-app \
  --local ./clusters-fleet-managed/prod-1/my-app \
  --server-side-generate
```

`--local` supplies the desired state from disk.
The live side stays the objects that Application already owns, on the cluster it already targets.
The new repo does not need to be registered in Argo CD until the Application source actually moves.

`--server-side-generate` uploads that path to the repo server, which generates manifests using the live Application's source type, then diffs them there.
That matches this cutover when the Application is a directory source and the path is plain YAML.
Generation then collects those files, and the diff uses the app's ignore rules and compare options.

Drop `--server-side-generate` when the live Application is still a Helm or Kustomize source.
With the flag, the repo server templates the upload as a chart or kustomization.
Without it, the CLI reads `*.yaml`, `*.yml`, and `*.json` as final manifests.
That is the right read for an already-rendered tree sitting next to a Helm-typed Application.
Flag behavior is in the [command reference](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_diff/).
Local generation is described under [diff strategies](https://argo-cd.readthedocs.io/en/latest/user-guide/diff-strategies/) (the "Local diff with server-side generation" section).

The CLI exits 0 when it finds no differences, 1 when it does, and 2 on a general error.
A script that treats every non-zero exit as "has a diff" hides auth failures and bad paths.
`--diff-exit-code` can separate a real diff from other failures; confirm the flags on the CLI version you run.

`argocd app diff` omits Kubernetes Secrets.
A secret-only change can look clean.

### Scope the path to one Application

Pass the directory that Application will sync after the path change.
A whole cluster tree mixes in resources other apps own, and the diff fills with adds and deletes a real sync would not perform.

Match the file set to `directory.include`, `directory.exclude`, and `directory.recurse` on the Application.
`--local` loads YAML, YML, and JSON under the path.
With `--server-side-generate`, `--local-include` replaces that default set entirely.
Re-specify any patterns you still want.
The Application's directory globs are a separate filter.
Files Argo CD would skip still show up as desired objects when they are in the uploaded set.

### Read the diff in three buckets

- **Adds and deletes.** Deletes become prunes when the new sync policy has prune enabled. Review them on their own.
- **Spec changes.** These are what the first sync will write.
- **Render noise.** Helm label helpers (`app.kubernetes.io/managed-by`, chart, heritage) appear when the templates include them and the hand-authored files do not. Change the template, or accept the write. Leave the rest of the diff in review.

### What this preview leaves out

`--local` replaces the desired manifests.
It leaves the Application spec on the live object: project, destination namespace, sync options, `ignoreDifferences`, and directory include/exclude.
When cutover changes those fields, compare the Application manifests on their own.
A parent app-of-apps diff shows the path change as an Application spec edit.
That line is the cutover itself.

If the app syncs with server-side apply, the preview should use the same diff strategy the controller will use on sync.
Current Argo CD uses server-side diff for that case.
The CLI follows the `ServerSideDiff` compare option when it is set; `--server-side-diff` forces it.
See [diff strategies](https://argo-cd.readthedocs.io/en/stable/user-guide/diff-strategies/).

---

## Order of checks

Run a structural diff of `clusters/` against `clusters-fleet-managed/` first.
That needs no cluster credentials.
It catches renderer bugs: dropped resources, renamed keys, values the template did not thread through.
Key order and Helm labels show up here; triage them once.

Then run `argocd app diff --local` per Application.
That is the preview of the first sync.

`kubectl diff --server-side -f <rendered-dir>` is the check when the Argo CD diff looks empty and you want the API server's opinion, or when no Application owns those objects yet.
Admission webhooks participate in a server-side diff; they stay out of a client-side `argocd app diff` unless server-side diff is on.

---

## Cutover

Leave automated sync and prune off.
When the `--local` diff is acceptable, change that Application's `spec.source.path` from `clusters/...` to `clusters-fleet-managed/...`, and `repoURL` if the repo moved.

Run `argocd app diff` with no `--local`.
An empty result means the path swap is a no-op sync.
Workloads stay as they are until someone syncs.

Rollback is reverting that source path in Git.

The Argo CD UI shows the same comparison after the live Application's path changes, with automated sync and prune still off.
That edits the Application object.
`--local` does not.
Revert the path in Git if the UI diff is not acceptable.

Throughout, the same Application objects remain, and cutover changes their source.
When the new tree is one directory per cluster and the old tree is one directory per app, the `--local` path has to follow the layout the new Application will use.

---

## Related

- [Multiple sources — `argocd app diff --local`](examples/docs/patterns/MULTIPLE-SOURCES-PATTERN.md#understanding-argocd-app-diff---local) — what `--local` changes, and why `--revision` keeps the live spec
- [Diffing and visibility](examples/helm-component-pattern/docs/diffing-and-visibility.md) — pull-request desired-vs-desired diffs, and fleet health after apps already track a path
- [Argo CD diff preview with app-of-apps](examples/docs/ARGOCD-DIFF-PREVIEW-APP-OF-APPS.md) — desired-vs-desired when Applications are generated
- [`argocd app diff` command reference](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd_app_diff/)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
