---
review:
  status: unreviewed
  notes: "Triage for Kafka/Confluent init stuck on kubernetes.default — NetworkPolicy, ANP priority, webhook, and OVN paths."
---

# Kafka Broker Stuck in Init — Cannot Reach `kubernetes` Service

> **Audience:** Platform engineers troubleshooting Confluent (classic Helm) or other Kafka brokers on OpenShift when init containers cannot reach the in-cluster API.
>
> **Purpose:** Split “cannot contact `kubernetes.default`” into webhook/API vs OVN vs NetworkPolicy paths, capture field signals, and avoid broker-delete cascades.

**Related:**

- [API Slowness and Web Console Performance](../api-slowness-web-console/README.md) — API latency, webhook timeouts
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) — node/OVN network diagnostics
- [Debug Toolbox Container](../debug-toolbox-container/README.md) — probe from a pod on the same node
- [Kafka on OpenShift tenancy](../../notes/kafka-on-openshift-tenancy.md) — broker flap / PDB / upgrade coupling
- [Network policy and observability](../../notes/network-policy-observability.md) — default-deny, DNS/API egress, OVN ACL audit

---

## Symptom

Kafka broker pods (classic Confluent Helm install observed) stick in **Init**.
Init logs show API client errors such as `max retries exceeded` with a path like `/api/v1/namespaces/<ns>/pods/<pod>` and `Failed to establish a new connection: Connection timed out`.
The client still targets the **`kubernetes` Service** in `default` (`$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT`) — not the broker pod named in the URL.

Operators delete stuck pods to recover.
That can cascade: more brokers leave ISR / go offline under recovery load.

### Signals that often co-occur

| Signal | What it suggests |
|--------|------------------|
| Strict OVN-K + default-deny NetworkPolicy / BANP | **Path C** — classic Helm does not auto-allow kube-apiserver egress |
| Intermittent failures; multiple ANPs share the same `spec.priority` | **Path C** — ANP evaluation order is undefined at equal priority |
| Apiserver logs show failed admission webhook calls (often **x509** / TLS trust) and elevated `kube-apiserver` restart counts | **Path A** — API-path / webhook stress |
| Elevated `ovnkube-node` restart counts; TCP to the kubernetes Service fails | **Path B** — ClusterIP / OVN path |

None of these alone proves the broker init failure.
Use the fork below before picking a remediation.

**Consistency hint:** Missing API egress in namespace `NetworkPolicy` is often **consistent** for every pod matching the selector.
**Intermittent** init failures on a locked-down cluster — especially when control-plane egress rules already exist — check **duplicate ANP priorities** before assuming OVN or chart bugs.
“Occasional” plus delete-pod-to-fix also fits Path B (OVN flap) or Path A (API/webhook load) when policies/labels are uneven, BANP and namespace policies disagree, or OVN ACL programming lags during `ovnkube-node` restarts (Path B + C together).

---

## What `kubernetes.default` is

The `kubernetes` Service in `default` is the ClusterIP front door to the kube-apiserver for in-cluster clients.
Broker init containers that need the API (SA token, labels, peer discovery, wait logic) talk to `$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT`.

In-cluster clients use the **Service port** (typically **443**), not the apiserver **endpoint port** on control-plane nodes (**6443**).
This is usually **not** a Confluent chart bug once the failure is “cannot reach the kubernetes Service.”

---

## Severity

**HIGH** for Kafka availability.

Intermittent API or pod-network reachability plus “delete pod to fix” turns a platform issue into a broker churn incident.

---

## Triage fork (do this first)

Capture the **exact** init failure class:

| Failure class | Likely path | Lead with |
|---------------|-------------|-----------|
| TCP timeout to the **kubernetes Service** on a **default-deny** cluster | Missing/incorrect egress or ANP priority collision | Path C |
| TCP timeout / connection refused / no route, **without** policy deny evidence | OVN / node networking | Path B |
| TCP connects, then TLS, HTTP 5xx, timeout, or admission denial | Apiserver / webhook | Path A |
| Ambiguous or mixed | Multiple | Path C inventory (including ANP priorities) + Path A/B correlation |

