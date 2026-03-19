# Troubleshooting: OAuth Server healthz Unavailable (Authentication CO Degraded)

## Overview

The authentication cluster operator reports **OAuthServerRouteEndpointAccessibleControllerAvailable** with the OAuth server's `/healthz` endpoint unavailable. The controller runs inside the authentication operator and periodically checks that it can reach the OAuth route; when that check fails, the authentication CO degrades and login (web console, `oc login`) can be affected.

## Severity

**HIGH** — Cluster login and web console depend on the OAuth server. The condition indicates the authentication operator cannot reach the OAuth route's healthz endpoint.

## Symptoms

- Authentication cluster operator degraded:
  - Condition: `OAuthServerRouteEndpointAccessibleControllerAvailable` — **Available=False**
  - Message often includes: `Get https://oauth-openshift.apps.<domain>/healthz: ...` with errors such as:
    - `connection refused`
    - `context deadline exceeded (Client.Timeout exceeded while awaiting headers)`
    - `no such host` (DNS)
- Web console login may fail or be slow.
- `oc login` may fail or hang.

## Emergency Quick Checks — Run This First

```bash
# 1. Confirm the failing condition
oc get co authentication -o yaml | grep -A 20 OAuthServerRouteEndpointAccessibleControllerAvailable

# 2. Get the OAuth route hostname and test from your machine
OAUTH_HOST=$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')
echo "OAuth route: https://$OAUTH_HOST/healthz"
curl -vvk --connect-timeout 10 "https://$OAUTH_HOST/healthz"

# 3. OAuth and authentication pods
oc get pods -n openshift-authentication
oc get pods -n openshift-oauth-apiserver
oc get route -n openshift-authentication

# 4. Authentication operator logs (look for healthz/route errors)
oc logs -n openshift-authentication-operator -l name=authentication-operator --tail=100 | grep -i -E "healthz|oauth|route|refused|timeout|dial"
```

**What to look for:**

- **Connection refused** → Firewall or load balancer blocking traffic to the OAuth route (most common).
- **Timeout** → Network path or LB not forwarding to the correct backends.
- **no such host** → DNS resolution failure from the nodes or operator.

---

## Quick Diagnosis

### 1. Get the Exact Error from the Authentication Operator

```bash
oc get co authentication -o jsonpath='{range .status.conditions[?(@.type=="Degraded")]}{.message}{"\n"}{end}'
oc get co authentication -o yaml
```

Note the URL in the message (e.g. `https://oauth-openshift.apps.<your-domain>/healthz`) and the error (refused, timeout, no such host).

### 2. Test healthz From Outside the Cluster

```bash
OAUTH_HOST=$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')
curl -vvk --connect-timeout 10 "https://$OAUTH_HOST/healthz"
# Expected: HTTP 200 and "ok" or similar
```

### 3. Test From Inside the Cluster (Same Perspective as the Operator)

The authentication operator runs on control plane nodes and reaches the OAuth route via the ingress/LB. Test from a pod that uses cluster DNS and network:

```bash
# From a debug pod on a master (or any node that should reach ingress)
oc run curl-oauth-test --image=registry.access.redhat.com/ubi9/ubi-minimal:latest --rm -it --restart=Never -- \
  curl -vvk --connect-timeout 10 "https://$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')/healthz"
```

Or from a node (if you have SSH or debug access):

```bash
oc debug node/<master-node> -- chroot /host curl -vvk --connect-timeout 10 "https://<oauth-route-host>/healthz"
```

### 4. Verify OAuth and Ingress Components

```bash
# OAuth server pods (should be Running)
oc get pods -n openshift-authentication -l app=oauth-openshift
oc get pods -n openshift-oauth-apiserver

# Ingress (route is served via default ingress)
oc get pods -n openshift-ingress
oc get route oauth-openshift -n openshift-authentication -o wide
oc get svc -n openshift-ingress
```

### 5. Check Authentication Operator Logs

```bash
oc logs -n openshift-authentication-operator -l name=authentication-operator --tail=200
# Search for the healthz URL and the error (refused, timeout, no such host)
```

---

## Common Root Causes

### 1. Firewall / Load Balancer Blocking (Most Common)

**Symptom:** `connection refused` or `dial tcp ... connect: connection refused`.

