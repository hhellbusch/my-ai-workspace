---
review:
  status: unreviewed
  notes: "AI-generated 2026-06-25. Hub CIM / AgentServiceConfig prerequisites sourced from ACM Clusters docs and OCP Assisted Installer documentation. Corporate proxy section added 2026-06-25 from production troubleshooting (cluster proxy vs assisted-pod env gap). Not yet validated against a live hub in this environment."
---

# ACM Hub CIM Setup — Enable On-Prem Cluster Provisioning

A working reference for enabling **Central Infrastructure Management (CIM)** on an ACM hub so you can **provision** new OpenShift clusters on bare metal (or agent-based installs, including nested OCP VMs) via the Assisted Installer.

**Audience:** Platform engineers standing up or auditing a bare-metal ACM hub.

**Not covered here:** Importing an already-installed cluster into ACM — that path does not require `AgentServiceConfig`. See [cluster-import-ansible](../examples/cluster-import-ansible/README.md) and [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](../examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md).

**Downstream workflow:** Once CIM is healthy, see [BARE-METAL-OPERATOR-INTEGRATION.md](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) for `InfraEnv`, discovery ISO, and install CRs.
For pre-install validation and gating, see [agent-install-preflight.md](./agent-install-preflight.md).

---

## Import vs provision

| Goal | Need CIM / `AgentServiceConfig`? |
|------|----------------------------------|
| Import existing OCP into ACM | No |
| ACM provisions new cluster (discovery ISO → install) | **Yes** |

If `oc get agentserviceconfig` returns nothing and you are trying to create `InfraEnv` / `AgentClusterInstall` CRs, fix this **before** debugging cluster-level manifests.

---

## What CIM is

ACM uses different provisioning backends by platform:

| Target | Engine | Hub prerequisite |
|--------|--------|------------------|
| Cloud (AWS, Azure, GCP, vSphere IPI, …) | Hive | Standard MCE — no `AgentServiceConfig` |
| On-prem bare metal / agent install | **CIM + Assisted Installer** | **`AgentServiceConfig` required** |
| Hosted control planes | HyperShift | Separate HyperShift setup |

**CIM** ships with **Multicluster Engine (MCE)** when ACM is installed. MCE deploys `assisted-service` and `assisted-image-service` pods in `multicluster-engine`, but those services need **`AgentServiceConfig`** to allocate storage and (in disconnected environments) declare install image URLs.

`AgentServiceConfig` tells the Assisted Installer:

- **databaseStorage** — cluster metadata DB
- **filesystemStorage** — logs, manifests, kubeconfigs
- **imageStorage** — RHCOS / discovery ISO cache
- **osImages** / **mirrorRegistryRef** — install media catalog (disconnected)

---

## Quick audit

Run on the **hub cluster**:

```bash
# 1. MCE healthy?
oc get mce multiclusterengine -n multicluster-engine

# 2. AgentServiceConfig present?
oc get agentserviceconfig

# 3. Assisted installer pods
oc get pods -n multicluster-engine | grep -E 'assisted-service|assisted-image'

# 4. PVCs bound for assisted installer
oc get pvc -n multicluster-engine | grep -i assisted

# 5. Provisioning CR (required on on-prem hubs)
oc get provisioning provisioning-configuration -o yaml

# 6. Routes for install targets to reach
oc get routes -A | grep assisted

# 7. Corporate proxy — cluster object vs assisted pods (see Corporate proxy section)
oc get proxy cluster -o jsonpath='http={.status.httpProxy}{"\n"}https={.status.httpsProxy}{"\n"}'
oc set env pod -n multicluster-engine -l app=assisted-image-service --list 2>/dev/null | grep -i proxy || true
```

**Healthy baseline:**

- `agentserviceconfig/agent` exists
- `assisted-service` and `assisted-image-service` deployments are **Available**
- Assisted PVCs are **Bound**
- `provisioning-configuration` has `spec.watchAllNamespaces: true` (on-prem hub platforms)

---

## Prerequisites

