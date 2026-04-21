# API Server Certificate Deadlock

## Overview

When the kube-apiserver is using a **bad serving certificate** (wrong CA, expired, wrong SANs, or key/cert mismatch), the cluster can enter a deadlock:

- Clients (including the kube-apiserver operator) cannot establish TLS to the API.
- The operator that would normally apply or rotate the certificate cannot reach the API to reconcile.
- The API keeps serving the bad cert, so the situation does not resolve itself.

This guide helps you **break the deadlock** and get the correct certificate applied.

## Symptoms

- `oc` / `kubectl` fail with TLS errors: `x509: certificate signed by unknown authority`, `certificate verify failed`, or `tls: handshake failure`.
- Web console and CLI both unreachable from outside the cluster.
- kube-apiserver operator may be degraded or unable to sync.
- API server logs may show: `tls: private key does not match public key` (if cert and key were replaced inconsistently).

## Prerequisites

- **SSH access** to at least one control plane node (required when API is unreachable from outside).
- The **correct certificate and private key** (PEM) that you want the API server to serve, or confirmation that you want the cluster to **re-issue** from the internal signer.

---

## Step 1: Get Access (Break the Deadlock)

If you cannot reach the API from your workstation, use a control plane node and the **localhost kubeconfig**, which talks to the local API server over `https://localhost:6443` and may still work when external clients fail (e.g. if only the external/LB cert is bad).

### From a control plane node

```bash
# SSH to a master
ssh core@<control-plane-ip>

# Use localhost kubeconfig (connects to https://localhost:6443)
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Verify you can reach the API
oc get nodes
oc get co kube-apiserver
```

If this works, you have API access from that node. Proceed to Step 2.

If **even localhost fails** (e.g. TLS handshake error), the serving cert used for localhost is also bad. Then you must fix the cert **on the node filesystem** and restart the API server static pods (see Step 4).

---

## Step 2: Identify the Failing Certificate

The kube-apiserver uses several serving cert secrets in `openshift-kube-apiserver`. Common names:

| Secret name | Purpose |
|-------------|--------|
| `localhost-serving-cert-certkey` | Localhost (e.g. 127.0.0.1, localhost) |
| `localhost-recovery-serving-certkey` | Recovery / fallback localhost |
| `service-network-serving-certkey` | Service network (internal cluster) |
| `external-loadbalancer-serving-certkey` | External LB / router |
| `internal-loadbalancer-serving-certkey` | Internal LB |

List and inspect:

```bash
oc get secrets -n openshift-kube-apiserver | grep -E "serving|cert"
oc get secret -n openshift-kube-apiserver localhost-serving-cert-certkey -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject -issuer -dates
```

Check operator status and recent events:

```bash
oc get co kube-apiserver -o yaml
oc get events -n openshift-kube-apiserver --sort-by='.lastTimestamp'
oc logs -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator --tail=100
```

---

## Step 3: Apply the New Cert When the API Is Reachable

If you got access via the localhost kubeconfig (Step 1), you can fix the cert via the API so the operator and static pods pick it up.

### Option A: You want the cluster to re-issue (internal signer)

Delete the bad secret so the operator regenerates it:

```bash
# Replace with the secret that is bad (e.g. localhost-serving-cert-certkey)
SECRET_NAME=localhost-serving-cert-certkey

oc delete secret -n openshift-kube-apiserver $SECRET_NAME
```

The kube-apiserver-operator will recreate the secret and sync it to the control plane nodes. Then **restart the kube-apiserver pods** so they load the new cert:

```bash
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
watch oc get pods -n openshift-kube-apiserver
```

Verify:

```bash
oc get co kube-apiserver
echo | openssl s_client -connect <api-host>:6443 -servername <api-host> 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

### Option B: You have your own cert and key (e.g. from Vault)

Create or replace the secret in `openshift-kube-apiserver` with type `kubernetes.io/tls`:

```bash
# Replace with your cert/key files and the correct secret name
SECRET_NAME=localhost-serving-cert-certkey  # or external-loadbalancer-serving-certkey, etc.

oc create secret tls $SECRET_NAME \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key \
  -n openshift-kube-apiserver \
  --dry-run=client -o yaml | oc apply -f -
