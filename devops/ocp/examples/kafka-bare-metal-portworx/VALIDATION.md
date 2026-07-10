# Validation — Kafka Bare-Metal Portworx Example

**Audience:** Engineers applying or reviewing these manifests before production use.

**Purpose:** Record what was verified without a live cluster, what requires cluster-side checks, and known caveats from static/doc review.

**Related:** [README.md](README.md) · [OCP examples index](../README.md)

---

## Static review status (no cluster)

Performed via YAML parse, doc cross-reference, and workspace Portworx/Strimzi/OCP conventions.

| Check | Result | Notes |
|-------|--------|-------|
| YAML syntax (all manifests) | Pass | `python3 -c "import yaml; ..."` |
| Internal markdown links | Pass | README → troubleshooting, AI-DISCLOSURE |
| Strimzi KRaft annotations | Pass | Matches Strimzi 0.40+ / AMQ Streams 2.9 KRaft docs |
| Strimzi `rack.topologyKey` | Pass | Matches Strimzi configuring docs |
| Portworx `px/rack` + `racks` SC param | Pass | Matches Portworx topology awareness docs |
| Portworx provisioner | Fixed | Primary SC uses `pxd.portworx.com` (CSI); legacy in-tree in separate file |
| MCP / MachineConfig API shape | Pass | Valid `MachineConfigPool` and `MachineConfig` objects |
| Confluent example | Illustrative only | API group/fields vary by operator version; image placeholder required |
| Ignition version in MC | Documented | Default `3.4.0` (OCP 4.16+); see file header for other OCP versions |
| Server-side apply (`oc apply --dry-run=server`) | Not run | Requires cluster + credentials |
| End-to-end Kafka ready | Not run | Requires operator, nodes, Portworx |

---

## Prerequisites matrix

Align operator, Kafka, and OpenShift versions before apply.

| Component | Minimum for these manifests | Verify |
|-----------|----------------------------|--------|
| **Strimzi operator** | 0.40+ (KRaft greenfield) | `oc get csv -A \| grep strimzi` |
| **AMQ Streams** | 2.7+ (2.9+ recommended for KRaft docs parity) | `oc get csv -A \| grep amq-streams` |
| **Kafka version** | 3.7.0 | `spec.kafka.version` in `kafka-cluster.yaml` |
| **KRaft metadataVersion** | 3.7-IV4 (must match Kafka 3.7.x) | Strimzi version matrix |
| **Portworx** | CSI driver `pxd.portworx.com` | `oc get csidriver pxd.portworx.com` |
| **OpenShift** | 4.14+ typical for KafkaNodePool; MC ignition per OCP version | `oc version` |

Official references:

- [Strimzi configuring — KRaft](https://strimzi.io/docs/operators/latest/configuring.html)
- [AMQ Streams KRaft mode](https://docs.redhat.com/en/documentation/red_hat_streams_for_apache_kafka/2.9/html/deploying_and_managing_streams_for_apache_kafka_on_openshift/assembly-kraft-mode-str)
- [Portworx topology awareness](https://docs.portworx.com/portworx-enterprise/concepts/cluster-topology-awareness)
- [Portworx CSI StorageClass](https://docs.portworx.com/portworx-csi/reference/storage-class)

---

## Cluster-side validation (run before production apply)

### 1. Confirm Portworx provisioner

```bash
oc get sc -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner | grep -i portworx
```

| Provisioner on cluster | StorageClass file to use |
|------------------------|--------------------------|
| `pxd.portworx.com` | `manifests/common/portworx-storageclass-kafka.yaml` |
| `kubernetes.io/portworx-volume` only | `manifests/common/portworx-storageclass-kafka-legacy-in-tree.yaml` (update Strimzi `class:` to match name) |

### 2. Server-side dry-run

```bash
cd devops/ocp/examples/kafka-bare-metal-portworx

oc apply --dry-run=server -f manifests/common/portworx-storageclass-kafka.yaml
oc apply --dry-run=server -f manifests/common/machineconfigpool-kafka-worker.yaml
oc apply --dry-run=server -f manifests/common/machineconfig-kafka-tuning.yaml
oc apply --dry-run=server -f manifests/strimzi/
```

Fix API version / field errors before real apply.

### 3. Node topology preflight

```bash
# At least 3 kafka-labeled nodes with distinct zones and px/rack
oc get nodes -l node-role.kubernetes.io/kafka \
  -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone,RACK:.metadata.labels.px/rack

# Portworx sees racks
kubectl get nodes -L px/rack
```

Scheduling with `topologySpreadConstraints` + `DoNotSchedule` **fails** if fewer than three zones are represented on kafka workers.

### 4. MCP rollout

```bash
oc get mcp kafka-worker
oc get machineconfig | grep kafka
```

Expect brief `Updating` on `kafka-worker` after MachineConfig apply. Pool `Degraded` with mismatched ignition version — adjust `machineconfig-kafka-tuning.yaml` per file header.

### 5. Strimzi deploy smoke

```bash
oc get kafka,kafkanodepool -n kafka
oc get pods -n kafka -w
oc describe kafka prod-kafka -n kafka
```

### 6. Rack awareness verification

```bash
# Pods spread across zones
oc get pods -n kafka -o custom-columns=NAME:.metadata.name,ZONE:.spec.nodeName,NODE:.spec.nodeName

# broker.rack inside broker pod
oc exec -n kafka <broker-pod> -- grep broker.rack /opt/kafka/config/server.properties 2>/dev/null || true

# Portworx volume replicas across racks
pxctl volume list
pxctl volume inspect <volume-id>
```

### 7. Upgrade safety

```bash
oc get pdb -n kafka
oc get mcp kafka-worker -o jsonpath='{.spec.maxUnavailable}{"\n"}'
```

---

## Known caveats

1. **Plaintext listener** — `kafka-cluster.yaml` uses `tls: false` on port 9092 for simplicity. Add TLS listeners for production.
2. **Confluent manifest** — Illustrative; confirm `oc api-resources` and operator docs before apply.
3. **Sizing placeholders** — CPU, memory, and `2Ti` storage are not capacity-planned.
4. **Portworx backend** — `io_profile` / `priority_io` support depends on Portworx version and underlying array; confirm in your PX release notes.
5. **Controller + broker anti-affinity** — Strimzi examples anti-affinity on `strimzi.io/kind: Kafka` prevents two Kafka pods per node (brokers and controllers). Ensure enough nodes for 3 controllers + 3 brokers across 3 racks.
6. **No Helm / external Kafka paths validated** — README describes them; only common + Strimzi + Confluent YAML were statically reviewed.

---

## Re-validate after changes

When editing manifests in this directory:

1. Re-run YAML parse on changed files.
2. Re-run `oc apply --dry-run=server` on a cluster matching target OCP/operator versions.
3. Update this file's static review table if scope changes.

*Example configurations — not production-ready without cluster validation. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md).*
