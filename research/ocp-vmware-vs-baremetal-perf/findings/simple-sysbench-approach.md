# Simplified benchmark — sysbench in a pod

**Date:** 2026-08-10  
**Status:** Preferred path — keep it simple  
**Hypothesis:** New bare-metal cluster delivers **≥20%** better performance than older hardware running OpenShift on VMware.

---

## What you are actually measuring

This is an **environment A vs environment B** comparison, not a controlled virtualization-only test:

| Factor | Old cluster | New cluster |
|--------|-------------|-------------|
| Hardware generation | Older | Newer |
| Substrate | VMware VMs | Bare metal |
| Possibly OCP version, storage, network | … | … |

A **≥20% sysbench win** supports “the new platform is faster.” It does **not** prove how much of that is bare metal vs new CPUs vs new disks. For a migration decision, that is usually fine — name the confound in the write-up.

---

## Yes — a container with sysbench is enough to start

**Sysbench** covers:

- **CPU** — events/sec (`cpu` test)
- **Memory** — bandwidth (`memory` test)

It does **not** cover network or disk. Add later only if the 20% hypothesis is about I/O or east-west traffic:

| Need | Simple add-on |
|------|----------------|
| Disk | `fio` Job on a PVC (same storage class / size both sides) |
| Network | `iperf3` or `nicolaka/netshoot` client/server Jobs |

For a first pass: **CPU + memory sysbench only**.

---

## Peer smoke-test parity (confirmed)

Peer host smoke test (EPEL install on UBI minimal):

```bash
sysbench cpu --cpu-max-prime=20000 --threads=4 run
```

**Hardened image** (`quay.io/rh_hhellbusch/sysbench:1.0.20`) — verified locally with the same flags:

```text
sysbench 1.0.20 (using bundled LuaJIT 2.1.0-beta2)
Prime numbers limit: 20000
CPU speed:
    events per second:  6557.81
```

Memory test also runs (`sysbench memory --threads=4 run` → MiB/sec in output).

| Topic | Notes |
|-------|--------|
| **Comparable metric** | `events per second` (CPU); `MiB/sec` (memory) |
| **LuaJIT line** | EPEL: `system LuaJIT 2.1.0-beta3`; our image: `bundled LuaJIT 2.1.0-beta2` — cosmetic; same sysbench 1.0.20 CPU workload |
| **Peer host smoke test** | Two random machines, keyboard access, `podman` + EPEL install — anecdotal only; different from OCP Job compare |
| **Jobs YAML** | Aligned: `--cpu-max-prime=20000 --threads=4` (default 10s) |

Peer reference: ad-hoc host smoke test (two random machines with keyboard access, **not** OpenShift Jobs) — Machine 1 ≈ **4655** eps, Machine 2 ≈ **5871** eps (~**26%** delta). Directionally interesting; **not** a substitute for the cluster benchmark. Formal compare = same Job YAML on old VMware OCP vs new bare-metal OCP.

---

## How to run (minimal)

### 1. Same Job on both clusters

Use identical YAML; only `KUBECONFIG` changes.

