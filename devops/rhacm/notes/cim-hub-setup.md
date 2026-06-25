---
review:
  status: unreviewed
  notes: "AI-generated 2026-06-25. Hub CIM / AgentServiceConfig prerequisites sourced from ACM Clusters docs and OCP Assisted Installer documentation. Not yet validated against a live hub in this environment."
---

# ACM Hub CIM Setup — Enable On-Prem Cluster Provisioning

A working reference for enabling **Central Infrastructure Management (CIM)** on an ACM hub so you can **provision** new OpenShift clusters on bare metal (or agent-based installs, including nested OCP VMs) via the Assisted Installer.

**Audience:** Platform engineers standing up or auditing a bare-metal ACM hub.

**Not covered here:** Importing an already-installed cluster into ACM — that path does not require `AgentServiceConfig`. See [cluster-import-ansible](../examples/cluster-import-ansible/README.md) and [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](../examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md).

**Downstream workflow:** Once CIM is healthy, see [BARE-METAL-OPERATOR-INTEGRATION.md](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) for `InfraEnv`, discovery ISO, and install CRs.

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
- **Disconnected:** mirror registry, `ConfigMap` for `assisted-service`, and `osImages` URLs on the mirror — see [Disconnected setup](#disconnected-setup) below

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
oc wait -n multicluster-engine deployment/assisted-image-service --for=condition=Available --timeout=300s
```

---

## Disconnected setup

Two additional pieces beyond the connected flow.

### Mirror ConfigMap

Create a `ConfigMap` in the infrastructure operator namespace (label `app: assisted-service`) with `ca-bundle.crt` and `registries.conf` for your mirror. See [ACM — Creating AgentServiceConfig](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.5/html-single/clusters/index#creating-the-agentserviceconfig-custom-resource).

### AgentServiceConfig with mirror and osImages

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
    name: <mirror-configmap-name>
  unauthenticatedRegistries:
    - <optional-unauthenticated-registry>
  osImages:
    - openshiftVersion: "4.16"
      version: "<release-version>"
      url: "<rhcos-iso-url-on-mirror>"
      rootFSUrl: "<rhcos-rootfs-url-on-mirror>"
      cpuArchitecture: x86_64
```

Update `spec.osImages` when you need to provision clusters on a new OCP minor version.

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

---

## Related documentation

| Doc | Contents |
|-----|----------|
| [production-readiness.md](./production-readiness.md) | Post-install hub hardening (search, backup, sizing) — complementary, not a substitute for CIM |
| [networking-requirements-2.16.md](./networking-requirements-2.16.md) | Hub ↔ managed cluster ports (import and Day-2 management) |
| [BARE-METAL-OPERATOR-INTEGRATION.md](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) | InfraEnv, AgentClusterInstall, discovery ISO, troubleshooting |
| [ACM Clusters — CIM](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.5/html-single/clusters/index#enabling-the-central-infrastructure-management-service) | Upstream reference |
| [Assisted Installer](https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/) | Assisted Installer product docs |

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*
