# RHACM Troubleshooting Guides

Practical diagnostic guides for Red Hat Advanced Cluster Management operational issues.

## Guides

| Guide | Symptom |
|---|---|
| [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md) | `The cluster is not reachable. Registration agent stopped updating its lease.` — clusters showing Unknown, during or after hub upgrade |

## Common Scenarios

**During a hub upgrade (MCH Pending/Updating):**
- Managed clusters temporarily showing Unknown during upgrade is expected behavior
- Hub upgrade can take up to 10 minutes per official ACM 2.15 docs
- Clusters should self-recover after MCH returns to Running
- See [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md) for upgrade-specific checks

**Disconnected environments:**
- Mirror catalog and `mce-subscription-spec` annotation issues are a common upgrade blocker
- Certificate and image pull issues more common without internet access
- See the lease troubleshooting guide — Scenario E covers the disconnected upgrade stall

## Reference Documentation

- [ACM 2.15 — Installing and Upgrading](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing)
- [ACM Support Matrix](https://access.redhat.com/articles/7133095)

## Related

- [Examples](../examples/) — RHACM configuration examples and patterns
- [OCP Troubleshooting](../../ocp/troubleshooting/) — OpenShift platform troubleshooting

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
