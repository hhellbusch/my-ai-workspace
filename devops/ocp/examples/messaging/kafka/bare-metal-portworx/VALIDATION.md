---
review:
  status: unreviewed
  notes: "Static validation checklist for bare-metal-portworx Kafka manifests."
---

# Validation — Kafka Bare-Metal Portworx Example

**Audience:** Engineers applying or reviewing these manifests before production use.

**Purpose:** Record what was verified without a live cluster, what requires cluster-side checks, and known caveats from static/doc review.

**Target platform:** OpenShift Container Platform **4.20+**

**Related:** [README.md](README.md) · [OCP examples index](../../../README.md)

---

## Static review status (no cluster)

Performed via YAML parse, doc cross-reference, and OCP 4.20 / Streams 3.1 / Portworx docs.

| Check | Result | Notes |
|-------|--------|-------|
| YAML syntax (all manifests) | Pass | `python3 -c "import yaml; ..."` |
| Internal markdown links | Pass | README → troubleshooting, AI-DISCLOSURE |
| Strimzi KRaft annotations | Pass | `strimzi.io/kraft: enabled` + node pools — Strimzi 0.48+ / Streams 3.1 |
| Strimzi `rack.topologyKey` | Pass | Matches Strimzi configuring docs |
| Kafka / metadataVersion | Pass | `4.1.0` / `4.1-IV1` per Strimzi kafka-versions.yaml |
| Portworx `px/rack` + `racks` SC param | Pass | Matches Portworx topology awareness docs |
| Portworx provisioner | Pass | Primary SC uses `pxd.portworx.com` (CSI) |
| MCP / MachineConfig API shape | Pass | Optional tuning uses Ignition **3.5.0** / `role: worker` |
| Confluent CFK manifests | Pass | `rackAssignment`, KRaft, `storageClass`, RBAC per Confluent docs |
| Server-side apply (`oc apply --dry-run=server`) | Not run | Requires OCP 4.20+ cluster + credentials |
| End-to-end Kafka ready | Not run | Requires operator, nodes, Portworx |

---

## Prerequisites matrix (OCP 4.20+)

| Component | Version for these manifests | Verify |
|-----------|----------------------------|--------|
| **OpenShift** | **4.20+** | `oc version` |
| **Ignition (MachineConfig)** | **3.5.0** | [OCP 4.20 machine config docs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/machine_configuration/machine-configs-configure) |
| **Streams for Apache Kafka** | **3.1** (Kafka 4.1, Strimzi 0.48.x) | `oc get csv -A \| grep amq-streams` |
| **Strimzi** (upstream alternative) | **0.48+** | `oc get csv -A \| grep strimzi` |
| **Confluent Platform Operator** | **CFK 2.8+** (CP 8.x KRaft) | `oc get csv -A \| grep -i confluent` |
| **Confluent Platform** | **8.1.0** (example images) | Pin to licensed version in `kafka-rack-aware.yaml` |
| **Kafka version (Strimzi)** | **4.1.0** | `spec.kafka.version` in `kafka-cluster.yaml` |
| **KRaft metadataVersion (Strimzi)** | **4.1-IV1** | Must match Kafka 4.1.x |
| **Portworx** | CSI driver `pxd.portworx.com` | `oc get csidriver pxd.portworx.com` |

Official references:

