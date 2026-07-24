---
review:
  status: unreviewed
  notes: "Working triage for Kafka/Confluent init stuck on kubernetes.default — NetworkPolicy, webhook, and OVN paths. Commands need field validation."
---

# Kafka Broker Stuck in Init — Cannot Reach `kubernetes` Service

> **Audience:** Platform engineers troubleshooting Confluent (classic Helm) or other Kafka brokers on OpenShift when init containers cannot reach the in-cluster API.
>
> **Purpose:** Split “cannot contact `kubernetes.default`” into webhook/API vs OVN vs NetworkPolicy paths, capture field signals, and avoid broker-delete cascades.

**Working status:** Hypothesis and triage order only — not a confirmed root cause.

**Related:**

- [API Slowness and Web Console Performance](../api-slowness-web-console/README.md) — API latency, webhook timeouts
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) — node/OVN network diagnostics
- [Debug Toolbox Container](../debug-toolbox-container/README.md) — probe from a pod on the same node
- [Kafka on OpenShift tenancy](../../notes/kafka-on-openshift-tenancy.md) — broker flap / PDB / upgrade coupling
- [Network policy and observability](../../notes/network-policy-observability.md) — default-deny, DNS/API egress, OVN ACL audit

---

## Symptom

Kafka broker pods (classic Confluent Helm install observed) stick in **Init**.
Init logs indicate failure to contact the **ClusterIP of the `kubernetes` Service in `default`** (in-cluster kube-apiserver VIP — first address in `serviceNetwork`, often `172.30.0.1` on OpenShift defaults).

Operators delete stuck pods to recover.
That can cascade: more brokers leave ISR / go offline under recovery load.

### Signals that often co-occur

| Signal | What it suggests |
|--------|------------------|
| Strict OVN-K + default-deny NetworkPolicy / BANP | **Path C** — classic Helm does not auto-allow kube-apiserver egress |
| Apiserver logs show failed admission webhook calls (often **x509** / TLS trust) and elevated `kube-apiserver` restart counts | **Path A** — API-path / webhook stress |
| Elevated `ovnkube-node` restart counts; TCP to the Service IP fails | **Path B** — ClusterIP / OVN path |

None of these alone proves the broker init failure.
Use the fork below before picking a remediation.

**Consistency hint:** Missing API egress in NetworkPolicy is often **consistent** for every pod matching the selector.
“Occasional” plus delete-pod-to-fix fits Path B (OVN flap) or Path A (API/webhook load) better — unless policies/labels are uneven, BANP and namespace policies disagree, or OVN ACL programming lags during `ovnkube-node` restarts (Path B + C together).

---

## What `kubernetes.default` is

The `kubernetes` Service in `default` is the ClusterIP front door to the kube-apiserver for in-cluster clients.
Broker init containers that need the API (SA token, labels, peer discovery, wait logic) talk to `$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT`.

This is usually **not** a Confluent chart bug once the failure is “cannot reach that IP.”

---

## Severity

**HIGH** for Kafka availability.

Intermittent API or pod-network reachability plus “delete pod to fix” turns a platform issue into a broker churn incident.

---

## Triage fork (do this first)

Capture the **exact** init failure class:

| Failure class | Likely path | Lead with |
|---------------|-------------|-----------|
| TCP timeout / no route to the **Service IP**, on a **default-deny** cluster | Missing/incorrect egress policy | Path C (check before or with Path B) |
| TCP timeout / connection refused / no route, **without** policy deny evidence | OVN / node networking | Path B |
| TCP connects, then TLS, HTTP 5xx, timeout, or admission denial | Apiserver / webhook | Path A |
| Ambiguous or mixed | Multiple | Path C inventory + Path A/B correlation |

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

# Control plane / network operators
oc get co kube-apiserver network
oc get pods -n openshift-kube-apiserver -o wide
oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide
```

From a **debug pod on the same node** as a stuck broker (see [debug toolbox](../debug-toolbox-container/README.md)):

```bash
# Substitute ClusterIP/port from the kafka pod env if needed
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

If TCP to the kubernetes ClusterIP fails from the broker node while apiserver endpoints are healthy elsewhere, treat as an OVN / node networking incident (support case material).
Do not attribute it to the Helm chart.

### Related guide

[CoreOS Networking Issues](../coreos-networking-issues/README.md).

---

## Path C — Missing egress to kube-apiserver (strict NetworkPolicy)

### Why it fits

Once a pod is selected by any `NetworkPolicy`, it is **isolated**: only explicitly allowed egress works.
Under default-deny / BANP baselines, brokers need an allow for:

| Destination | Typical allow | Why brokers/init need it |
|-------------|---------------|--------------------------|
| `openshift-dns` | UDP/TCP **5353** | Resolve names (including `kubernetes.default`) |
| kube-apiserver via `kubernetes.default` ClusterIP | TCP **443** (Service port; host may be 6443 on endpoints) | Init / operator / in-cluster clients |

