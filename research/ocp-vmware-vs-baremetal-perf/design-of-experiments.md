# Design of experiments — OpenShift substrate comparison

**Version:** 0.1 (draft)  
**Last updated:** 2026-08-06  
**Status:** Awaiting peer review — no lab runs yet

---

## 1. Research question

> For equivalent OpenShift deployments, does bare metal outperform VMware-hosted workers on workloads representative of our production environment — and by how much, on which dimensions?

**Primary hypothesis (H1):** Bare-metal workers deliver higher throughput and lower p95/p99 latency than vSphere VM workers for CPU-, I/O-, and network-intensive workloads, when VMware workers are not overcommitted.

**Null hypothesis (H0):** No statistically or operationally significant difference on representative workloads after fair tuning of both substrates.

**Alternative outcomes we must allow:**

- Virtualized workers match or beat bare metal on light/bursty workloads or when topology favors many small nodes.
- Differences appear only in tail latency or one resource dimension (e.g. network), not headline throughput.

---

## 2. What “fair” means (non-negotiables)

| Control | Requirement |
|---------|-------------|
| OpenShift version | Same minor release on both clusters |
| CNI | Same plugin (e.g. OVNKubernetes) and comparable config |
| Worker topology | **Equivalent node count** — e.g. 4 bare-metal workers vs 4 vSphere VM workers (not 4 vs 300) |
| Hardware | Same server generation; document SKU, NIC, disk |
| CPU/RAM per worker | Matched allocatable; VMware VMs use **reservations**, not best-effort overcommit |
| Storage | Document backing (vSAN / NFS / FC / local LV); same CSI driver class where possible |
| Tuning effort | Equal effort on PerformanceProfile (bare metal) vs VM latency sensitivity + NUMA alignment (VMware) |
| Workload | Identical manifests, images, replica counts, resource requests/limits |

**Explicitly out of scope for v0.1:** Comparing VKS/Tanzu to OpenShift; pod-density control-plane limits as a proxy for app performance.

---

## 3. Test environments (to be confirmed with peer)

| Field | Bare metal cluster | VMware cluster | Notes |
|-------|-------------------|----------------|-------|
| Install method | | | IPI/UPI; document |
| OCP version | | | |
| Control plane | | | Same topology class (e.g. 3 CP nodes) |
| Worker count | | | **Must match** |
| Worker vCPU / RAM | | | Match allocatable |
| vCPU:pCPU ratio (VMware) | N/A | 1:1 target | Document if higher |
| Network | | | Speed, CNI, MTU |
| Storage default SC | | | |
| Monitoring | | | Thanos/Prometheus enabled |

### VMware worker checklist (performance-oriented)

- [ ] Latency sensitivity = High
- [ ] CPU and memory fully reserved
- [ ] VMXNET3 + paravirtual SCSI
- [ ] NUMA aligned; avoid spanning sockets without intent
- [ ] Document datastore type and ESXi power management settings
- [ ] Capture CPU **steal time** during runs

---

## 4. Experiment tiers

Run in order. Tier 0 establishes substrate delta; higher tiers add application realism.

### Tier 0 — Substrate micro-benchmarks

**Goal:** Measure raw CPU, memory, disk, and network deltas independent of app logic.

| Test | Tool | Key metrics |
|------|------|-------------|
| CPU | Ripsaw `sysbench` | events/sec, latency |
| Memory | Ripsaw `sysbench` | bandwidth, latency |
| Block I/O | Ripsaw `fio` on PVC | IOPS, p95 latency |
| Network (overlay) | Ripsaw `uperf` pod-to-pod | throughput, latency, TCP/UDP |
| Network (node) | Ripsaw `uperf` hostNetwork=true | node-level ceiling |

**Pass/fail framing:** Not binary — record **delta %** (bare metal vs VMware) per metric. Expect largest gaps on network and storage tails.

### Tier 1 — Platform behavior

**Goal:** Scheduling, API, and storage provisioning under load — *not* a substitute for app benchmarks.

| Test | Tool | Key metrics |
|------|------|-------------|
| Pod scheduling density | kube-burner-ocp `node-density-heavy` | time-to-ready, apiserver latency |
| Control-plane stress | kube-burner-ocp `cluster-density-v2` | etcd duration, error rate |
| PVC churn | kube-burner-ocp `pvc-density` | bind latency, throughput |

**Interpretation:** Per Red Hat and prior vendor debates, treat these as **platform limit** tests. A win here does not imply app win.

### Tier 2 — Application workloads (peer to prioritize)

