# OpenShift Internal Image Registry: Expose & Authenticate

## Symptom

Unable to authenticate to the OpenShift internal image registry using `podman login`.
Common errors:

- **403 Forbidden** — user is authenticated but lacks registry RBAC roles
- **401 Unauthorized** — token is invalid, expired, or malformed login command
- **x509 / TLS error** — registry route uses a self-signed or internal CA cert
- **connection refused / no route** — registry route has not been exposed

---

## Step 1: Expose the Registry (if not already done)

Enable the default external route on the registry operator:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster \
  --patch '{"spec":{"defaultRoute":true}}' \
  --type=merge
```

Wait for the route to appear (usually < 60 seconds):

```bash
oc get route default-route -n openshift-image-registry
```

Capture the hostname for use in subsequent commands:

```bash
REGISTRY=$(oc get route default-route -n openshift-image-registry \
  --template='{{ .spec.host }}')
echo $REGISTRY
```

---

## Step 2: Authenticate with podman

### Standard login (current user OAuth token)

```bash
podman login \
  -u $(oc whoami) \
  -p $(oc whoami -t) \
  --tls-verify=false \
  $REGISTRY
```

> `--tls-verify=false` bypasses certificate validation. See Step 4 for the
> proper CA trust solution.

### Login as a service account

> **Note:** `oc sa get-token` was deprecated in OpenShift 4.11 (Kubernetes 1.24)
> and removed in later releases. Use the Secret-based approach below instead.

**Option A: Long-lived token Secret (OCP 4.15 and earlier)**

Create a Secret bound to the service account:

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: <service-account-name>-token
  namespace: <namespace>
  annotations:
    kubernetes.io/service-account.name: <service-account-name>
```

```bash
oc apply -f sa-token-secret.yaml
```

> **OCP 4.16+ / Kubernetes 1.29+:** The `LegacyServiceAccountTokenCleanUp`
> feature gate is enabled by default and will **immediately garbage-collect**
> any `kubernetes.io/service-account-token` Secret not referenced by the
> service account object or a running pod. You must link the Secret to the SA
> right after creating it, or it will be deleted:
>
> ```bash
> oc secrets link <service-account-name> <service-account-name>-token -n <namespace>
> ```

Retrieve the token and login:

```bash
SA_TOKEN=$(oc get secret <service-account-name>-token -n <namespace> \
  -o jsonpath='{.data.token}' | base64 -d)

podman login \
  -u serviceaccount \
  -p $SA_TOKEN \
  --tls-verify=false \
  $REGISTRY
```

**Option B: Short-lived token via TokenRequest API (recommended for OCP 4.16+)**

Avoid managing Secrets entirely — request a bound token directly:

```bash
SA_TOKEN=$(oc create token <service-account-name> -n <namespace>)

podman login \
  -u serviceaccount \
  -p $SA_TOKEN \
  --tls-verify=false \
  $REGISTRY
```

> Tokens issued by `oc create token` expire (default 1 hour; override with
> `--duration`, e.g. `--duration=24h`). They are not stored as Secrets and
> cannot be garbage-collected.

**Option C: GitOps / declarative-only (no imperative commands)**

Declare both the ServiceAccount and the Secret together, with the SA's
`.secrets[]` field pre-referencing the Secret by name. The cleanup controller
will not garbage-collect a Secret that appears in the SA's secrets list.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <service-account-name>
  namespace: <namespace>
  annotations:
    argocd.argoproj.io/sync-wave: "0"   # SA must exist before Secret is created
secrets:
- name: <service-account-name>-token
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: <service-account-name>-token
  namespace: <namespace>
  annotations:
    kubernetes.io/service-account.name: <service-account-name>
    argocd.argoproj.io/sync-wave: "1"   # Secret applied after SA
```

The token value is **never stored in Git** — the API server's token controller
auto-populates `secret.data.token` after the Secret is created. Downstream
resources reference it by name:

```yaml
env:
- name: REGISTRY_TOKEN
  valueFrom:
    secretKeyRef:
      name: <service-account-name>-token
      key: token
