# Fleet Management — Ideas & Future Work

> **Audience:** Workspace owner — review queue, not a committed roadmap
> **Status:** Living log · last updated 2026-06-25
> **Scope:** Documentation and framework follow-ups from fleet control spectrum / RHACM-as-code work

Items here are **candidates for later**.
Nothing in this file is in-flight unless it also appears in [BACKLOG.md](../../BACKLOG.md) or an active epic.

---

## How to use this log

| Column | Meaning |
|--------|---------|
| **Type** | `doc` = documentation only · `framework` = code/manifest changes in `argo/examples/framework/` · `governance` = ACM policy design · `workshop` = customer/stakeholder material |
| **Signal** | Rough priority when you pick something up — not a schedule |

---

## Documentation

| ID | Idea | Signal | Notes |
|----|------|--------|-------|
| D-1 | **Commit & publish** `git-driven-configuration.md` + spectrum cross-links | Now | Uncommitted as of 2026-06-25 |
| D-2 | **Workshop one-pager** — fleet control spectrum visuals (ASCII or mermaid) for customer conversations | Medium | Four persona anchors on primary axis; see [fleet-control-spectrum.md](fleet-control-spectrum.md) |
| D-3 | **Additional spectrum axes** — promotion model (trunk vs branch-per-env), blast radius / sync safety | Low | Mentioned in brainstorm; not yet in spectrum doc |
| D-4 | **Executive vs architect framing** — same barometers, different end labels | Low | "Organizational maturity" vs "tool posture" |
| D-5 | **Per-concern worksheet** as printable / workshop handout | Medium | Export table from spectrum doc; NMState/OAuth/kubeadmin examples |
| D-6 | **Rebuild test runbook** — "fresh hub + Git only" acceptance procedure | Medium | Tied to [git-driven-configuration.md](rhacm/git-driven-configuration.md) rebuild narrative |
| D-7 | **Public onboarding guide** — distill private cluster-onboarding epic into devops runbook when lab path is proven | Later | Source: `private/drafts/cluster-onboarding/team-guide.md`; docs follow doing |
| D-8 | **PolicyGenerator how-to** in-repo — kustomize plugin + CI render step | Medium | Link from git-driven-configuration; upstream docs exist but no workspace example yet |
| D-9 | **Argo tracking prerequisite** — short ops note for `application.resourceTrackingMethod` on OpenShift GitOps | High | Required before policies-as-code via Argo; see [ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md](argo/examples/docs/patterns/ARGOCD-RHACM-POLICY-GENERATED-RESOURCES.md) |

---

## Framework (defer — adjust later)

| ID | Idea | Signal | Notes |
|----|------|--------|-------|
| F-1 | **`hub-rhacm-integration` Argo Application** — sync `GitOpsCluster`, `Placement`, `ManagedClusterSet` from Git (wave `-10`) | High | Files exist under `framework/hub/rhacm/` but comments still say `oc apply` |
| F-2 | **`hub/rhacm/integration/` directory** — move integration YAML out of flat `hub/rhacm/` | Low | Layout described in git-driven-configuration; optional refactor |
| F-3 | **`hub/rhacm/policies/` scaffold** — `baseline/` and `inform/` with one example policy each | Medium | Governance phase; start with `inform` on one unmanaged type |
| F-4 | **Hub Application for policies** — sync `hub/rhacm/policies/` at wave `-5` or `-3` | Medium | Depends on F-3; same pattern as `cluster-label-sync` |
| F-5 | **PolicyGenerator in CI** — render policy bundles before Argo sync | Medium | Alternative to hand-authored policy YAML at scale |
| F-6 | **Remove `oc apply` comments** from integration manifests once F-1 exists | Low | Cleanup after F-1 |
| F-7 | **Framework GUIDELINES** — add invariant: all `hub/rhacm/*` delivered by Argo, no imperative hub apply | Low | One paragraph + link to git-driven-configuration |

---

## Governance & ownership decisions

| ID | Idea | Signal | Notes |
|----|------|--------|-------|
| G-1 | **Ownership matrix sign-off** — which mandates stay Argo vs move to ACM | High | cert-manager, monitoring, logging are Argo today; OAuth/NMState/kubeadmin typically ACM |
| G-2 | **Phase 4 governance slice definition** — minimal ACM increment without redesign | High | inform → one enforce → document split; aligns with onboarding epic Phase 4 |
| G-3 | **`inform` policies for drift outside app catalog** — `ClusterVersion`, `OAuth`, console edits | Medium | Argo-heavy blind spot per spectrum doc |
| G-4 | **Grey zone: NMState channel per OCP version** — ACM policy template vs Helm per version group | Medium | Resolution is templating in ACM, not more Argo charts |
| G-5 | **Dual-controller audit** — grep fleet repo for resources that could be deployed both ways | Low | Prevent Policy + Application on same object |

---

## Workshop / customer communication

| ID | Idea | Signal | Notes |
|----|------|--------|-------|
| W-1 | **Discovery question card** — six questions that plot posture on spectrum | Medium | From fleet-control-spectrum brainstorm |
| W-2 | **"Same YAML, different owner"** single-slide exercise | Medium | Two questions before naming tools |
| W-3 | **Day 0 / Day 1 / Day 2 strip** under barometer — lifecycle vs reconciliation | Low | Explains why 100% one tool feels wrong |
| W-4 | **Anti-pattern callouts** slide — Argo for compliance reporting, ACM for team apps, dual ownership | Low | Already in spectrum prose; distill for slides |

---

## Resolved / shipped

| ID | Item | Where |
|----|------|-------|
| ✓ | Fleet control spectrum (seven axes) | [fleet-control-spectrum.md](fleet-control-spectrum.md) |
| ✓ | Git-driven RHACM configuration principle | [rhacm/git-driven-configuration.md](rhacm/git-driven-configuration.md) |
| ✓ | Framework label sync as Git → ACM → Argo pattern | [cluster-labels README](argo/examples/framework/hub/rhacm/cluster-labels/README.md) |

---

## Session log

Brief context for future-you when picking items up.

**2026-06-25** — Brainstormed fleet control spectrum (multiple barometers, not binary Argo vs ACM).
Current solution posture: GitOps-heavy; Day 2 via Helm/ApplicationSets; ACM used for import, GitOpsCluster, label enforcement.
Agreed: RHACM hub config should live in Git with same DevOps practices as Argo delivery.
Decision: docs first; framework changes logged here for later.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
