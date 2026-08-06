# OCP namespace guardrails

**Purpose:** Research inputs for namespace limits beyond CPU/memory — etcd object counts, control-plane impact, and quota mechanisms.

**Status:** Complete — synthesized into operational guide.

**Output:** [Namespace guardrails guide](../../devops/ocp/guides/namespace-guardrails/README.md)

## Primary sources

| Source | URL | Used for |
|--------|-----|----------|
| Kubernetes Resource Quotas | https://kubernetes.io/docs/concepts/policy/resource-quotas/ | Object count syntax, `count/` keys, control-plane rationale |
| OCP Quotas (building applications) | https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/quotas | Project quotas, ClusterResourceQuota, project templates |
| OCP Object maximums | https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/scalability_and_performance/planning-your-environment-according-to-object-maximums | Tested per-namespace and cluster maximums, churn factors |
| OCP etcd performance | https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/etcd/performance-considerations-for-etcd | Disk quota 8–32 GiB, defrag, alerts |
| K8s sig-scalability thresholds | https://github.com/kubernetes/community/blob/main/sig-scalability/configs-and-limits/thresholds.md | 1.5 MB object size, per-type counts |
| EndpointSlices scaling | https://kubernetes.io/blog/2020/09/02/scaling-kubernetes-networking-with-endpointslices/ | Endpoints object size, watch amplification |

## Workspace context

- `devops/ocp/troubleshooting/api-slowness-web-console/README.md` — etcd/API slowness; brief ResourceQuota example
- `devops/ocp/notes/container-density-overcommit.md` — compute-focused LimitRange/CRO; references ResourceQuota in adoption order
