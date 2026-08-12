---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# OCP Notes

Informal OpenShift quick references and command notes. These are working references — commands and patterns used regularly — not structured troubleshooting guides (those live in `ocp/troubleshooting/`).

Red Hat doc links in notes follow [`rules/red-hat-docs-links.md`](../../../rules/red-hat-docs-links.md).

## Contents

- **[machine-config-pools.md](machine-config-pools.md)** — MachineConfig and MachineConfigPool targeting, custom pools, rollout behavior
- **[openshift-useful-commands.md](openshift-useful-commands.md)** — Useful OpenShift and kubectl commands for pod management, troubleshooting, and cluster operations
- **[container-density-overcommit.md](container-density-overcommit.md)** — Packing/overcommit architecture for large bare-metal clusters (LimitRange, CRO, VPA, HPA)
- **Namespace guardrails** — Object-count quotas and control-plane limits beyond CPU/memory: [guides/namespace-guardrails/README.md](../guides/namespace-guardrails/README.md)
- **[cluster-resource-override.md](cluster-resource-override.md)** — ClusterResourceOverride Operator: request/limit ratios, opt-in namespaces, pitfalls
- **[vertical-pod-autoscaler.md](vertical-pod-autoscaler.md)** — VPA features, tradeoffs, pitfalls, and right-sizing practices
- **[network-policy-observability.md](network-policy-observability.md)** — NetworkPolicy enforcement, OVN audit logging, NetObserv, Kafka (Strimzi vs CFK) and Flink port requirements
- **[kafka-on-openshift-tenancy.md](kafka-on-openshift-tenancy.md)** — Kafka tenancy models, MCP/CVO upgrades, PDB and network-policy pitfalls on shared workers
- **[pod-termination-quick-stop.md](pod-termination-quick-stop.md)** — Force-delete vs scale-to-zero; grace-period=0 and the `kill -9` analogy

Placement rules for all `devops/` content: [ORGANIZATION.md](../../ORGANIZATION.md).

## Adding New Notes

When adding a new note:
1. Use a descriptive filename with kebab-case
2. Link it from this README
3. If it grows into a full troubleshooting guide, move it to `ocp/troubleshooting/` with the standard symptom → cause → fix structure

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*
