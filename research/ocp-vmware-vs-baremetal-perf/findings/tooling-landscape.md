# Tooling landscape — off-the-shelf options

**Date:** 2026-08-06  
**Question:** What exists ready-to-run for benchmarking two existing OpenShift clusters (VMware vs bare metal)?

## Short answer

There is **no single product or suite** that runs “OpenShift on VMware vs bare metal” out of the box. Red Hat’s PerfScale ecosystem uses **composable open-source tools**. For existing clusters, the closest off-the-shelf path is:

1. **[benchmark-operator](https://github.com/cloud-bulldozer/benchmark-operator)** (formerly Ripsaw) — substrate + app micro-benchmarks via CRs  
2. **[kube-burner-ocp](https://github.com/kube-burner/kube-burner-ocp)** — platform/scale workloads via CLI  
3. **[benchmark-runner](https://github.com/redhat-performance/benchmark-runner)** — optional unified runner + Grafana compare (heavier deps)

You still assemble a **runbook** (which workloads, which order, how to compare results across clusters). None of the tools know about “substrate A vs B” natively.

---

## Tool-by-tool assessment

### 1. kube-burner-ocp — platform / control-plane stress

| | |
|---|---|
| **What it is** | Single binary; OCP wrapper around kube-burner with embedded workload configs |
| **Install** | `curl -Ls …/hack/install.sh \| sh` → `kube-burner-ocp` |
| **Run model** | CLI from laptop with `KUBECONFIG`; auto-discovers Prometheus |
| **Built-in workloads** | `node-density`, `node-density-heavy`, `cluster-density-v2`, `pvc-density`, `network-policy`, virt workloads, web-burner variants, … |
| **Metrics** | Prometheus scrape + optional Elasticsearch/OpenSearch indexing |
| **Off-the-shelf?** | **Yes** for platform tests — one command per workload |
| **Gaps** | No CPU/disk/network micro-benchmarks; not an app benchmark suite (no HammerDB/Kafka built-in); compares clusters only if you run twice and diff results yourself |

**Example:**

```bash
kube-burner-ocp node-density-heavy --pods-per-node=50
kube-burner-ocp pvc-density --iterations=100
```

**Best for DOE tier:** 1 (platform behavior)

---

### 2. benchmark-operator (Ripsaw) — substrate + application baselines

| | |
|---|---|
| **What it is** | Kubernetes operator; apply `Benchmark` CRs to launch standard tools |
| **Install** | Helm or `make deploy`; needs `privileged` SCC on OCP |
| **Run model** | `oc apply -f` CR per test; operator orchestrates client/server pods |
| **Built-in workloads** | `fio`, `uperf`, `iperf3`, `sysbench`, `pgbench`, `ycsb`, `hammerdb`, `smallfile`, `fs-drift`, custom image |
| **Metrics** | Optional Elasticsearch indexing; results also in workload pods/logs |
| **Off-the-shelf?** | **Yes** for micro + DB benches — but each test is a CR you configure (node pins, storage class, hostNetwork, etc.) |
| **Gaps** | No cross-cluster compare UI; ES setup is on you; docs are per-workload; operator maintenance is community (cloud-bulldozer) |

**Example pattern:** Red Hat’s [network benchmarking series](https://www.redhat.com/en/blog/benchmarking-openshift-network-performance-part-1-basics) uses Ripsaw + uperf.

**Best for DOE tiers:** 0 (substrate), 2 (pgbench, hammerdb)

**Install sketch (OCP):**

```bash
git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator/charts/benchmark-operator
oc create namespace benchmark-operator
oc adm policy add-scc-to-user privileged -z benchmark-operator -n benchmark-operator
helm install benchmark-operator . -n benchmark-operator
```

---

### 3. benchmark-runner — containerized “single command” runner

| | |
|---|---|
| **What it is** | Python framework in a container (`quay.io/benchmark-runner/benchmark-runner`); Red Hat Perf/Scale (Virt-focused) |
| **Install** | Pull image; mount kubeconfig; optional Elasticsearch + Grafana |
| **Run model** | `podman run -e WORKLOAD=… -e RUN_TYPE=func_ci\|perf_ci …` |
| **Built-in workloads** | `stressng`, `uperf`, `sysbench`, `fio`, `vdbench`, HammerDB (Postgres/MariaDB/MSSQL), `bootstorm`, `clusterbuster`, Krkn |
| **Metrics** | Elasticsearch indices + **Grafana dashboards** for cross-run comparison |
| **Off-the-shelf?** | **Mostly** — closest to a packaged “run and compare” experience |
| **Gaps** | `perf_ci` expects large clusters + ODF/LSO for storage/DB; VM workloads need **OpenShift Virtualization**; opinionated toward Virt perf CI, not generic substrate shootout |

**Best for DOE tiers:** 0–2 if you want Grafana comparison without building it; overkill if you only need pod-based benches on modest clusters.

Ref: [Red Hat Developer article (Nov 2025)](https://developers.redhat.com/articles/2025/11/18/how-run-performance-tests-using-benchmark-runner)

---

### 4. cloud-bulldozer/e2e-benchmarking — CI automation, not a user suite

| | |
|---|---|
| **What it is** | Shell wrappers (`WORKLOAD=node-density ./run.sh`) around kube-burner for pipeline use |
| **Off-the-shelf?** | For **automated CI** on a single cluster — not a dual-cluster comparison product |
| **Use here** | Borrow workload names/configs; optional later if you automate regression |

---

### 5. clusterbuster — scale / synthetic load

| | |
|---|---|
| **What it is** | `redhat-performance/clusterbuster` — namespace/deployment generator, client-server traffic |
| **Off-the-shelf?** | Yes, but niche: scale/stress, not standard substrate benchmarks |
| **Use here** | Optional supplement; also callable via benchmark-runner |

---

### 6. ODF-benchmarker — storage-only

| | |
|---|---|
| **What it is** | Node-level CPU/storage/network via sysbench/iperf on ODF nodes |
| **Off-the-shelf?** | Yes, if both clusters use ODF |
| **Use here** | Skip unless ODF is the storage layer on both sides |

---

### 7. Kafka / streaming — not packaged (in scope; assemble from Strimzi + perf scripts)

Vendor studies use Kafka producer perf tests. No suite ships this as a one-liner. **In scope for this project** — see [findings/kafka-workload-design.md](findings/kafka-workload-design.md):

- Deploy identical Strimzi/AMQ Streams cluster on both substrates
- Run `kafka-producer-perf-test.sh` via Kubernetes Jobs (image bundled with Strimzi)
- Matrix: 1/2/4/8 topics — throughput and latency vs PT-style scenarios
- Small harness to build: cluster CRs + producer Jobs + `run-matrix.sh` + log parser

---

## What vendor benchmarks actually used

| Study | Tools |
|-------|-------|
| PT / Broadcom 2026 | Kafka + HammerDB TPROC-C/PostgreSQL on VKS vs OCP |
| PT pod density | kube-burner (`kubelet-density-heavy` variant) |
| Red Hat PerfScale CI | kube-burner, e2e-benchmarking, custom validators |

---

## Recommended stack (existing clusters, minimal assembly)

| Tier | Tool | Rationale |
|------|------|-----------|
| 0 — Substrate | **benchmark-operator** | fio, uperf, sysbench CRs — same YAML run on both clusters |
| 1 — Platform | **kube-burner-ocp** | One CLI per test; Prometheus built in |
| 2 — Application | **benchmark-operator** (`hammerdb`, `pgbench`) + **Kafka** (Strimzi Jobs) | OLTP via operator; Kafka via [kafka-workload-design.md](kafka-workload-design.md) |
| 2 — Kafka | **Strimzi/AMQ Streams + perf-test Jobs** | In scope; standard Apache perf scripts, not a third-party suite |
| Compare | **Your thin wrapper** | Same CRs/flags, `KUBECONFIG` switch, spreadsheet or ES/Grafana |

### What you still have to build (small)

1. **Pinned CR set** — version-controlled `Benchmark` manifests (node selectors, storage class, hostNetwork flags)
2. **Kafka bundle** — Strimzi cluster + topic + producer Job templates ([design](kafka-workload-design.md))
3. **Run harness** — shell/Makefile: `make tier0 CLUSTER=bm` / `CLUSTER=vmware`
3. **Results collector** — pull ES docs or pod logs into a comparison table (or use benchmark-runner’s Grafana if you adopt it)
4. **User metadata** — `kube-burner-ocp --user-metadata` YAML tagging `substrate: baremetal|vmware`

---

## Decision matrix

| If you want… | Choose |
|--------------|--------|
| Fastest start, platform-only | kube-burner-ocp alone |
| Substrate + DB/network baselines | benchmark-operator |
| Grafana cross-run dashboards out of the box | benchmark-runner (+ Elasticsearch) |
| Fully automated regression CI | e2e-benchmarking patterns + ES |
| One tool does everything | **Does not exist** — combine 2 of the above |

---

## Next step for this project

Draft a `benchmarks/` directory (under research or later `devops/ocp/examples/`) with:

- Helm install notes for benchmark-operator
- kube-burner-ocp install + standard command list
- Tier 0–2 CR/manifest bundle with placeholders for storage class and node names
- `run-compare.sh` skeleton