```bash
# Stuck brokers and nodes
oc get pods -n <kafka-ns> -o wide | grep -E 'Init|Error|Crash'
oc describe pod -n <kafka-ns> <broker-pod> | sed -n '/Init Containers/,/Containers:/p'

# kubernetes Service and endpoints (should list apiserver IPs)
oc get svc kubernetes -n default -o wide
oc get endpoints kubernetes -n default -o wide

# Strict-cluster: list policies before assuming OVN is broken
oc get networkpolicy,adminnetworkpolicy,baselineadminnetworkpolicy -A
oc get networkpolicy -n <kafka-ns> -o yaml

# ANP priority collisions (OVN-K accepts 0–99; lower number = higher precedence; BANP has no priority)
oc get adminnetworkpolicy -o json | jq -r '
  .items[] | "\(.metadata.name)\tpriority=\(.spec.priority)"' | sort -t$'\t' -k2 -n

# Control plane / network operators
oc get co kube-apiserver network
oc get pods -n openshift-kube-apiserver -o wide
oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide
```

From a **debug pod on the same node** as a stuck broker (see [debug toolbox](../debug-toolbox-container/README.md)):

```bash
# Substitute host/port from the broker pod env or kubernetes Service
curl -vk --connect-timeout 5 \
  "https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}/readyz"
```

- Fails before TLS on a locked-down namespace → Path C first, then Path B.
- Fails before TLS with policies clearly allowing API → Path B.
- Reaches TLS / HTTP → Path A (API health, webhooks, load).

**Important:** A debug pod only proves Path C if it uses the **same labels** (and therefore the same NetworkPolicy selection) as the broker/init pod.
A privileged toolbox with different labels can reach the API while the broker still cannot.

---

## Path A — Broken admission webhook / apiserver stress

### Why it fits

Admission webhooks sit on the apiserver request path.
An **x509** failure talking to a webhook service means the apiserver cannot validate the webhook TLS trust (wrong CA, expired cert, name mismatch, or stale `caBundle`).

If `failurePolicy: Fail`, matching API calls fail hard.
If `Ignore`, you still get latency, log spam, and load — enough to make init look like “API unreachable” under timeouts.

High **kube-apiserver** restart counts while webhook errors spam the logs are a red flag, not background noise.

### Checks

```bash
oc get validatingwebhookconfiguration,mutatingwebhookconfiguration

# Inspect failurePolicy, timeoutSeconds, clientConfig (service + caBundle)
# Replace <webhook-fragment> with a name substring from the listing above
oc get validatingwebhookconfiguration -o yaml | grep -iA30 <webhook-fragment>
oc get mutatingwebhookconfiguration -o yaml | grep -iA30 <webhook-fragment>

# Apiserver logs: webhook / x509
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=200 \
  | grep -iE 'webhook|x509|certificate'

# Webhook backend health (namespace/service names vary by install)
oc get pods,svc -A | grep -i <webhook-fragment>
```

### Remediation direction (change-control required)

1. Fix the webhook TLS trust: renew cert, correct SANs, refresh `caBundle` in the webhook configuration to match what the service presents.
2. Confirm with the webhook owners whether `failurePolicy: Ignore` is acceptable for non-critical hooks (operational tradeoff — do not change silently).
3. Emergency only: disable or remove a broken webhook configuration when change control allows — restores API path at the cost of losing that admission control until restored.

After remediation, watch apiserver restart rate and broker init success without mass deletes.

### Related guide

Broader API latency and webhook timeout patterns: [API Slowness](../api-slowness-web-console/README.md).

---

## Path B — OVN / ClusterIP reachability

### Why it fits

ClusterIP traffic to `kubernetes.default` traverses OVN-Kubernetes.
Frequent **`ovnkube-node` restarts** can produce **occasional**, node-local blackholes.
Deleting a broker pod “fixes” it when the new pod lands on a healthier node or OVN recovers — which matches intermittent recoveries.

### Checks

```bash
# Restart correlation: which nodes, how often
oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node \
  -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp

# Map stuck brokers → nodes with high ovnkube-node restarts
oc get pods -n <kafka-ns> -o wide

# Network CO and OVN pods
oc get co network
oc logs -n openshift-ovn-kubernetes -c ovnkube-node --tail=200 \
  "$(oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-node \
    --field-selector spec.nodeName=<broker-node> -o name | head -1)"
```