Select **at least two** that mirror production. **Kafka is in scope** — see [findings/kafka-workload-design.md](findings/kafka-workload-design.md).

| Workload | Tool | Key metrics |
|----------|------|-------------|
| PostgreSQL OLTP | benchmark-operator `pgbench` or HammerDB | TPS, NOPM, p95 latency |
| **Kafka streaming** | **Strimzi/AMQ Streams + `kafka-producer-perf-test` Jobs** | throughput (MB/s), avg/max latency, records/sec |
| HTTP service | `wrk2` or kube-burner hello-openshift variant | RPS, p99 latency |

**Peer input needed:** Rank workloads; confirm Kafka operator (AMQ Streams vs Strimzi) and broker sizing.

### Tier 3 — Optional (only if in production scope)

| Workload | Tool | Notes |
|----------|------|-------|
| Low-latency / DPDK | TRex + testpmd + SR-IOV | Bare metal often dominates; VM path may need passthrough |
| GPU inference | GPU Operator + model bench | If GPU workloads exist on both substrates |

---

## 5. Tooling stack

| Layer | Tool | Repo / docs |
|-------|------|-------------|
| Platform scale | kube-burner-ocp | https://github.com/kube-burner/kube-burner-ocp |
| Micro + app benches | benchmark-operator | https://github.com/cloud-bulldozer/benchmark-operator |
| **Kafka streaming** | **Strimzi or AMQ Streams + perf-test Jobs** | [kafka-workload-design.md](findings/kafka-workload-design.md) |
| CI automation | e2e-benchmarking | https://github.com/cloud-bulldozer/e2e-benchmarking |
| Metrics | OCP Prometheus / Thanos | kube-burner metrics profiles; Strimzi Kafka metrics |
| Optional indexing | Elasticsearch | For longitudinal compare |

---

## 6. Metrics and observability

### Application (per workload)

- Throughput (TPS, MB/s, RPS)
- Latency: p50, **p95**, **p99**
- Error rate

### Platform (both clusters, same windows)

- CPU steal time (VMware workers)
- Node CPU/memory utilization
- etcd request duration, apiserver latency
- CNI / OVN metrics if available
- Storage provision/bind latency

### Reporting

- Report **per-node efficiency** (e.g. TPS per worker), not only cluster aggregate — avoids topology tricks.
- Include configuration appendix (YAML snippets, VM sizing, reservation settings).

---

## 7. Execution protocol (draft)

1. **Baseline both clusters** — health checks, same time sync, no competing jobs.
2. **Tier 0 → 1 → 2** in order; cool-down between destructive kube-burner runs.
3. **Three repetitions** minimum per test configuration; report mean and spread.
4. **Single variable changes** — if tuning VMware, re-run affected tiers only.
5. **Archive artifacts** — kube-burner UUID dirs, Ripsaw CR results, Prometheus snapshots.

---

## 8. Success criteria (to refine with peer)

| Criterion | Draft threshold |
|-----------|-----------------|
| Practical significance | e.g. >15% p95 latency improvement on primary workload |
| Consistency | Same direction on ≥2 of 3 repetitions |
| Operational relevance | Improvement matters for stated SLO or capacity plan |

Avoid declaring a “winner” from Tier 1 alone.

---

## 9. Known literature pitfalls (design guardrails)

- **Topology asymmetry** — 300 small VM workers vs 4 bare-metal workers measures queuing geometry, not substrate speed ([Red Hat critique](https://www.redhat.com/en/blog/precision-over-perception-why-architecture-matters-benchmarking)).
- **Overcommit masking** — light synthetic pods hide CPU contention; use reserved VMs and workloads that consume declared requests.
- **Platform swap** — VKS vs OCP bare metal is not our question unless explicitly scoped.
- **Storage confound** — vSAN vs local NVMe can swamp hypervisor effects; document or match where possible.

---

## 10. Open decisions

- [ ] Peer workload priority list
- [ ] Hardware inventory and whether same boxes can run both profiles sequentially
- [ ] VMware worker sizing and reservation policy
- [ ] Whether to include virtualized OCP on OCP Virtualization as a third arm (KVM on bare metal — closer to “virtual on same iron”)
- [ ] Statistical analysis depth (formal tests vs engineering judgment)
- [ ] Publication target: internal memo only vs `devops/ocp/guides/` vs library entry

---

## 11. Revision history

| Version | Date | Change |
|---------|------|--------|
| 0.1 | 2026-08-06 | Initial draft from literature survey session |
