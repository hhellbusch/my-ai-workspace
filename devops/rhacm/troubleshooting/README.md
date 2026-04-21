# RHACM Troubleshooting Guides

Practical diagnostic guides for Red Hat Advanced Cluster Management operational issues.

## Guides

| Guide | Symptom |
|---|---|
| [mch-stuck-pending-upgrade.md](./mch-stuck-pending-upgrade.md) | `MultiClusterHub` stuck in `Updating` / `Pending` / `Installing` beyond ~10–15 min during hub upgrade |
| [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md) | `The cluster is not reachable. Registration agent stopped updating its lease.` — clusters showing Unknown, during or after hub upgrade |

## Common Scenarios

**MCH stuck during upgrade:**
- OLM InstallPlan with Manual approval waiting to be approved
- Missing `mce-subscription-spec` annotation in disconnected environments (upgrade starts but stalls)
- Image pull failures if mirror catalog was not updated for the new version
- A sub-component (MCE, webhook, etc.) not reaching Available state
- See [mch-stuck-pending-upgrade.md](./mch-stuck-pending-upgrade.md) — includes a diagnostic decision tree

**Managed clusters Unknown during or after hub upgrade:**
- Expected behavior while MCH is still Updating (up to 10 minutes per ACM 2.15 docs)
- Clusters should self-recover after MCH returns to Running
- If still Unknown after hub is healthy, investigate klusterlet and connectivity
- See [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md)

## Reference Documentation

- [ACM 2.15 — Installing and Upgrading](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing)
- [ACM Support Matrix](https://access.redhat.com/articles/7133095)

## Related

- [Examples](../examples/) — RHACM configuration examples and patterns
- [OCP Troubleshooting](../../ocp/troubleshooting/) — OpenShift platform troubleshooting

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
