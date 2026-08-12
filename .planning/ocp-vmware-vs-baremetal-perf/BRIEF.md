# OCP VMware vs bare metal — workload performance

**Status:** Active — research and experiment design started 2026-08-06.

**Question:** Does OpenShift on bare metal outperform OpenShift on VMware for representative workloads — and under what conditions?

**Audience:** Platform engineers and architects comparing deployment substrates (internal peer review; may extend to customer-facing guidance later).

**Decision it enables:** Whether to invest in bare-metal OpenShift, stay on vSphere-hosted workers, or adopt a mixed topology — with workload-specific evidence rather than vendor headlines.

**Hypothesis (simplified, 2026-08-10):** New bare-metal cluster delivers **≥20%** better performance than older hardware + VMware. First test: sysbench CPU/memory Jobs — see [findings/simple-sysbench-approach.md](findings/simple-sysbench-approach.md).

**Hypothesis (original, granular):** Bare-metal workers deliver higher throughput and lower tail latency than vSphere VM workers for equivalent hardware — deferred unless simple sysbench is insufficient.

**Output (planned):**

- Research drawer: `research/ocp-vmware-vs-baremetal-perf/`
- Experiment design: `research/ocp-vmware-vs-baremetal-perf/design-of-experiments.md`
- Session journal: `research/ocp-vmware-vs-baremetal-perf/journal.md`
- Operational guide (if warranted): `devops/ocp/guides/` — only after experiments run and findings stabilize

**Scope:** Substrate comparison (same OCP version, equivalent worker topology), benchmark tooling survey, fair test methodology. Application workloads: **Kafka streaming**, PostgreSQL OLTP, optional HTTP. See `findings/kafka-workload-design.md`.

**Not in scope (initially):** VKS/Tanzu vs OpenShift platform wars; MTV migration performance; TCO/licensing analysis (may add later as a separate dimension).

**Related workspace material:**

- `devops/ocp/notes/container-density-overcommit.md` — node packing (orthogonal but shares quota/tuning context)
- `research/ocp-container-density-overcommit/` — density control-plane map