Classic **Confluent Helm** does not generate NetworkPolicies.
Strimzi often does for listeners; CFK still expects you to author policies by hand.
It is easy to allow broker↔broker and DNS and still **omit API egress** — then init fails contacting the `kubernetes` Service IP.

See [Network policy and observability](../../notes/network-policy-observability.md) (DNS gotcha, CFK manual policies, OVN ACL audit).

### Checks

```bash
# Namespace and cluster-scoped policy inventory
oc get networkpolicy -n <kafka-ns>
oc get adminnetworkpolicy,baselineadminnetworkpolicy

# Do policies select the broker pods? Compare labels.
oc get pods -n <kafka-ns> --show-labels | head
oc get networkpolicy -n <kafka-ns> -o yaml | grep -E 'podSelector|namespaceSelector|policyTypes|ports:|ipBlock'

# Look for egress to DNS (5353) and to API (443) or to the kubernetes Service / apiserver CIDR
oc get networkpolicy -n <kafka-ns> -o json | jq '
  .items[] | {
    name: .metadata.name,
    types: .spec.policyTypes,
    egress: .spec.egress
  }'

# OVN ACL audit (if enabled) — deny verdicts toward the kubernetes ClusterIP
# Annotate ns: k8s.ovn.org/acl-logging: '{ "deny": "alert", "allow": "notice" }'
```

**What “good enough” egress looks like (shape only — adapt labels/CIDRs):**

```yaml
# Illustrative — confirm labels and ports on your cluster before apply
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-broker-to-kube-apiserver
  namespace: <kafka-ns>
spec:
  podSelector:
    matchLabels:
      # must match broker / init pods
      app: <broker-label>
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector: {}
          podSelector: {}
      # Prefer tighter: allow only the kubernetes Service IP or control-plane CIDR
      ports:
        - protocol: TCP
          port: 443
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: openshift-dns
      ports:
        - protocol: UDP
          port: 5353
        - protocol: TCP
          port: 5353
```

Prefer allowing the **`kubernetes` Service ClusterIP** (or documented control-plane CIDR) over wide-open egress.
Confirm whether BANP already allows API and DNS cluster-wide — if BANP denies, a namespace allow will not override it.

### Remediation direction

1. Add/fix egress so broker (and init) pods can reach DNS and `kubernetes.default:443`.
2. Re-test with a **same-label** debug pod or by watching one broker init — do not mass-delete.
3. If ACL audit shows denies during `ovnkube-node` restarts, fix policy **and** treat Path B as concurrent.

---

## What not to do

- **Mass-delete Kafka broker pods** as the primary fix. That amplifies ISR / controller / downstream client pain.
- Prefer: fix missing API egress (Path C), stabilize API path (Path A), and/or node networking (Path B), then recover **one broker at a time**.
- Avoid chart upgrades or broker config churn until the fork above classifies the failure.

---

## Priority order (working recommendation)

1. **Classify** the init error (TCP vs post-connect).
2. **On a strict OVN-K / NetworkPolicy cluster, inventory Path C first** when TCP to the kubernetes ClusterIP fails — missing API egress is a common Helm gap and is cheap to verify.
3. **Path A** when apiserver shows webhook x509 (or similar) plus restarts — especially if TCP connects but API calls fail or time out.
4. **Path B** when ClusterIP never connects despite policies that clearly allow API/DNS, especially if stuck pods sit on high-`ovnkube-node`-restart nodes.
5. Only after platform path is stable, revisit Confluent Helm init scripts if they still fail against a healthy `kubernetes.default`.

---

## Field capture checklist

Copy answers into the incident thread:

- [ ] Exact init container name and error line (one sample)
- [ ] `kubernetes` Service ClusterIP and `endpoints/kubernetes` ready addresses
- [ ] NetworkPolicy / ANP / BANP in the Kafka namespace — egress allow for DNS **and** API (443)?
- [ ] Broker pod labels vs `podSelector` on those policies
- [ ] OVN ACL audit deny lines toward the kubernetes ClusterIP (if logging enabled)
- [ ] Suspect webhook names, `failurePolicy`, `timeoutSeconds`
- [ ] Whether curl/`readyz` from a **same-label** pod fails at TCP or after connect
- [ ] Stuck broker node names vs `ovnkube-node` restart counts
- [ ] Timeline: first broker init failures vs policy changes, apiserver / OVN restart spikes
- [ ] Change window: can webhook cert/`caBundle` be fixed or hook temporarily bypassed?

---

## Open questions

- What is the suspect webhook’s `failurePolicy` (`Fail` or `Ignore`)?
- Do init failures correlate to specific worker nodes, or are they random?
- Do broker NetworkPolicies (or BANP) allow egress to DNS **and** to the kube-apiserver / `kubernetes` Service?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
