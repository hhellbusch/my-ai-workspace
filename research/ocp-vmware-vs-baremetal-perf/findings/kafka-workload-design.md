# Kafka workload — benchmark design

**Date:** 2026-08-06  
**Status:** In scope — Tier 2 application workload  
**Parent:** [design-of-experiments.md](../design-of-experiments.md)

---

## Why Kafka is in scope

Streaming workloads are a common production pattern on OpenShift and were used in vendor substrate comparisons (Principled Technologies Kafka producer tests in the [2026 VKS vs OCP report](https://www.principledtechnologies.com/Broadcom/vSphere-Kubernetes-Service-competitive-0126.pdf)). Network latency and east-west throughput often differentiate VMware vs bare metal more than lightweight HTTP probes.

---

## Off-the-shelf tooling reality

| Option | Available? | Notes |
|--------|------------|-------|
| kube-burner-ocp | No | No Kafka workload |
| benchmark-operator / Ripsaw | No | No Kafka CR |
| benchmark-runner | No | No Kafka workload |
| **Apache Kafka perf scripts** | **Yes** | `kafka-producer-perf-test.sh`, `kafka-consumer-perf-test.sh` ship in the Kafka/Strimzi image |
| **Strimzi / AMQ Streams** | **Yes** | Operator + `Kafka` CR — deploy identical cluster on both substrates |
| Red Hat Streams docs | Partial | Producer tuning guidance, not a turnkey compare kit |

**Conclusion:** Kafka benchmarking is **assemble-yourself**, but from standard components — not custom code. The benchmark harness is a small set of Kubernetes Jobs + a Strimzi cluster manifest bundle.

---

## Recommended approach

### Architecture

```text
┌─────────────────────────────────────────────────────────┐
│  Strimzi Kafka cluster (identical spec both substrates) │
│  3 brokers (KRaft) · same CPU/RAM/disk · same SC       │
└─────────────────────────────────────────────────────────┘
         ▲                              ▲
         │ bootstrap:9092               │
┌────────┴────────┐            ┌────────┴────────┐
│ producer Job(s) │            │ consumer Job(s)│
│ perf-test image │            │ (optional)     │
└─────────────────┘            └────────────────┘
```

### Operator choice

| Operator | When to use |
|----------|-------------|
| **AMQ Streams** (Red Hat) | Production-aligned OCP; supported path |
| **Strimzi** (upstream) | Lighter install for lab-only compare |

Workspace already has Strimzi manifests: [`devops/ocp/examples/messaging/kafka/bare-metal-portworx/`](../../../devops/ocp/examples/messaging/kafka/bare-metal-portworx/README.md). For substrate compare, **strip rack/Portworx specifics** and parameterize storage class + broker sizing — same YAML on both clusters.

### Perf test runner

Run from a **Job** (not `oc run` ad hoc) so runs are reproducible and logged:

```yaml
# Pattern — values filled by harness
apiVersion: batch/v1
kind: Job
metadata:
  name: kafka-producer-perf-topic-4
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: perf
          image: quay.io/strimzi/kafka:0.48.0-kafka-4.1.0   # match operator version
          command:
            - bin/kafka-producer-perf-test.sh
          args:
            - --topic
            - bench-topic-4
            - --num-records
            - "5000000"
            - --record-size
            - "1024"
            - --throughput
            - "-1"
            - --print-metrics
            - --producer-props
            - bootstrap.servers=kafka-bench-kafka-bootstrap:9092
            - --producer-props
            - acks=1
            - --producer-props
            - batch.size=16384
            - --producer-props
            - linger.ms=10
            - --producer-props
            - compression.type=none
```

Ref: [Strimzi cheat sheet — producer perf](http://blog.jromanmartin.io/cheat-sheets/strimzi), [Red Hat producer tuning article](https://developers.redhat.com/articles/2021/07/19/benchmarking-kafka-producer-throughput-quarkus).

---

## Test matrix (aligned with vendor studies, simplified)

Run the **same matrix on both clusters**. Document all producer props in the run manifest.

| Scenario | Topics | Producers | record-size | Notes |
|----------|--------|-----------|-------------|-------|
| K1 | 1 | 1 | 1024 B | Baseline single-stream |
| K2 | 2 | 2 | 1024 B | Light parallelism |
| K4 | 4 | 4 | 1024 B | Medium parallelism |
| K8 | 8 | 8 | 1024 B | PT used up to 8 topics — tail latency divergence often appears here |

**Per scenario metrics** (from `--print-metrics` output):

- Throughput (MB/sec)
- Average latency (ms)
- Max latency (ms)
- Records sent / records/sec

**SLO-style threshold** (optional, from PT narrative): flag when p99 or max latency exceeds **50 ms** — document whether that threshold matters for your peer's use case.

### Scaling dimensions (hold constant across substrates)

| Parameter | Recommendation |
|-----------|----------------|
| Broker count | 3 (KRaft: 3 controllers + 3 brokers, or combined per Strimzi 0.48 NodePool model) |
| Replication factor | 3 |
| `min.insync.replicas` | 2 |
| Partitions per topic | ≥ producer count (e.g. 12) |
| Producer `acks` | 1 (throughput-focused; document if you retest with `all`) |
| TLS | **Same on both** — TLS materially affects throughput; do not compare TLS-on vs TLS-off |
| Storage | Same size/IOPS class per broker; document vSAN vs local NVMe |

---

## Fairness controls (substrate compare)

1. **Identical Kafka CR** — byte-for-byte except storage class name if required per cluster.
2. **Broker resources** — same `requests`/`limits`; Guaranteed QoS preferred.
3. **Node placement** — either both on dedicated labeled workers, or both on shared workers; do not dedicate on one side only.
4. **Network path** — pod-to-broker via cluster Service (overlay); optional second pass with producers on same nodes as brokers (not required for substrate test).
5. **JVM heap** — explicit and equal (`-Xmx` in `Kafka` CR).
6. **Cool-down** — delete topics or use fresh topics per run; 5+ min between heavy scenarios.

---

## Observability

| Source | Metrics |
|--------|---------|
| Perf test stdout | throughput, avg/max latency |
| Strimzi KafkaExporter / JMX → Prometheus | broker CPU, request rate, under-replicated partitions |
| OCP Prometheus | node network, disk latency, **CPU steal** (VMware) |
| Pod logs | archive via Job completion |

Optional: Grafana dashboard from Strimzi metrics for broker-side view during producer load.

---

## What to build (benchmarks bundle)

| Artifact | Purpose |
|----------|---------|
| `kafka/kafka-cluster.yaml` | Parameterized Strimzi `Kafka` + `KafkaNodePool` |
| `kafka/kafka-topic.yaml` | Topics with partition counts per scenario |
| `kafka/producer-job.yaml` | Templated Job — `TOPIC_COUNT`, `RECORD_SIZE`, `NUM_RECORDS` |
| `kafka/run-matrix.sh` | Loop K1→K8, capture logs to `results/<cluster>/<scenario>.txt` |
| `kafka/compare.sh` | Parse perf-test output into CSV for side-by-side |

---

## Workspace cross-links

- [Kafka on OpenShift tenancy](../../../devops/ocp/notes/kafka-on-openshift-tenancy.md) — shared vs dedicated workers, PDB/drain interactions during benchmark
- [Network policy / Strimzi ports](../../../devops/ocp/notes/network-policy-observability.md) — ensure bench namespace policies allow broker traffic
- [Bare-metal Kafka + Portworx example](../../../devops/ocp/examples/messaging/kafka/bare-metal-portworx/README.md) — production-style manifests (adapt, do not copy rack/Portworx blindly to VMware cluster)

---

## Open decisions

- [ ] AMQ Streams vs upstream Strimzi for lab clusters
- [ ] Dedicated Kafka workers vs shared workers (must match both sides)
- [ ] Storage class parity between VMware and bare metal
- [ ] Consumer perf included or producer-only (PT focused on producers)
- [ ] Whether to replicate PT's multi-topic-on-single-producer vs one-producer-per-topic model