If TCP to the kubernetes Service fails from the broker node while apiserver endpoints are healthy elsewhere, treat as an OVN / node networking incident (support case material).
Do not attribute it to the Helm chart.

### Related guide

[CoreOS Networking Issues](../coreos-networking-issues/README.md).

---

## Path C — Policy gaps (strict NetworkPolicy / ANP / BANP)

### Why it fits

Once a pod is selected by any `NetworkPolicy`, it is **isolated**: only explicitly allowed egress works.
Under default-deny / BANP baselines, brokers need platform- or namespace-level allows for:

| Destination | Port | Why brokers/init need it |
|-------------|------|--------------------------|
| `openshift-dns` pods | UDP/TCP **5353** | Cluster DNS (CoreDNS listens on 5353; Service presents port 53) |
| **`kubernetes` Service** (in-cluster API VIP) | TCP **443** | Init containers and operators use `$KUBERNETES_SERVICE_HOST` / `$KUBERNETES_SERVICE_PORT` |
| Control-plane nodes (optional supplement) | TCP **6443** | Direct or post-DNAT paths; does **not** replace the Service **443** allow |

Classic **Confluent Helm** does not generate NetworkPolicies.
Strimzi often does for listeners; CFK still expects you to author policies by hand.
It is easy to allow broker↔broker and DNS and still **omit API egress** — then init fails with connection timeouts to the kubernetes Service.