- ACM / MCE installed and `MultiClusterHub` phase **Running**
- Cluster-admin (or equivalent) on the hub
- A **default StorageClass** supporting `ReadWriteOnce` PVCs in `multicluster-engine`
- **Connected:** outbound access to Red Hat / mirror image sources (or pre-populated `osImages`)
- **Corporate proxy:** cluster `Proxy` object configured — see [Corporate proxy](#corporate-proxy) (cluster proxy alone is not sufficient for Assisted Installer pods)
- **Disconnected / mirror-only:** mirror registry, `ConfigMap` for `assisted-service`, and `osImages` URLs — see [Mirror configuration](#mirror-configuration)

---

## 1. Provisioning CR (on-prem hubs only)

Required when the hub runs on **bare metal**, **vSphere UPI**, **OpenStack**, or platform **`None`**. Skip if the hub is on AWS, Azure, GCP, or vSphere IPI.

Patch an existing CR:

```bash
oc patch provisioning provisioning-configuration \
  --type merge -p '{"spec":{"watchAllNamespaces": true}}'
```

If the CR does not exist, create it:

```yaml
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  provisioningNetwork: Disabled
  watchAllNamespaces: true
```

`provisioningNetwork: Disabled` is normal when you are enabling CIM for Assisted Installer workflows — not standing up a Metal³ provisioning network on the hub itself.

Verify:

```bash
oc get provisioning provisioning-configuration \
  -o jsonpath='watchAllNamespaces={.spec.watchAllNamespaces}{"\n"}'
```

---

## 2. AgentServiceConfig (connected)

Replace storage sizes for your expected cluster count. Red Hat minimums: `filesystemStorage` ≥ 100Gi, `imageStorage` ≥ 50Gi for lab-scale use.

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
spec:
  databaseStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
  filesystemStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 100Gi
  imageStorage:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 50Gi
```

Apply:

```bash
oc apply -f agent-service-config.yaml
```

Verify:

```bash
oc get agentserviceconfig agent -o yaml
oc get deploy -n multicluster-engine | grep assisted
oc wait -n multicluster-engine deployment/assisted-service --for=condition=Available --timeout=300s
oc rollout status -n multicluster-engine statefulset/assisted-image-service --timeout=300s
```

In restricted networks, complete [Corporate proxy](#corporate-proxy) or [Mirror configuration](#mirror-configuration) before expecting ISO downloads to succeed.

---

## Restricted network: choose a strategy

Many enterprise hubs are neither fully connected nor fully air-gapped. Pick one primary path for **hub-side** RHCOS ISO/rootfs downloads:

| Environment | Hub pulls install media from | Typical setup |
|-------------|------------------------------|---------------|
| Open internet | `mirror.openshift.com` (default) | Connected `AgentServiceConfig` only |
| Internet via corporate proxy | `mirror.openshift.com` through proxy | Cluster `Proxy` **plus** proxy env on assisted pods |
| Internal mirror only | Your mirror HTTP server / registry | `spec.osImages` + `mirrorRegistryRef` — no public internet |

**Two separate proxy layers** — do not conflate them:

| Layer | Configured via | Affects |
|-------|----------------|---------|
| **Hub** assisted pods | `assisted-service` ConfigMap, `assisted-image-service` StatefulSet env, or custom ConfigMap annotation | Hub downloading/caching RHCOS ISO and rootfs |
| **Install targets** (agents/nodes) | `InfraEnv.spec.proxy` or cluster install proxy | Discovery agents and nodes during install |

Fixing hub proxy does not configure install-target proxy, and vice versa.

---

## Corporate proxy

### Cluster proxy does not reach assisted pods automatically

The hub cluster-wide `Proxy` object (`config.openshift.io/v1`) configures OpenShift platform behavior. **Assisted Installer pods do not inherit it automatically.**

The infrastructure operator copies `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` into assisted components from **its own environment at reconcile time** — not by reading `proxy/cluster` directly. Symptom: `oc get proxy cluster` shows values, but `assisted-image-service` still fails reaching `mirror.openshift.com`.

The pod that downloads RHCOS images is **`assisted-image-service`** (StatefulSet). Check it first.

### Diagnose

```bash
# Cluster proxy configured?
oc get proxy cluster -o yaml

# Do assisted pods actually have proxy env?
oc set env pod -n multicluster-engine -l app=assisted-image-service --list
oc set env pod -n multicluster-engine -l app=assisted-service --list

# ConfigMap the service reads
oc get cm assisted-service -n multicluster-engine -o yaml | grep -i proxy

# Test egress from the image service pod
AIS_POD=$(oc get pod -n multicluster-engine -l app=assisted-image-service -o jsonpath='{.items[0].metadata.name}')
oc exec -n multicluster-engine "$AIS_POD" -- \
  curl -sS -o /dev/null -w '%{http_code}\n' --connect-timeout 10 \
  https://mirror.openshift.com/ || echo "failed"
```

If curl fails without proxy but succeeds when you pass `HTTPS_PROXY` manually in `oc exec`, the fix is pod-level proxy injection.

### Inject proxy into Assisted Installer pods

Read values from the cluster proxy **status** (resolved form), then push them to assisted components:

```bash
HTTP_PROXY=$(oc get proxy cluster -o jsonpath='{.status.httpProxy}')
HTTPS_PROXY=$(oc get proxy cluster -o jsonpath='{.status.httpsProxy}')
NO_PROXY=$(oc get proxy cluster -o jsonpath='{.status.noProxy}')

# assisted-service deployment reads this ConfigMap
oc patch cm assisted-service -n multicluster-engine --type merge -p "{
  \"data\": {
    \"HTTP_PROXY\": \"${HTTP_PROXY}\",
    \"HTTPS_PROXY\": \"${HTTPS_PROXY}\",
    \"NO_PROXY\": \"${NO_PROXY}\"
  }
}"

