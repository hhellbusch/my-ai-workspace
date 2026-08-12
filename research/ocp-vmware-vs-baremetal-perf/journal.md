# Journal — OCP VMware vs bare metal performance

Append-only. New entries at the top. One entry per session or notable decision.

**Updated via:** end of research sessions, `/checkpoint`, or when the DOE changes materially.

---

## Entry format

```markdown
### YYYY-MM-DD — [phase] — one-line summary

**Context:** What prompted this entry.
**Decisions:** What we settled (or explicitly deferred).
**Open questions:** What still needs peer input or lab access.
**Next:** Concrete next step.
```

---

## Log

### 2026-08-10 — peer context — host smoke test ≠ cluster benchmark

**Context:** Peer's ~26% CPU delta was two random machines with keyboard access (`podman` + on-the-fly EPEL install), not OpenShift Jobs on VMware vs bare-metal clusters.

**Implication:** Anecdotal signal only — useful for motivation, not proof. Formal test = same `sysbench-jobs.yaml` on both OCP clusters, 3 runs, median compare.

---

### 2026-08-10 — simplify — sysbench-in-a-pod; 20% hypothesis

**Context:** Peer wants a simple test, not full Strimzi/kube-burner suite. Hypothesis: **≥20%** improvement on new bare metal vs old hardware + VMware.

**Decision:** **Yes — run sysbench in a Job** (CPU + memory). Same YAML on both clusters; 3 runs; compare median `events per second` / MiB/sec. No benchmark-operator required for v1.

**Caveat:** Measures **new stack vs old stack** (hardware + substrate), not virtualization isolation alone. Fine for migration justification; say so in results.

**Deferred:** Kafka, kube-burner, Ripsaw — only if sysbench doesn’t answer the question or peer needs I/O/network (fio/iperf3).

**Artifact:** [findings/simple-sysbench-approach.md](findings/simple-sysbench-approach.md), [benchmarks/simple/sysbench-jobs.yaml](benchmarks/simple/sysbench-jobs.yaml)

**Next:** Push `quay.io/rh_hhellbusch/sysbench:1.0.20` and re-run Quay security scan.

---

### 2026-08-10 — security — hardened image for Quay findings

**Context:** Quay security scan flagged HIGH CVEs on the EPEL-based image.

**Findings (Trivy):** 12 HIGH — mostly `curl-minimal` (UBI base, unused at runtime) and `mariadb-connector-c` (EPEL sysbench dependency, not needed for cpu/memory tests).

**Fix:** Multi-stage Dockerfile — build sysbench 1.0.20 from source with `--without-mysql`; runtime on **UBI micro** (sysbench + glibc only). Jobs hardened: `readOnlyRootFilesystem`, drop ALL caps, `emptyDir` for `/tmp`, tag `1.0.20` not `latest`.

**Artifact:** Updated `Dockerfile`, `sysbench-jobs.yaml`, `benchmarks/simple/README.md`.

---

**Context:** User created `quay.io/rh_hhellbusch/sysbench` for the UBI+EPEL image.

**Updates:** Jobs use `quay.io/rh_hhellbusch/sysbench:latest`; fixed Job `args` (ENTRYPOINT is `sysbench` — do not repeat in args); added `benchmarks/simple/README.md`.

---

### 2026-08-06 — kafka — confirmed in scope; workload design drafted

**Context:** Peer confirmed Kafka as a benchmark workload type.

**Decision:** Kafka is **Tier 2**, not optional. No OTS Kafka benchmark in kube-burner/Ripsaw/benchmark-runner — use **Strimzi or AMQ Streams** + Apache `kafka-producer-perf-test.sh` via Kubernetes Jobs. Test matrix mirrors vendor studies: 1/2/4/8 topics, 1 KB records, throughput + latency.

**Artifact:** [findings/kafka-workload-design.md](findings/kafka-workload-design.md)

**Open questions:** AMQ Streams vs Strimzi; dedicated vs shared Kafka workers; storage class parity; producer-only vs consumer runs.