```

> **Sync wave ordering is important.** The SA (wave 0) must be fully synced
> before the Secret (wave 1) is created. If the Secret lands first and the SA
> does not yet reference it, the cleanup controller can delete it before the
> SA sync completes.

---

## Step 3: Fix 403 Forbidden (RBAC)

A 403 means OpenShift validated your token but the user has no role granting
registry access. Grant the appropriate role:

### Pull access (registry-viewer)

```bash
# Grant pull access for your user in a specific namespace
oc policy add-role-to-user registry-viewer $(oc whoami) -n <namespace>

# Or grant cluster-wide pull access
oc adm policy add-cluster-role-to-user registry-viewer $(oc whoami)
```

### Push + pull access (registry-editor)

```bash
# Grant push/pull access for your user in a specific namespace
oc policy add-role-to-user registry-editor $(oc whoami) -n <namespace>
```

### Full registry admin (cluster-admin or registry-admin)

```bash
oc adm policy add-cluster-role-to-user registry-admin $(oc whoami)
```

### Verify assigned roles

```bash
# Check roles in a specific namespace
oc get rolebindings -n <namespace> | grep $(oc whoami)

# Check cluster-level roles
oc get clusterrolebindings | grep $(oc whoami)
```

After granting the role, **login again** — tokens cache the role snapshot at
issue time. A fresh token picks up the new roles:

```bash
oc login  # re-authenticate to get a new token
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $REGISTRY
```

---

## Step 4: Fix x509 / TLS Certificate Errors

The default registry route uses the cluster ingress wildcard certificate. If
your cluster uses a private CA (common in air-gapped or on-prem installs), you
must trust that CA.

### Option A: Skip verification (testing only)

```bash
podman login --tls-verify=false -u $(oc whoami) -p $(oc whoami -t) $REGISTRY
```

### Option B: Trust the cluster CA (recommended)

```bash
# Extract the ingress CA certificate
oc extract secret/router-ca -n openshift-ingress-operator --to=.

# Copy to system trust store (Fedora/RHEL)
sudo cp tls.crt /etc/pki/ca-trust/source/anchors/${REGISTRY}.crt
sudo update-ca-trust

# Verify
podman login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY
```

### Option C: Configure Docker / Podman to trust specific registry

```bash
# Create directory for the registry cert
sudo mkdir -p /etc/docker/certs.d/${REGISTRY}
sudo cp tls.crt /etc/docker/certs.d/${REGISTRY}/ca.crt
```

---

## Step 5: Fix 401 Unauthorized

A 401 means the credentials themselves failed. Check:

### Token is expired

OAuth tokens expire (default 24 hours). Re-authenticate:

```bash
oc login
oc whoami -t   # confirm you have a new token
```

### Username format

The username passed to `podman login` must match exactly what `oc whoami`
returns. Avoid hardcoding:

```bash
# Correct
podman login -u $(oc whoami) -p $(oc whoami -t) $REGISTRY

# Wrong — username mismatch causes 401
podman login -u admin -p $(oc whoami -t) $REGISTRY
```

---

## Step 6: Verify End-to-End

After a successful login, test push and pull:

```bash
# Tag a local image for the registry
podman tag myimage:latest ${REGISTRY}/<namespace>/myimage:latest

# Push
podman push ${REGISTRY}/<namespace>/myimage:latest

# Verify image stream was created
oc get imagestream -n <namespace>

# Pull
podman pull ${REGISTRY}/<namespace>/myimage:latest
```

---

## Quick Diagnostic Reference

| Error | Cause | Fix |
|-------|-------|-----|
| 403 Forbidden | Missing RBAC role | Grant `registry-viewer` / `registry-editor` |
| 401 Unauthorized | Invalid/expired token or wrong username | Re-authenticate with `oc login`, use `$(oc whoami)` |
| x509 certificate | Untrusted CA | Trust ingress CA or use `--tls-verify=false` |
| connection refused | Route not exposed | `oc patch configs.imageregistry...defaultRoute:true` |
| ImagePullBackOff (in-cluster) | SA missing `system:image-puller` | `oc policy add-role-to-user system:image-puller system:serviceaccount:<ns>:default -n <image-ns>` |

---

## Related Resources

- [OpenShift Docs: Exposing the Registry](https://docs.openshift.com/container-platform/latest/registry/securing-exposing-registry.html)
- [OpenShift Docs: Registry Authentication](https://docs.openshift.com/container-platform/latest/registry/accessing-the-registry.html)

---

*AI-assisted content — reviewed for accuracy against OpenShift 4.x behavior.*