```

Then **restart the kube-apiserver pods** so they mount the new secret:

```bash
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
watch oc get pods -n openshift-kube-apiserver
```

### Option C: Operator not reconciling (force operator to re-sync)

If the operator is running but not applying the new cert:

1. **Restart the kube-apiserver operator** so it re-syncs secrets to the nodes:

   ```bash
   oc delete pods -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator
   ```

2. Wait for the operator to become ready and for the target secret to be updated on the nodes (check secret resource version or timestamp).

3. **Restart the kube-apiserver pods** so they load the updated cert:

   ```bash
   oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
   ```

---

## Step 4: When the API Is Not Reachable at All (Manual Fix on Node)

If even `oc` with the localhost kubeconfig fails (TLS to localhost:6443 fails), you must update the cert **on the control plane node** and restart the static pods.

### 4.1 Locate certs on the node

Certs are under the static-pod resources. Paths are often one of:

- `/etc/kubernetes/static-pod-certs/secrets/<secret-name>/`
- `/etc/kubernetes/static-pod-resources/secrets/<secret-name>/`

Example:

```bash
sudo ls -la /etc/kubernetes/static-pod-certs/secrets/
# e.g. localhost-serving-cert-certkey, localhost-recovery-serving-certkey, ...
```

### 4.2 Replace cert and key on the node

Back up and replace the cert and key for the secret that is bad (e.g. `localhost-serving-cert-certkey`):

```bash
SECRET_DIR=/etc/kubernetes/static-pod-certs/secrets/localhost-serving-cert-certkey
sudo cp -a $SECRET_DIR $SECRET_DIR.bak.$(date +%Y%m%d%H%M%S)
# Copy your correct tls.crt and tls.key into $SECRET_DIR
sudo cp /path/to/your/tls.crt $SECRET_DIR/tls.crt
sudo cp /path/to/your/tls.key $SECRET_DIR/tls.key
sudo chown -R root:root $SECRET_DIR
sudo chmod 644 $SECRET_DIR/tls.crt
sudo chmod 600 $SECRET_DIR/tls.key
```

Repeat for any other cert you need to fix (e.g. `localhost-recovery-serving-certkey`).

### 4.3 Restart kube-apiserver static pods

The kubelet will restart the static pods and they will load the new files:

```bash
# Remove the static pod manifest so kubelet stops the pod (it will recreate from the source)
sudo rm /etc/kubernetes/manifests/kube-apiserver-pod.yaml
# Wait a few seconds, then restore so kubelet restarts with the new cert
# (Restore from backup or let the operator recreate it; if you only removed it, re-create from the same source the node uses.)

# Alternative: restart kubelet so it re-reads manifests and certs (more disruptive)
sudo systemctl restart kubelet
```

On OpenShift, the manifest is usually managed by the MCO/static pod installer. Safer approach: replace the cert files as above, then **delete the secret in the API** (if you can get temporary API access after fixing one node) so the operator re-syncs; or restart kubelet on that node so the existing static pod is restarted and picks up the new files.

If you have multiple masters, repeat the same cert replacement and restart on each control plane node that serves the API with that cert.

### 4.4 Verify

From the node (or after restoring API access):

```bash
curl -k https://localhost:6443/healthz
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes
```

---

## Step 5: User-Provided API Server Certificates (openshift-config)

If you are using **custom API server certificates** (not the cluster-internal ones), they are configured via `apiserver/cluster` and a secret in `openshift-config`:

1. Cert and key go into a `kubernetes.io/tls` secret in `openshift-config`.
2. `apiserver/cluster` must reference that secret (see [Configuring certificates](https://docs.openshift.com/container-platform/latest/security/certificates/api-server.html)).

If the operator "is not picking up the new cert":

- Ensure the secret in `openshift-config` has the correct `tls.crt` and `tls.key`.
- Ensure `oc get apiserver cluster -o yaml` shows the correct `spec.servingCerts` (or equivalent) reference.
- Restart the kube-apiserver operator so it re-syncs, then restart kube-apiserver pods:

  ```bash
  oc delete pods -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator
  oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
  ```

---

## Quick Reference: Order of Operations

| Situation | Action |
|-----------|--------|
| API reachable via localhost kubeconfig | Use Step 1 → 2 → 3 (delete secret or replace secret, then restart apiserver pods). |
| Operator not applying new cert | Restart kube-apiserver-operator, then restart kube-apiserver pods (Step 3 Option C). |
| API not reachable at all | Use Step 4: replace cert/key on node, restart static pods or kubelet. |
| Using custom cert in openshift-config | Update secret in `openshift-config`, check `apiserver/cluster`, restart operator and apiserver pods (Step 5). |

---

## Prevention

- Avoid replacing only the cert or only the key; always replace the pair together (cert + key) and ensure they match.
- When using custom API server certs, update the secret in `openshift-config` and let the operator propagate; avoid editing only on the node unless in a recovery scenario.
- Monitor certificate expiry and rotate before expiration; use the cluster’s rotation or your PKI (e.g. Vault) with a clear rotation procedure.

---

## See Also

- [Control plane kubeconfigs](../control-plane-kubeconfigs/README.md) – Using localhost kubeconfig on masters
- [API slowness / certificate issues](../api-slowness-web-console/README.md) – Certificate verification and force restart
- [CSR management](../csr-management/README.md) – Node and client certificate approval
- Red Hat: [Issue replacing Master API certificates in OpenShift 4](https://access.redhat.com/solutions/5991611) (subscription required)
- OpenShift docs: [Configuring certificates](https://docs.openshift.com/container-platform/latest/security/certificates/api-server.html)