**Next:** Add `benchmarks/kafka/` manifest bundle when scaffolding harness.

---

### 2026-08-06 — tooling — off-the-shelf landscape assessment

**Context:** Environments presumed to exist; focus shifted from DOE fairness to runnable benchmark tooling.

**Conclusion:** No single off-the-shelf “VMware vs bare metal” product. Closest composable stack:

1. **benchmark-operator** (Ripsaw) — Tier 0/2: fio, uperf, sysbench, pgbench, hammerdb via CRs
2. **kube-burner-ocp** — Tier 1: node-density, cluster-density, pvc-density via CLI
3. **benchmark-runner** (optional) — containerized runner + Grafana/ES for cross-run compare; heavier deps, Virt/ODF-oriented

**Gaps:** Kafka/Strimzi not packaged in any suite; cross-cluster comparison is DIY (same CRs, two kubeconfigs, diff results).

**Decision:** See [findings/tooling-landscape.md](findings/tooling-landscape.md). Next artifact: versioned `benchmarks/` bundle (install + CRs + run harness).

**Open questions:**

- Does peer want Elasticsearch/Grafana or spreadsheet-level compare?
- Is OpenShift Virtualization installed (unlocks benchmark-runner VM workloads)?
- Default storage class name on each cluster for fio/pvc tests?

**Next:** Scaffold `benchmarks/` with operator install + Tier 0 CR templates.

---

### 2026-08-06 — kickoff — literature survey and placement decision

**Context:** Peer wants to compare VMware-based OpenShift with bare-metal OpenShift for workload performance. Initial hypothesis: bare metal wins. Started workspace research thread.

**Findings (literature):**

- No independent, apples-to-apples study found for *same OCP version, matched worker topology, OpenShift-on-vSphere vs OpenShift-bare-metal*.
- Most vendor benchmarks compare **VKS/Tanzu** to **OCP bare metal** — a platform comparison, not a substrate comparison.
- Principled Technologies (Jan 2026) is the closest: includes **virtualized OCP on VCF** vs **OCP bare metal** — claims virtualized OCP wins on Kafka/OLTP under their config. Methodology contested by Red Hat (topology, overcommit, synthetic workloads).
- Red Hat's [Precision over perception](https://www.redhat.com/en/blog/precision-over-perception-why-architecture-matters-benchmarking) argues for virtual-to-virtual or bare-to-bare comparisons with equivalent node counts and production-representative workloads.
- Independent K8s comparisons (e.g. Gcore, The New Stack) suggest ~10–20% effective virtualization tax; bare metal leads on network/storage tails — but not OpenShift-specific.

**Decisions:**

- **Home:** `research/ocp-vmware-vs-baremetal-perf/` (workshop) + `.planning/ocp-vmware-vs-baremetal-perf/BRIEF.md` (cross-session anchor).
- **Not** `devops/ocp/troubleshooting/` — this is comparative research, not a symptom guide.
- **Not** `devops/ocp/guides/` yet — operational guide only after experiments run.
- Seed DOE in `design-of-experiments.md`; iterate there rather than duplicating structure in the journal.

**Open questions:**

- What workloads does the peer actually run? (OLTP, Kafka, HTTP microservices, batch, GPU?)
- Do they have access to **both** substrates on **the same hardware generation**?
- Is production topology 1:1 VM workers per host, or dense VM workers (hosted control plane pattern)?
- VMware storage class (vSAN, NFS, FC) and whether bare metal uses equivalent CSI backing?
- Is the comparison OCP IPI on vSphere workers, or OCP with workers on OpenShift Virtualization — or both?

**Next:**

- Peer review of `design-of-experiments.md` v0.1 — confirm hardware access, workload priorities, and topology constraints.
- Add `sources/` entries when PDFs or pages are fetched locally.
- After peer sign-off on DOE, consider `devops/ocp/guides/` stub or lab runbook.