# assisted-image-service needs StatefulSet env explicitly
oc set env statefulset/assisted-image-service -n multicluster-engine \
  HTTP_PROXY="$HTTP_PROXY" \
  HTTPS_PROXY="$HTTPS_PROXY" \
  NO_PROXY="$NO_PROXY"

oc rollout restart statefulset/assisted-image-service -n multicluster-engine
oc rollout restart deployment/assisted-service -n multicluster-engine
```

Re-verify pod env and curl after rollout.

### Durable override via ConfigMap annotation

For a maintained config, annotate `AgentServiceConfig` and manage a dedicated ConfigMap. The operator merges it into the `assisted-service` deployment; you must restart `assisted-service` after changes. You still need the **image service StatefulSet** env (above) unless the operator is reconciled with proxy in its own environment.

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
  annotations:
    unsupported.agent-install.openshift.io/assisted-service-configmap: assisted-service-config
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-service-config
  namespace: multicluster-engine
data:
  HTTP_PROXY: "http://proxy.example.com:8080"
  HTTPS_PROXY: "http://proxy.example.com:8080"
  NO_PROXY: ".cluster.local,.svc,10.0.0.0/8,192.168.0.0/16"
```

### Proxy CA (TLS inspection)

If the corporate proxy performs TLS inspection, set `spec.trustedCA` on `proxy/cluster` to a ConfigMap in `openshift-config` containing the proxy's CA. Assisted pods should mount the cluster trusted CA bundle; without it, HTTPS through the proxy fails with certificate errors even when proxy env vars are correct.

```bash
oc get proxy cluster -o jsonpath='trustedCA={.spec.trustedCA.name}{"\n"}'
# Verify the referenced ConfigMap exists in openshift-config
```

### Proxy gotchas

- **`httpsProxy` URL scheme:** Use `http://proxy-host:port` for the proxy listener in most environments. A `https://` proxy URL when the proxy only speaks HTTP on that port surfaces as a generic connection failure.
- **`NO_PROXY`:** Include cluster service CIDRs, hub ingress domains, internal mirror hostnames, and BMC ranges. OCP populates defaults in `proxy/cluster` status — extend rather than replace when patching assisted pods.
- **Operator re-reconcile:** Patching the StatefulSet directly can be overwritten if the operator reconciles without proxy in its own env. Treat ConfigMap + StatefulSet env as a pair; document what you applied for upgrades.

