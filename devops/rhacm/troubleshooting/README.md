---
review:
  status: unreviewed
  notes: "AI-generated index. Needs read pass to confirm guide descriptions match current content."
---

# RHACM Troubleshooting Guides

Practical diagnostic guides for Red Hat Advanced Cluster Management operational issues.

## Guides

| Guide | Symptom |
|---|---|
| [mch-stuck-pending-upgrade.md](./mch-stuck-pending-upgrade.md) | `MultiClusterHub` stuck in `Updating` / `Pending` / `Installing` beyond ~10–15 min during hub upgrade |
| [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md) | `The cluster is not reachable. Registration agent stopped updating its lease.` — clusters showing Unknown, during or after hub upgrade |
| [search-service-503.md](./search-service-503.md) | Search UI returns 503 / "Error occurred while contacting the search service" — `search-postgres` OOMKill and other search component failures |

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

**Search UI returning 503:**
- `search-postgres` OOMKilled — increase memory limits via the `Search` CR
- Search service not enabled in MCH, or per-cluster addon not deployed
- See [search-service-503.md](./search-service-503.md); for first-time setup see [notes/search-setup.md](../notes/search-setup.md)

## Reference Documentation

- [ACM 2.15 — Installing and Upgrading](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing)
- [ACM Support Matrix](https://access.redhat.com/articles/7133095)

## Related

- [Notes](../notes/) — RHACM quick references including search setup
- [Examples](../examples/) — RHACM configuration examples and patterns
- [OCP Troubleshooting](../../ocp/troubleshooting/) — OpenShift platform troubleshooting

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
