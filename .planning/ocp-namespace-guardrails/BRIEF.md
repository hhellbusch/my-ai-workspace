# OCP namespace guardrails

**Status:** Active — guide drafted 2026-08-06.

**Question:** How do platform teams limit namespace impact on the control plane beyond CPU/memory quotas?

**Audience:** OpenShift cluster administrators defining multi-tenant namespace policy.

**Decision it enables:** Which quota keys to enforce per namespace tier, and how to wire defaults into project creation.

**Output:**

- Guide: `devops/ocp/guides/namespace-guardrails/README.md`
- Quick reference: `devops/ocp/guides/namespace-guardrails/QUICK-REFERENCE.md`
- Examples: `devops/ocp/guides/namespace-guardrails/examples/`
- Research drawer: `research/ocp-namespace-guardrails/README.md`

**Scope:** ResourceQuota object counts, LimitRange, ClusterResourceQuota, project templates, etcd/control-plane impact model. Not node-level density (see `devops/ocp/notes/container-density-overcommit.md`).

**Not in scope:** Admission webhook design, ValidatingAdmissionPolicy authoring, per-CRD operator limits.
