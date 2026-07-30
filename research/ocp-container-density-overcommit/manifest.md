# Source Manifest

**Subject:** OCP container density / overcommit — landscape survey
**URL:** (workspace notes) devops/ocp/notes/container-density-overcommit.md
**Analysis started:** 2026-07-17
**Total references:** 12
**Focus:** Discover control-plane paths (P1–P10 in paths.md); not claim-verify a single article

**Fetch notes:** `docs.redhat.com` returns HTTP 403 to the automated fetcher. Where needed, URLs below use OKD HTML or `openshift/openshift-docs` raw AsciiDoc mirrors; canonical RH titles remain in `notes` for citation.

---

| ref_id | url | status | file | notes |
| --- | --- | --- | --- | --- |
| ref-01 | https://raw.githubusercontent.com/openshift/openshift-docs/enterprise-4.18/nodes/clusters/nodes-cluster-overcommit.adoc | fetched | sources/ref-01.txt | 5579 chars |
| ref-02 | https://raw.githubusercontent.com/openshift/openshift-docs/enterprise-4.18/modules/nodes-cluster-resource-override.adoc | fetched | sources/ref-02.txt | 5049 chars |
| ref-03 | https://github.com/openshift/cluster-resource-override-admission-operator/blob/main/README.md | fetched | sources/ref-03.txt | P2 — upstream Operator behavior / opt-in label |
| ref-04 | https://kubernetes.io/docs/concepts/policy/limit-range/ | fetched | sources/ref-04.txt | P1 — LimitRange defaults / ratios |
| ref-05 | https://kubernetes.io/docs/concepts/policy/resource-quotas/ | fetched | sources/ref-05.txt | P1 — namespace aggregate caps |
| ref-06 | https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/ | fetched | sources/ref-06.txt | P3 — Guaranteed / Burstable / BestEffort |
| ref-07 | https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/ | fetched | sources/ref-07.txt | P3 — PriorityClass vs eviction |
| ref-08 | https://docs.okd.io/4.18/nodes/pods/nodes-pods-vertical-autoscaler.html | fetched | sources/ref-08.txt | 246219 chars |
| ref-09 | https://kubernetes.io/docs/concepts/workloads/autoscaling/vertical-pod-autoscale/ | fetched | sources/ref-09.txt | P4 — upstream VPA + LimitRange interaction |
| ref-10 | https://docs.okd.io/4.18/nodes/nodes/nodes-nodes-resources-configuring.html | fetched | sources/ref-10.txt | 207329 chars |
| ref-11 | https://docs.okd.io/latest/post_installation_configuration/node-tasks.html | fetched | sources/ref-11.txt | 277272 chars |
| ref-12 | https://docs.okd.io/4.18/machine_management/applying-autoscaling.html | fetched | sources/ref-12.txt | 212202 chars |
