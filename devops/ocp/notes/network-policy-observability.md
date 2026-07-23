---
review:
  status: unreviewed
  notes: "New reference — network policy and observability for Kafka/Flink on OCP."
---

# Network Policy and Observability on OpenShift

> **Audience:** Platform engineers securing or troubleshooting Kafka and Flink workloads on OpenShift Container Platform with OVN-Kubernetes.
>
> **Purpose:** Explain how network policies are enforced, how to observe allow/deny decisions, and what ports and policy patterns Kafka (Strimzi vs Confluent) and Flink need.

**Target platform:** OCP 4.18+ (OVN-Kubernetes default).

**Related:**

- [OVN-Kubernetes install config](../examples/ovn-kubernetes-install-config/README.md) — `policyAuditConfig` on the cluster `Network` CR
- [Kafka on bare-metal with Portworx](../examples/kafka-bare-metal-portworx/README.md) — rack-aware Confluent/Strimzi examples
- [NetworkAttachmentDefinition (NAD)](../examples/network-attachment-definitions/README.md) — additional networks beyond the default pod network
- [Audit logging for network security](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/network_security/logging-network-security) — OVN ACL audit logging (Red Hat docs)
- [Network Observability network policy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/observability/network_observability/network-observability-network-policy) — NetObserv + OVN events (Red Hat docs)

---

## On this page