- [OCP 4.20 — Machine configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/machine_configuration/index)
- [Streams for Apache Kafka 3.1 on OpenShift](https://docs.redhat.com/en/documentation/red_hat_streams_for_apache_kafka/3.1/)
- [Streams 3.1 — supported configurations (OCP 4.16–4.20)](https://docs.redhat.com/en/documentation/red_hat_streams_for_apache_kafka/3.1/html/release_notes_for_streams_for_apache_kafka_3.1_on_openshift/ref-supported-configurations-str)
- [Strimzi configuring — KRaft](https://strimzi.io/docs/operators/latest/configuring.html)
- [Confluent — rack awareness](https://docs.confluent.io/operator/current/co-configure-rack-awareness.html)
- [Confluent — storage](https://docs.confluent.io/operator/current/co-storage.html)
- [Portworx topology awareness](https://docs.portworx.com/portworx-enterprise/concepts/cluster-topology-awareness)
- [Portworx CSI StorageClass](https://docs.portworx.com/portworx-csi/reference/storage-class)

---

## Cluster-side validation (run before production apply)

### 0. Confirm OCP version

```bash
oc version
# Server Version should be 4.20.x for untested drift on older minors
```

### 1. Confirm Portworx provisioner

```bash
oc get sc -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner | grep -i portworx
```

| Provisioner on cluster | StorageClass file to use |
|------------------------|--------------------------|
| `pxd.portworx.com` | `manifests/common/portworx-storageclass-kafka.yaml` |
| `kubernetes.io/portworx-volume` only | `manifests/common/portworx-storageclass-kafka-legacy-in-tree.yaml` (update `class:` / `storageClass.name` to match) |

### 2. Server-side dry-run

```bash
cd devops/ocp/examples/messaging/kafka/bare-metal-portworx

oc apply --dry-run=server -f manifests/common/portworx-storageclass-kafka.yaml
# Optional — reboots all workers:
# oc apply --dry-run=server -f manifests/common/machineconfig-kafka-tuning.yaml
oc apply --dry-run=server -f manifests/common/confluent-kafka-rbac.yaml
oc apply --dry-run=server -f manifests/zone-region/confluent/
# or: oc apply --dry-run=server -f manifests/custom-rack/confluent/
# Strimzi comparison:
# oc apply --dry-run=server -f manifests/zone-region/strimzi/
```

Fix API version / field errors before real apply. Strimzi operator CSV must support Kafka 4.1.0; CFK CSV must support your CP image version.

### 3. Node topology preflight

```bash
oc get nodes -l node-role.kubernetes.io/worker \
  -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone,RACK:.metadata.labels.px/rack

kubectl get nodes -L px/rack
```

### 4. MCP rollout (optional kernel tuning only)

```bash
# Only if you applied machineconfig-kafka-tuning.yaml (worker role):
oc get mcp worker
oc get machineconfig 99-kafka-kernel-tuning -o yaml | grep 'version:'
# Expect ignition version 3.5.0 on OCP 4.20
```

### 5. CFK deploy smoke (primary)

```bash
oc get kraftcontroller,kafka -n kafka
oc get pods -n kafka -w
oc describe kafka prod-kafka -n kafka
```

### 5b. Strimzi deploy smoke (comparison)

```bash
oc get kafka,kafkanodepool -n kafka
oc get pods -n kafka -w
oc describe kafka prod-kafka -n kafka
```

### 6. Rack awareness verification

```bash
oc get pods -n kafka -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
# CFK:
oc exec -n kafka prod-kafka-0 -- grep broker.rack /opt/confluentinc/etc/kafka/kafka.properties
# Strimzi:
# oc exec -n kafka <broker-pod> -- grep broker.rack /opt/kafka/config/server.properties
PX_NS=${PX_NS:-portworx}
PX_POD=$(oc get pods -n $PX_NS -l name=portworx -o jsonpath='{.items[0].metadata.name}')
oc exec -n $PX_NS $PX_POD -- /opt/pwx/bin/pxctl volume inspect <volume-id>
```

### 7. Upgrade safety

```bash
oc get pdb -n kafka
oc get mcp worker -o jsonpath='{.spec.maxUnavailable}{"\n"}'
```

---

## Known caveats

1. **Plaintext listener** — `kafka-cluster.yaml` uses `tls: false` on port 9092 for simplicity. Add TLS listeners for production.
2. **Kafka 4.1 only** — These manifests target Kafka 4.1 / KRaft. Do not apply to clusters still on ZooKeeper or Kafka 3.x without version changes.
3. **Red Hat vs upstream images** — With Streams 3.1, use Red Hat-built Kafka images from the operator bundle; upstream Strimzi uses different image references.
4. **Confluent manifests** — Static review against CFK 2.8+ docs; confirm `oc api-resources | grep confluent` and pin images to your licensed CP version before apply.
5. **Sizing placeholders** — CPU, memory, and `2Ti` storage are not capacity-planned.
6. **Portworx backend** — `io_profile` / `priority_io` support depends on Portworx version and underlying array.
7. **ACM BMAC examples** — Illustrative hub BMH; confirm InfraEnv namespace, BMC credentials, and `infraenvs.agent-install.openshift.io` label match your GitOps layout.

---

## Re-validate after changes

1. Re-run YAML parse on changed files.
2. Re-run `oc apply --dry-run=server` on an OCP 4.20+ cluster.
3. Update this file's static review table if scope changes.

*Example configurations — not production-ready without cluster validation. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md).*