**Cause:** The path from the authentication operator (running on masters) to the OAuth route goes through the ingress load balancer. If a firewall or LB rule blocks traffic from the master nodes (or from the network segment where the operator runs) to the ingress VIP/LB on port 443, the healthz check fails.

**What to do:**

- Verify firewall rules allow traffic **from** control plane nodes **to** the load balancer / ingress VIP on port 443 (and 80 if redirects are used).
- On the load balancer, ensure the backend pool for the `*.apps.<domain>` (or the OAuth host) includes the ingress router pods; ensure health checks and forwarding are correct.
- If you use NetworkPolicy, ensure the `openshift-authentication-operator` namespace (or the network segment of the operator) can reach the ingress namespace / service.

### 2. DNS Resolution Failure

**Symptom:** `no such host` or `lookup oauth-openshift.apps.... on ...:53: no such host`.

**Cause:** The authentication operator (or nodes) cannot resolve the OAuth route hostname.

**What to do:**

- From a master node or a pod, test: `nslookup <oauth-route-host>` or `getent hosts <oauth-route-host>`.
- Verify cluster DNS (CoreDNS) is healthy: `oc get pods -n openshift-dns` and `oc get dns cluster -o yaml`.
- Verify node DNS config (e.g. `/etc/resolv.conf`) and that external or internal DNS used for `*.apps.<domain>` is reachable and returns the correct IP for the OAuth host.

### 3. Timeout (No Response)

**Symptom:** `context deadline exceeded` or `Client.Timeout exceeded while awaiting headers`.

**Cause:** Packets are allowed but the request never completes (LB not forwarding, backend down, or network congestion).

**What to do:**

- Confirm ingress router pods are Running and endpoints exist: `oc get endpoints -n openshift-ingress`.
- Check LB backend pool and health checks; ensure backends are healthy and the LB forwards to the router service.
- Increase timeout only as a temporary workaround; fix the underlying connectivity or backend availability.

### 4. OAuth or Ingress Pods Unhealthy

**Symptom:** Route exists but backends are not ready or OAuth pods are crash-looping.

**What to do:**

```bash
oc get pods -n openshift-authentication
oc get pods -n openshift-ingress
oc logs -n openshift-authentication -l app=oauth-openshift --tail=100
oc describe route oauth-openshift -n openshift-authentication
```

Fix any crash loops, image pull, or readiness issues first; then re-check healthz.

---

## Resolution Checklist

1. **Identify the error** — From `oc get co authentication -o yaml` and operator logs, note: refused, timeout, or no such host.
2. **Test healthz** — From your machine and from inside the cluster (e.g. `oc run ... curl ... https://<oauth-host>/healthz`).
3. **If connection refused:**
   - Allow traffic from control plane nodes to the ingress LB/VIP on 443 (and 80 if needed).
   - Verify LB backends and forwarding for the OAuth hostname.
4. **If no such host:**
   - Fix DNS for the OAuth route host (cluster DNS and/or node resolv.conf).
5. **If timeout:**
   - Fix LB backends and health checks; ensure ingress and OAuth pods are Running and ready.
6. **Re-check:** Wait 1–2 minutes, then:
   - `curl -vk https://<oauth-route-host>/healthz`
   - `oc get co authentication`

---

## Verification

```bash
# Condition should become Available=True
oc get co authentication

# Optional: watch until degraded clears
watch -n 5 'oc get co authentication -o jsonpath="{.status.conditions[?(@.type==\"Degraded\")].status} {.status.conditions[?(@.type==\"Degraded\")].message}"'
```

---

## Data Collection for Support

If opening a Red Hat support case:

```bash
oc adm must-gather
# Include authentication and ingress namespaces
oc get co authentication -o yaml > authentication-co.yaml
oc get route oauth-openshift -n openshift-authentication -o yaml > oauth-route.yaml
oc logs -n openshift-authentication-operator -l name=authentication-operator --tail=500 > auth-operator.log
```

---

## References

- [Red Hat Solution 7000864](https://access.redhat.com/solutions/7000864) — Authentication CO degraded with OAuthServerRouteEndpointAccessibleControllerAvailable (healthz connection refused; firewall/LB).
- [api-slowness-web-console](../api-slowness-web-console/README.md) — General API/console/OAuth checks.