### Install-target proxy (`InfraEnv`)

When servers booting the discovery ISO also need a proxy to reach the hub or Red Hat, set proxy on the **InfraEnv** (or cluster install config), not only on the hub:

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: example
spec:
  proxy:
    httpProxy: "http://proxy.example.com:8080"
    httpsProxy: "http://proxy.example.com:8080"
    noProxy: ".svc,.cluster.local,10.0.0.0/8"
```

Proxy credentials in URLs must be URL-encoded.

---

## Mirror configuration

Use a mirror when the hub cannot reach `mirror.openshift.com` directly — fully disconnected labs, or connected-via-proxy environments where hosting ISOs internally is simpler than fighting egress.

### Mirror ConfigMap for registries

Create a `ConfigMap` in `multicluster-engine` with label `app: assisted-service`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: assisted-installer-mirror-config
  namespace: multicluster-engine
  labels:
    app: assisted-service
data:
  ca-bundle.crt: |
    -----BEGIN CERTIFICATE-----
    # Registry / mirror CA
    -----END CERTIFICATE-----
  registries.conf: |
    unqualified-search-registries = ["registry.access.redhat.com", "docker.io"]

    [[registry]]
    location = "quay.io"
    mirror-by-digest-only = false

      [[registry.mirror]]
      location = "mirror.example.com:5000"
      insecure = false
```

Reference it from `AgentServiceConfig`:

```yaml
spec:
  mirrorRegistryRef:
    name: assisted-installer-mirror-config
  unauthenticatedRegistries:
    - mirror.example.com:5000   # only if mirror needs no pull-secret auth
```

`mirrorRegistryRef` affects **container image pulls during install**. It does not replace `spec.osImages` for RHCOS ISO/rootfs URLs.

### osImages on an internal mirror

Host RHCOS live ISO and rootfs on an HTTP server or mirror reachable from the hub (directly or via proxy). Point `AgentServiceConfig` at those URLs:

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: AgentServiceConfig
metadata:
  name: agent
spec:
  databaseStorage:
    accessModes: [ReadWriteOnce]
    resources:
      requests:
        storage: 10Gi
  filesystemStorage:
    accessModes: [ReadWriteOnce]
    resources:
      requests:
        storage: 100Gi
  imageStorage:
    accessModes: [ReadWriteOnce]
    resources:
      requests:
        storage: 50Gi
  mirrorRegistryRef:
    name: assisted-installer-mirror-config
  osImages:
    - cpuArchitecture: x86_64
      openshiftVersion: "4.16"
      version: "416.94.202410090854-0"
      url: "https://mirror.example.com/pub/rhcos/4.16.x/rhcos-live.x86_64.iso"
      rootFSUrl: "https://mirror.example.com/pub/rhcos/4.16.x/rhcos-live-rootfs.x86_64.img"
```

- Add the mirror hostname to **`NO_PROXY`** if it is on an internal network and should not traverse the corporate proxy.
- Add a new `osImages` entry per OCP version you need to provision.
- ISO sources: [mirror.openshift.com RHCOS paths](https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/) — sync to your mirror, then update URLs.

After apply, `assisted-image-service` fetches from your mirror instead of the public internet.

### Connected vs mirror: decision guide

| Signal | Prefer |
|--------|--------|
| Hub can reach `mirror.openshift.com` (direct or via injected proxy) | Connected `AgentServiceConfig` without `osImages` |
| Hub has cluster proxy but assisted pods lack env | [Corporate proxy](#corporate-proxy) injection |
| No outbound internet; internal registry only | Full [mirror configuration](#mirror-configuration) |
| Intermittent proxy / allowlist pain | Mirror `osImages` internally even if not fully air-gapped |

---

## 3. Network connectivity for provisioning

Install targets (physical servers or VMs booting the discovery ISO) must reach the hub's assisted services. This is **in addition to** hub ↔ managed-cluster connectivity documented in [networking-requirements-2.16.md](./networking-requirements-2.16.md).

| Direction | Purpose |
|-----------|---------|
| Install target → hub | HTTPS to `assisted-image-service` route (ISO download, agent registration) |
| Install target → hub | API connectivity during install |
| Hub → install target | BMC/Redfish only for Metal³/IPI bare-metal workflows |

Discover routes on the hub:

```bash
oc get routes -A | grep assisted
```

From an install target (or jump host on the same network), test reachability to the assisted-image-service URL before booting hosts from ISO.

---

## 4. Confirm provisioning works

After CIM is healthy, a minimal smoke test is creating an `InfraEnv` and waiting for the discovery ISO:

```bash
# After applying InfraEnv for a test namespace:
oc wait --for=condition=ImageCreated \
  infraenv/<name> -n <namespace> --timeout=300s