- [How policies work on OCP](#how-policies-work-on-ocp)
- [Observability options](#observability-options)
- [Kafka: Strimzi vs Confluent](#kafka-strimzi-vs-confluent)
- [Flink network requirements](#flink-network-requirements)
- [End-to-end design checklist](#end-to-end-design-checklist)
- [Debugging workflow](#debugging-workflow)

---

## How policies work on OCP

OVN-Kubernetes translates Kubernetes network policy objects into OVN access control lists (ACLs).
OpenShift also supports stronger policy types that platform teams use for default-deny baselines.

| Policy type | Scope | Typical use |
|-------------|-------|-------------|
| **NetworkPolicy** | Namespace | App-team ingress/egress rules |
| **AdminNetworkPolicy (ANP)** | Cluster | Admin overrides, tenant isolation |
| **BaselineAdminNetworkPolicy (BANP)** | Cluster | Default-deny with explicit allows |
| **EgressFirewall** | Namespace | Block or allow egress to external CIDRs |

**Default behavior:** Pods with no matching policy are fully open.
Once a pod is selected by any `NetworkPolicy`, it becomes *isolated* — only explicitly allowed traffic passes.

**Common gotchas:**

- **DNS** must be allowed under default-deny.
  On OCP, egress to `openshift-dns` on UDP/TCP **5353** (or `kube-dns` on port 53 in upstream clusters).
- Policies match **pod labels**, not Deployment or CR names.
- Cross-namespace flows use `namespaceSelector` + `podSelector`.
- `EgressFirewall` controls traffic to external IPs; `NetworkPolicy` controls pod-to-pod and pod-to-service traffic inside the cluster.
- **ANP/BANP precedence:** Admin and baseline admin policies evaluate alongside namespace `NetworkPolicy` objects.
  A BANP default-deny can block traffic even when a namespace `NetworkPolicy` allows it — design platform baselines and namespace policies together, not in isolation.
- **External egress** (S3 checkpoints, schema registry outside the cluster) needs `EgressFirewall` or an explicit egress allow to the target CIDR on port 443 — a namespace `NetworkPolicy` alone is not enough for traffic leaving the cluster.

Cluster-wide audit log settings live in `policyAuditConfig` on the `Network` CR.
See [OVN-Kubernetes install config — Policy Audit Config](../examples/ovn-kubernetes-install-config/README.md#policy-audit-config-parameters).

---

## Observability options

Two complementary approaches — use both in production Kafka/Flink environments.

### 1. OVN ACL audit logging (policy-centric)

Answers: *Which policy blocked this connection?*

**Cluster level:** Configure `policyAuditConfig` on the `Network` CR (destination, rate limit, syslog facility).

**Namespace level:** Annotate namespaces under observation:

```yaml
metadata:
  annotations:
    k8s.ovn.org/acl-logging: '{ "deny": "alert", "allow": "notice" }'
```

Logs appear in `/var/log/ovn/acl-audit-log.log` on OVN pods and optionally at a configured syslog/UDP destination.
Each entry includes verdict (`allow`/`drop`), source/dest IPs and ports, and the ACL name (for example `NP:kafka/my-policy:Ingress:0`).

**Pros:** Direct tie to policy decisions; low setup overhead.
**Cons:** Rate-limited (default 20 messages/second/node); not a full flow topology view.

### 2. Network Observability Operator (flow-centric)

Answers: *Who is talking to whom, and was traffic allowed or denied?*

**Version matrix** (OVN network events — verify on your z-stream before production reliance):

| Component | Minimum | Status |
|-----------|---------|--------|
| OCP | 4.18 | `OVNObservability` feature gate required |
| NetObserv Operator | 1.8 | OVN `NetworkEvents` (Technology Preview) |
| OVN ACL audit logging | Any OVN-Kubernetes cluster | GA — no feature gate |

Requires:

- Network Observability Operator **1.8+** installed
- Loki or Kafka as flow storage backend
- OCP 4.18+ with `OVNObservability` feature gate enabled (`oc edit featuregate cluster`)
- `FlowCollector` with eBPF `NetworkEvents`:

```yaml
apiVersion: flows.netobserv.io/v1beta2
kind: FlowCollector
metadata:
  name: cluster
spec:
  agent:
    type: eBPF
    ebpf:
      sampling: 1
      privileged: true
      features:
        - "NetworkEvents"
  loki:
    enable: true
```

Provides flow records enriched with Kubernetes metadata, allow/deny events for NetworkPolicy/ANP/EgressFirewall, and console dashboards under **Observe → Dashboards → NetObserv**.

**Pros:** Visual troubleshooting, historical search, cross-workload correlation.
**Cons:** Heavier footprint (eBPF agent per node, storage backend); OVN network events are Technology Preview on 4.18+.

Treat NetObserv OVN events as preview — validate on your z-stream before using them as compliance evidence.
Prefer OVN ACL audit logging for incident response until preview features are GA on your version.

### When to use which

| Need | Tool |
|------|------|
| Design and validate policies before rollout | Git-managed YAML + `oc describe networkpolicy` |
| Runtime deny debugging during an incident | OVN ACL audit logging on affected namespaces |
| Ongoing visibility and compliance evidence | NetObserv + Loki |

---

## Kafka: Strimzi vs Confluent

> **Unverified:** Port and policy behavior below is doc-sourced.
> Not validated on a live locked-down cluster in this workspace.
> Confirm generated policies and pod labels on a staging cluster before production rollout.

The **Kafka protocol ports are the same** regardless of operator.
Differences are in **who generates policies** and **how you declare allowed clients**.

### Shared Kafka port model

| Port | Between | Purpose |
|------|---------|---------|
| **9090–9091** | Broker ↔ broker | Inter-broker replication (reserved; not client listeners) |
| **9092+** | Clients → broker | Listener ports (configurable per listener) |
| **9404** | Prometheus → broker | Metrics (reserved) |
| **9999** | JMX | Monitoring (reserved) |
| **443** | External clients → Route | OpenShift Route listener (passthrough to broker port, e.g. 9094) |

Under default-deny, every client listener port you expose must appear in an allow rule on both sides (client egress and broker ingress).

### Strimzi / Streams for Apache Kafka

Strimzi **auto-generates `NetworkPolicy` resources** for each Kafka cluster.
You declare who may connect via `networkPolicyPeers` on each listener in the `Kafka` CR:

```yaml
listeners:
  - name: plain
    port: 9092
    type: internal
    networkPolicyPeers:
      - podSelector:
          matchLabels:
            app: flink
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: flink
```

Strimzi also generates policies for:

- Inter-broker traffic (9090/9091)
- Entity Operator, Cruise Control, Kafka Connect (if deployed)
- Cluster Operator → broker/controller connectivity (operator must reach the Kafka namespace)

#### Cross-namespace operator (`openshift-operators`)

Many clusters install the Streams/Strimzi operator in `openshift-operators` while Kafka runs in `kafka`.
Strimzi generates operand policies in the Kafka namespace, but a cluster-wide BANP or a deny-all in `openshift-operators` can still block the operator from reaching brokers.

**Verify first:**

```bash
oc get networkpolicy -n kafka
oc get pods -n openshift-operators -l name=strimzi-cluster-operator
oc logs -n openshift-operators deploy/strimzi-cluster-operator --tail=30
```

**If the operator cannot reconcile:**

1. Inspect Strimzi-generated policies in `kafka` — they usually include operator ingress rules with `namespaceSelector: {}` or a label you control.
2. If your operator namespace has no usable labels, set `STRIMZI_OPERATOR_NAMESPACE_LABELS` on the Cluster Operator deployment so generated policies can match it.
3. As a last resort, add an explicit allow from `openshift-operators` to `kafka` — copy ports from the generated `*-cluster-operator-*` NetworkPolicy rather than guessing.

**Same-namespace operator:** Strimzi handles operator connectivity automatically when the Cluster Operator runs in the same namespace as the Kafka cluster.

**KRaft note:** Controller pods use metadata ports distinct from client listeners.
Strimzi's generated policies cover controller-to-broker paths — do not replace them with hand-written policies unless you understand the full port map.

### Confluent Platform Operator (CFK)

CFK does **not** auto-generate Kubernetes `NetworkPolicy` objects the way Strimzi does.
You write policies yourself (or via a policy-as-code layer like RHACM/Gatekeeper).

What CFK provides instead:

- **Listener configuration** on the `Kafka` CR (`spec.listeners`) — same port semantics as upstream Kafka
- **RBAC** for rack assignment and operator reconciliation (see [confluent-kafka-rbac.yaml](../examples/kafka-bare-metal-portworx/manifests/common/confluent-kafka-rbac.yaml))
- **Route / Ingress / LoadBalancer** exposure for external clients — clients connect on 443 (Route) or the Service port you define

**Implication:** On a locked-down cluster, CFK requires more explicit policy authoring.
You must allow:

| Source | Destination | Ports |
|--------|-------------|-------|
| CFK operator namespace | Kafka, KRaft controller pods | Discover from generated Services and `oc get netpol` on a staging cluster — do not guess |
| Broker pods | Broker pods | 9090–9091 (inter-broker) |
| Client pods (Flink, apps) | Broker listeners | 9092+ per listener config |
| Prometheus | Brokers | 9404 |
| Brokers | DNS | 5353/53 |

**CFK pod labels** (for `podSelector` in hand-written policies — confirm with `oc get pods -n kafka --show-labels`):

| Label | Example value | Use |
|-------|---------------|-----|
| `app` | `prod-kafka` (matches Kafka CR `metadata.name`) | Broker targeting |
| `platform.confluent.io/type` | `kafka` | Component type |
| `confluent-platform` | `"true"` | All CFK operands |

### Side-by-side summary

| Aspect | Strimzi / Streams | Confluent CFK |
|--------|-------------------|---------------|
| Policy generation | Auto per cluster + listener `networkPolicyPeers` | Manual (your responsibility) |
| Client allow-list | Declarative in `Kafka` CR | Manual `NetworkPolicy` YAML |
| Operator connectivity | Generated policies (same-ns operator) | You must allow operator → operand |
| External access | `route`, `ingress`, `loadbalancer` listeners | Same listener types; Route on 443 |
| Observability hooks | Same OVN audit + NetObserv | Same OVN audit + NetObserv |

For rack-aware bare-metal examples with both operators, see [kafka-bare-metal-portworx](../examples/kafka-bare-metal-portworx/README.md).

---

## Flink network requirements

Flink adds **intra-cluster** flows on top of the Kafka client connection.

### Intra-Flink (JobManager ↔ TaskManager)

| Port | Protocol | Purpose |
|------|----------|---------|
| **6123** | TCP | RPC (control plane) |
| **6124** | TCP | Blob server (JARs, distributed cache) |
| **8081** | TCP | REST API / Web UI |
| **6121–6122** | TCP | Data exchange (default; configurable) |

### Flink → Kafka

| Port | Protocol | Purpose |
|------|----------|---------|
| **9092+** | TCP | Consumer/producer traffic to broker listener |
| **9093** | TCP | TLS listener (if configured) |

### Flink → other dependencies

| Target | Port | Notes |
|--------|------|-------|
| DNS | 5353 / 53 | Required under default-deny |
| Schema Registry | 8081 (typical) | If using Apicurio or Confluent Schema Registry |
| S3 / object storage | 443 | Checkpoint and savepoint state |
| Prometheus | 9249 | Flink metrics (if scraped) |

### Example policy sketch (Flink namespace)

Broker `podSelector` by operator (confirm labels on your cluster):

| Operator | `podSelector` |
|----------|---------------|
| Strimzi | `strimzi.io/kind: Kafka` + `strimzi.io/cluster: prod-kafka` |
| CFK | `app: prod-kafka` + `platform.confluent.io/type: kafka` |

**Strimzi egress** (Flink → Kafka):

```yaml
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kafka
          podSelector:
            matchLabels:
              strimzi.io/kind: Kafka
              strimzi.io/cluster: prod-kafka
      ports:
        - { protocol: TCP, port: 9092 }
```

**CFK egress** (same flow, different labels):

```yaml
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kafka
          podSelector:
            matchLabels:
              app: prod-kafka
              platform.confluent.io/type: kafka
      ports:
        - { protocol: TCP, port: 9092 }
```

Full Flink namespace policy (Strimzi variant):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: flink-allow-kafka-and-internal
  namespace: flink
spec:
  podSelector:
    matchLabels:
      app: flink
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: flink
      ports:
        - { protocol: TCP, port: 6123 }
        - { protocol: TCP, port: 6124 }
        - { protocol: TCP, port: 8081 }
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: openshift-dns
      ports:
        - { protocol: UDP, port: 5353 }
    - to:
        - podSelector:
            matchLabels:
              app: flink
      ports:
        - { protocol: TCP, port: 6123 }
        - { protocol: TCP, port: 6124 }
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kafka
          podSelector:
            matchLabels:
              strimzi.io/kind: Kafka
              strimzi.io/cluster: prod-kafka
      ports:
        - { protocol: TCP, port: 9092 }
```

For CFK, swap the final egress block for the CFK variant above.

**Watch for:** Custom `taskmanager.data.port` and `taskmanager.rpc.port` values — pin a known port range in both Flink config and network policy rather than leaving ephemeral ports open.
Schema Registry and external checkpoint storage need separate egress rules (see [Flink → other dependencies](#flink--other-dependencies)).

---

## End-to-end design checklist

1. **Namespace layout:** `kafka`, `flink`, and optionally `netobserv` (dedicated namespace for Loki/Kafka storage backends).
2. **Default posture:** BANP or namespace-level default-deny with explicit allows — reconcile BANP rules with namespace `NetworkPolicy` (BANP can override allows).
3. **Kafka policies:**
   - Strimzi: configure `networkPolicyPeers` per listener; verify generated policies with `oc get networkpolicy -n kafka`
   - Strimzi cross-ns operator: confirm `openshift-operators` → `kafka` path if operator is not co-located
   - CFK: write ingress/egress policies for brokers, controllers, and operator; confirm labels with `oc get pods --show-labels`
4. **Flink policies:** Allow internal JM/TM ports, egress to Kafka listener port, DNS, Schema Registry (if used), and checkpoint storage (`EgressFirewall` or egress to 443 for S3).
5. **Audit logging:** Enable `k8s.ovn.org/acl-logging` on `kafka` and `flink` namespaces (`"deny": "alert"`).
6. **NetObserv:** Operator 1.8+, Loki backend, `OVNObservability` gate, `NetworkEvents` in FlowCollector — treat as preview until validated on your z-stream.
7. **Alerting:** Ship ACL deny logs and NetObserv denied flows to your SIEM or Alertmanager.

---

## Debugging workflow

When Flink cannot reach Kafka:

1. **Connectivity test** from a TaskManager pod:

   ```bash
   oc exec -n flink deploy/flink-taskmanager -- \
     nc -zv my-cluster-kafka-bootstrap.kafka.svc 9092
   ```

2. **NetObserv:** Filter by source namespace `flink`, destination `kafka`; look for denied flows.

3. **OVN ACL audit log:** Search for `verdict=drop` and the policy name on an OVN pod:

   ```bash
   oc exec -n openshift-ovn-kubernetes <ovn-pod> -- \
     grep verdict=drop /var/log/ovn/acl-audit-log.log | tail -20
   ```

4. **Label verification:** Policies match pod labels, not CR names.

   ```bash
   oc get pods -n kafka --show-labels
   oc get pods -n flink --show-labels
   oc get networkpolicy -n kafka -o yaml
   oc get networkpolicy -n flink -o yaml
   ```

5. **DNS:** Confirm resolution inside the Flink pod:

   ```bash
   oc exec -n flink deploy/flink-taskmanager -- \
     nslookup my-cluster-kafka-bootstrap.kafka.svc.cluster.local
   ```

6. **Route vs internal listener:** If using a Strimzi/CFK `route` listener, clients connect on **443** through the router — broker pod policies still apply to the passthrough path.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