**Image:** [quay.io/rh_hhellbusch/sysbench](https://quay.io/repository/rh_hhellbusch/sysbench) — build from [`Dockerfile`](Dockerfile), push, then apply Jobs. Pin by digest for repeatable runs.

```yaml
# benchmarks/simple/sysbench-cpu-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sysbench-cpu
  namespace: benchmark
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: sysbench
          image: quay.io/rh_hhellbusch/sysbench:latest
          args:
            - cpu
            - --threads=4
            - --time=60
            - run
          resources:
            requests:
              cpu: "4"
              memory: "1Gi"
            limits:
              cpu: "4"
              memory: "1Gi"
```

```yaml
# benchmarks/simple/sysbench-memory-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sysbench-memory
  namespace: benchmark
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: sysbench
          image: quay.io/rh_hhellbusch/sysbench:latest
          args:
            - memory
            - --threads=4
            - --time=60
            - run
          resources:
            requests:
              cpu: "4"
              memory: "4Gi"
            limits:
              cpu: "4"
              memory: "4Gi"
```

### 2. Commands

```bash
oc create namespace benchmark
oc apply -f sysbench-cpu-job.yaml
oc logs -n benchmark job/sysbench-cpu -f

# Repeat on other cluster
export KUBECONFIG=~/kubeconfigs/old-vmware.yaml
oc apply -f sysbench-cpu-job.yaml
oc logs -n benchmark job/sysbench-cpu -f
```

Delete and re-run 3× per cluster; take the median.

### 3. What to compare

From log output:

| Test | Metric | Example line |
|------|--------|----------------|
| CPU | `events per second` | higher is better |
| Memory | `transferred (MiB/sec)` | higher is better |

**20% rule:**

```text
improvement % = (new_bare_metal - old_vmware) / old_vmware × 100
```

Hypothesis holds if CPU **and/or** memory (whichever you care about) median is **≥ 20%** higher on the new cluster.

---

## Keep it fair (small checklist)

- [ ] Same `--threads` and `--time` on both clusters
- [ ] Same pod `cpu`/`memory` requests and limits (Guaranteed QoS)
- [ ] Run when clusters are otherwise idle
- [ ] 3 runs each; use **median**, not best single run
- [ ] Note OCP version, worker vCPU count, and whether old VMware workers are overcommitted
- [ ] Optional: `oc adm top nodes` during run — if old cluster shows high steal/contention, record it

**Thread count:** Pick a number ≤ vCPUs available per worker (e.g. 4 or 8). Use the **same** value on both sides. Do not max out an entire bare-metal host on one pod unless the old VMware pod gets equivalent reserved vCPUs.

---

## When sysbench is not enough

| If the peer cares about… | Sysbench alone? |
|--------------------------|-----------------|
| “Is the new platform faster for generic compute?” | Yes |
| Kafka / database production SLOs | No — need app-level test later |
| Network between pods | No — add iperf3 |
| Disk for stateful workloads | No — add fio on PVC |

Defer Kafka/Strimzi until a simple sysbench pass confirms the 20% ballpark — or doesn’t.

---

## Operator vs plain Job?

| Approach | Verdict |
|----------|---------|
| **Job + public sysbench image** | **Use this** — fewest moving parts |
| benchmark-operator + sysbench CR | More setup; same result |
| kube-burner / Kafka / HammerDB | Overkill for this hypothesis |

---

## Image trust

| Image | Verdict |
|-------|---------|
| `severalnines/sysbench` | **Do not use** for this benchmark — see below |
| **UBI micro + source build (`Dockerfile`)** | **Recommended** — minimal runtime, no EPEL/MariaDB |
| benchmark-operator sysbench workload | OK if you already run the operator; heavier setup |

**Severalnines the company** is legitimate (database/cluster management vendor). **`severalnines/sysbench` the image** is not trustworthy for a 2026 enterprise test:

- Last pushed to Docker Hub **~7 years ago**
- Bundles **sysbench 1.0.17-era** on **old Debian**
- No ongoing CVE maintenance or reproducible tagging
- Popular in old blog posts (1M+ pulls), not an official image from [sysbench upstream](https://github.com/akopytov/sysbench)
- Source: [ashraf-s9s/sysbench-docker](https://github.com/ashraf-s9s/sysbench-docker) — fine as a 2018 demo, stale today

There is **no official sysbench container** from the upstream project. For OpenShift, build a small image from **Red Hat UBI** and **EPEL** (same pattern RHEL docs use for sysbench on RHEL 9).

---

## Suggested one-pager for the peer

> We run the same sysbench CPU and memory Jobs on the **old VMware OCP cluster** and the **new bare-metal OCP cluster**, three times each, and compare median throughput. Success = **≥20%** improvement on the new side. (Peer's earlier host-only `podman` test on two random machines is informal context — not the benchmark.)