**Do not hardcode the kubernetes Service address** (`/32` in `ipBlock`) as a long-term fix.
That VIP is cluster-specific and masks policy-design problems.
Prefer a **platform ANP baseline** (optional BANP `default` for tier-3 guardrails; see [Network policy and observability](../../notes/network-policy-observability.md#platform-baseline-egress)) or allow the cluster **`serviceNetwork` CIDR** on TCP **443** when namespace policy must own API egress.

### Control-plane rules are not enough

`AdminNetworkPolicy` egress to **control-plane nodes** on **6443** (or **443**) matches a **different destination** than traffic to the **kubernetes Service VIP on 443**.
In-cluster API clients use the Service front door.
A policy stack that only allows control-plane nodes can still drop init traffic — or appear to work intermittently when combined with other rules.

Standard namespace **`NetworkPolicy`** cannot use the `nodes` peer; only ANP/BANP can target control-plane nodes.

### ANP priority collisions

On OVN-Kubernetes, each `AdminNetworkPolicy` has `spec.priority` in **0–99** (**lower number = higher precedence**).
`BaselineAdminNetworkPolicy` has **no priority field** (singleton `default`, evaluated in tier 3 after namespace `NetworkPolicy`).
Red Hat documents that **there is no guarantee which policy wins when two ANPs share the same priority** — evaluation order becomes nondeterministic.

Symptoms match Path B (intermittent timeouts, delete-pod-to-fix) but root cause is policy tiering.
After assigning **unique, deliberate priorities**, API/DNS allows stabilize without per-cluster Service VIP `/32` rules.

Reference: [Admin network policy — OCP 4.18](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/network_security/admin-network-policy) (priority and precedence).

See [Network policy and observability](../../notes/network-policy-observability.md) (DNS gotcha, platform baseline, ANP priority, OVN ACL audit).

### Checks

```bash
# Namespace and cluster-scoped policy inventory
oc get networkpolicy -n <kafka-ns>
oc get adminnetworkpolicy,baselineadminnetworkpolicy

# Do policies select the broker pods? Compare labels.
oc get pods -n <kafka-ns> --show-labels | head
oc get networkpolicy -n <kafka-ns> -o yaml | grep -E 'podSelector|namespaceSelector|policyTypes|ports:|ipBlock'

# Look for egress to DNS (5353) and API (Service port 443)
oc get networkpolicy -n <kafka-ns> -o json | jq '
  .items[] | {
    name: .metadata.name,
    types: .spec.policyTypes,
    egress: .spec.egress
  }'

# Duplicate ANP priorities (BANP has no priority field)
oc get adminnetworkpolicy -o json | jq -r '
  .items | group_by(.spec.priority) | map(select(length > 1)) |
  .[] | "priority \(.[0].spec.priority): " + (map(.metadata.name) | join(", "))'

# OVN ACL audit (if enabled) — deny verdicts toward the kubernetes Service VIP
# Annotate ns: k8s.ovn.org/acl-logging: '{ "deny": "alert", "allow": "notice" }'
```

**Namespace policy shape** (when platform baseline does not already allow API/DNS — adapt labels; confirm `serviceNetwork` from the cluster):

```yaml
# Illustrative — prefer platform ANP for DNS + API when possible
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-broker-egress-platform
  namespace: <kafka-ns>
spec:
  podSelector:
    matchLabels:
      app: <broker-label>   # must match broker / init pods
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: openshift-dns
      ports:
        - protocol: UDP
          port: 5353
        - protocol: TCP
          port: 5353
    - to:
        - ipBlock:
            cidr: <serviceNetwork-CIDR>   # oc get network cluster -o jsonpath='{.status.serviceNetwork[0]}'
      ports:
        - protocol: TCP
          port: 443
```

Confirm whether BANP already allows API and DNS cluster-wide — if BANP denies, a namespace allow will not override it.
Namespace `NetworkPolicy` cannot set ANP priority; fix collisions at the cluster policy tier.

### Remediation direction

1. Assign **unique ANP priorities** (platform denies before allows; DNS/API allows before broad default-deny). Use BANP `default` separately for tier-3 guardrails if needed.
2. Ensure tenant namespaces can reach **DNS (5353)** and the **kubernetes Service on 443** — via platform baseline or namespace `serviceNetwork` CIDR rule, not a hardcoded Service VIP.
3. Keep namespace policies for **application traffic** (broker mesh, registry, metrics).
4. Re-test with a **same-label** debug pod or by watching one broker init — do not mass-delete.
5. If ACL audit shows denies during `ovnkube-node` restarts after policy is correct, treat Path B as concurrent.

---

## What not to do

- **Mass-delete Kafka broker pods** as the primary fix. That amplifies ISR / controller / downstream client pain.
- Prefer: fix missing API egress (Path C), stabilize API path (Path A), and/or node networking (Path B), then recover **one broker at a time**.
- Avoid chart upgrades or broker config churn until the fork above classifies the failure.

---

## Priority order (working recommendation)

1. **Classify** the init error (TCP vs post-connect).
2. **On a strict OVN-K / NetworkPolicy cluster, inventory Path C first** when TCP to the kubernetes Service fails — missing API/DNS egress and **duplicate ANP priorities** are common Helm/platform gaps.
3. **Path C — ANP priority** when failures are intermittent despite control-plane or API-looking rules; audit `spec.priority` on all ANPs.
4. **Path A** when apiserver shows webhook x509 (or similar) plus restarts — especially if TCP connects but API calls fail or time out.
5. **Path B** when the Service never connects despite correct policy tiering, especially if stuck pods sit on high-`ovnkube-node`-restart nodes.
6. Only after platform path is stable, revisit Confluent Helm init scripts if they still fail against a healthy kubernetes Service.

---

## Field capture checklist

Copy answers into the incident thread:

- [ ] Exact init container name and error line (one sample)
- [ ] `kubernetes` Service address and `endpoints/kubernetes` ready addresses
- [ ] NetworkPolicy / ANP / BANP — egress allow for DNS (**5353**) and kubernetes Service (**443**)?
- [ ] **Unique** `spec.priority` on each ANP (no duplicates in 0–99)
- [ ] Broker pod labels vs `podSelector` on those policies
- [ ] OVN ACL audit deny lines toward the kubernetes Service VIP (if logging enabled)
- [ ] Suspect webhook names, `failurePolicy`, `timeoutSeconds`
- [ ] Whether curl/`readyz` from a **same-label** pod fails at TCP or after connect
- [ ] Stuck broker node names vs `ovnkube-node` restart counts
- [ ] Timeline: first broker init failures vs policy changes, apiserver / OVN restart spikes
- [ ] Change window: can webhook cert/`caBundle` be fixed or hook temporarily bypassed?

---

## Open questions

- What is the suspect webhook’s `failurePolicy` (`Fail` or `Ignore`)?
- Do init failures correlate to specific worker nodes, or are they random?
- Do duplicate ANP priorities exist on the cluster?
- Does the platform baseline allow DNS and kubernetes Service **443**, or only control-plane **6443**?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
