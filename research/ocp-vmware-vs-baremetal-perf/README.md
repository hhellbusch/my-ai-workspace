# OCP VMware vs bare metal — workload performance

**Purpose:** Research and experiment design for comparing OpenShift on VMware (vSphere workers) with OpenShift on bare metal — published benchmarks, tooling, and a fair test plan.

**Status:** In progress

**Output:** TBD — experiment results and (if warranted) `devops/ocp/guides/` operational guide.

**Project brief:** [`.planning/ocp-vmware-vs-baremetal-perf/BRIEF.md`](../../.planning/ocp-vmware-vs-baremetal-perf/BRIEF.md)

## Working documents

| Document | Role |
|----------|------|
| [journal.md](journal.md) | Append-only session log — decisions, iterations, open questions |
| [design-of-experiments.md](design-of-experiments.md) | Living test plan — hypotheses, matrix, tooling, pass/fail criteria |
| [findings/tooling-landscape.md](findings/tooling-landscape.md) | Off-the-shelf tool assessment (kube-burner-ocp, benchmark-operator, benchmark-runner) |
| [findings/simple-sysbench-approach.md](findings/simple-sysbench-approach.md) | **Preferred** — sysbench Jobs, 20% hypothesis, minimal setup |
| [benchmarks/simple/README.md](benchmarks/simple/README.md) | Build/push to Quay, run Jobs |
| [benchmarks/simple/sysbench-jobs.yaml](benchmarks/simple/sysbench-jobs.yaml) | CPU + memory Jobs (`quay.io/rh_hhellbusch/sysbench`) |

## Subdirectories (create as needed)

| Subdir | When |
|--------|------|
| `sources/` | Raw fetched pages, PDFs, transcripts (save as `.txt`) |
| `findings/` | Per-source analysis batches before synthesis |

## Primary external sources (initial survey)

| Source | URL | Notes |
|--------|-----|-------|
| Red Hat — benchmark methodology critique | https://www.redhat.com/en/blog/precision-over-perception-why-architecture-matters-benchmarking | Topology asymmetry; fair comparison principles |
| Principled Technologies / Broadcom (Jan 2026) | https://www.principledtechnologies.com/Broadcom/vSphere-Kubernetes-Service-competitive-0126.pdf | VKS vs OCP bare metal vs virtualized OCP on VCF; Kafka + HammerDB |
| EANTC telco CNF report (Aug 2022) | https://www.vmware.com/docs/1668273_eantc-testreport-vmware-cnfperformance-final_aug_2022 | Latency-focused; telco context |
| kube-burner | https://kube-burner.github.io/kube-burner/latest/ | Platform scale / control-plane stress |
| kube-burner-ocp | https://github.com/kube-burner/kube-burner-ocp | OCP canned workloads |
| Ripsaw / Benchmark Operator | https://github.com/cloud-bulldozer/ripsaw | fio, uperf, sysbench, pgbench, HammerDB |
| cloud-bulldozer e2e-benchmarking | https://github.com/cloud-bulldozer/e2e-benchmarking | CI wrapper for kube-burner workloads |
| Red Hat — OpenShift network benchmarking | https://www.redhat.com/en/blog/benchmarking-openshift-network-performance-part-1-basics | uperf methodology on OCP |

## Workspace context

- `devops/ocp/notes/container-density-overcommit.md` — node-level packing (different question, shared tuning surface)
- `research/ocp-container-density-overcommit/paths.md` — density control-plane map