oc get infraenv <name> -n <namespace> \
  -o jsonpath='{.status.isoDownloadURL}{"\n"}'
```

If `ImageCreated` never becomes True, check assisted-service logs before debugging cluster CRs:

```bash
oc logs -n multicluster-engine deploy/assisted-service --tail=100
oc logs -n multicluster-engine deploy/assisted-image-service --tail=100
```

Full CR workflow: [BARE-METAL-OPERATOR-INTEGRATION.md — Method 1](../examples/BARE-METAL-OPERATOR-INTEGRATION.md#method-1-assisted-installer-with-discovery-iso).

---

## Common symptoms when CIM is not configured

| Symptom | Likely cause |
|---------|----------------|
| `oc get agentserviceconfig` empty | `AgentServiceConfig` never created |
| `assisted-service` pods not Ready / CrashLoop | Missing or invalid storage config |
| `InfraEnv` stuck, no `ImageCreated` | Assisted image service not healthy |
| PVCs Pending in `multicluster-engine` | No suitable StorageClass |
| Agents cannot register after ISO boot | Firewall/DNS — install target cannot reach assisted routes |
| Rootfs download fails at boot — `curl: (35) Connection reset by peer` | Install network → hub ingress :443; see [agent-install-rootfs-ssl-failure.md](../troubleshooting/agent-install-rootfs-ssl-failure.md) |
| ISO pull fails on `mirror.openshift.com` | Hub egress blocked; see [Corporate proxy](#corporate-proxy) or [Mirror configuration](#mirror-configuration) |
| Cluster proxy set but assisted pods have no `HTTP_PROXY` | Expected gap — inject proxy env on assisted pods |
| HTTPS via proxy fails with cert errors | Missing `trustedCA` on cluster proxy or incomplete CA bundle |

---

## Related documentation

| Doc | Contents |
|-----|----------|
| [Disconnected OCP + Quay (4.18.14)](../../ocp/disconnected-install/working-guide.md) | Full mirror stack — Quay, `oc-mirror`, install; this doc covers hub-side assisted mirror only |
| [production-readiness.md](./production-readiness.md) | Post-install hub hardening (search, backup, sizing) — complementary, not a substitute for CIM |
| [networking-requirements-2.16.md](./networking-requirements-2.16.md) | Hub ↔ managed cluster ports (import and Day-2 management) |
| [BARE-METAL-OPERATOR-INTEGRATION.md](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) | InfraEnv, AgentClusterInstall, discovery ISO, troubleshooting |
| [agent-install-rootfs-ssl-failure.md](../troubleshooting/agent-install-rootfs-ssl-failure.md) | Install host cannot pull rootfs from `assisted-image-service` during ISO boot |
| [ACM Clusters — CIM](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.5/html-single/clusters/index#enabling-the-central-infrastructure-management-service) | Upstream reference |
| [ACM — cluster proxy](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.3/html/clusters/creating-a-cluster-proxy) | Hub and managed-cluster proxy context |
| [OCP — cluster-wide proxy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/configuring_network_settings/enable-cluster-wide-proxy) | `Proxy` CR, `trustedCA`, `noProxy` |
| [Assisted Installer](https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/) | Assisted Installer product docs |

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*
