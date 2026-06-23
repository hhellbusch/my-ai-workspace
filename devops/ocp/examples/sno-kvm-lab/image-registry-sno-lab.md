# SNO Lab — Enable Internal Image Registry

> **Audience:** Operators running the home-lab SNO cluster (`sno.hell`) after [storage](dynamic-storage.md) is configured.
> **Purpose:** Enable the cluster image registry so DevSpaces (and other workloads) can pull `openshift/cli` and other internal images.

Companion to [dynamic-storage.md](dynamic-storage.md) and the [SNO KVM lab guide](README.md).

---

## On this page

- [Why this is a separate step](#why-this-is-a-separate-step)
- [Symptoms](#symptoms)
- [Procedure (lab)](#procedure-lab)
- [Persistent registry storage (optional)](#persistent-registry-storage-optional)
- [DevSpaces follow-up](#devspaces-follow-up)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Related reading](#related-reading)

---

## Why this is a separate step

SNO installs often ship with the **internal image registry removed** to save resources:

```bash
oc get configs.imageregistry.operator.openshift.io cluster \
  -o jsonpath='{.spec.managementState}{"\n"}'
# Removed
```

**Storage and the image registry are independent:**

| Component | What it provides |
|-----------|------------------|
| HPP / LVMS / Local Storage | PVCs for workspace data, apps, monitoring |
| Internal image registry | In-cluster image hosting at `image-registry.openshift-image-registry.svc:5000` |

[OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces) devfiles commonly reference:

```yaml
image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
```

Without a running registry, workspace pods fail on the **`oc-cli` init container** even when the workspace PVC binds successfully.

---

## Symptoms

DevWorkspace stuck or failed:

```
Failed — Error creating DevWorkspace deployment: Init Container oc-cli has state ImagePullBackOff
```

Pod events:

```
Failed to pull image "image-registry.openshift-image-registry.svc:5000/openshift/cli:latest":
  dial tcp: lookup image-registry.openshift-image-registry.svc on ...: no such host
```

Or, before enabling:

```bash
oc get pods -n openshift-image-registry
# Only cluster-image-registry-operator and node-ca — no image-registry deployment
```

---

## Procedure (lab)

Use **`emptyDir`** for registry blob storage — fine for a lab; images are lost if the registry pod restarts.
No extra PVC required.

```bash
export KUBECONFIG=~/gemini-workspace/devops/ocp/install/exec/auth/kubeconfig
```

### 1. Enable the registry

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{
  "spec": {
    "managementState": "Managed",
    "replicas": 1,
    "storage": {
      "emptyDir": {}
    }
  }
}'
```

### 2. Wait for the registry pod

```bash
oc get pods -n openshift-image-registry -w
# Expect: image-registry-* 1/1 Running

oc get svc image-registry -n openshift-image-registry
# CLUSTER-IP on port 5000
```

### 3. Import the OpenShift CLI imagestream

DevSpaces pulls `openshift/cli:latest` from the internal registry.
The imagestream exists by default; import pushes the image into the registry:

```bash
oc import-image cli:latest -n openshift --confirm
oc get imagestream cli -n openshift
# Image Repository: image-registry.openshift-image-registry.svc:5000/openshift/cli
```

If `import-image` fails with API errors, wait for `openshift-apiserver` to be healthy and retry:

```bash
oc get clusteroperator openshift-apiserver image-registry
oc get pods -n openshift-apiserver
```

---

## Persistent registry storage (optional)

For registry images to survive pod restarts, back the registry with a PVC on your default StorageClass (`hostpath-csi` on this lab):

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{
  "spec": {
    "managementState": "Managed",
    "replicas": 1,
    "storage": {
      "pvc": {
        "claim": {
          "accessModes": ["ReadWriteOnce"],
          "resources": {
            "requests": {
              "storage": "10Gi"
            }
          }
        }
      }
    }
  }
}'
```

Omit `storageClassName` to use the cluster default.
Re-run `oc import-image cli:latest -n openshift --confirm` after the registry pod is Running.

---

## DevSpaces follow-up

After enabling the registry:

1. **Delete the failed workspace** (if one exists from before the fix):

```bash
oc delete devworkspace --all -n che-kube-admin-devspaces-qcgubv --wait=true
```

2. **Start a new workspace** from the DevSpaces dashboard.

The new workspace should:

- Provision a PVC on the default StorageClass (`hostpath-csi`)
- Pull `openshift/cli` from the internal registry for the `oc-cli` init container

Other devfile images (e.g. `quay.io/redhat-cop/devspaces-java21-node20-python311`) still require outbound access to quay.io.

---

## Verification

```bash
# Registry managed and running
oc get configs.imageregistry.operator.openshift.io cluster \
  -o jsonpath='{.spec.managementState}{" "}{.status.storageManaged}{"\n"}'

oc get deploy image-registry -n openshift-image-registry

# CLI image available in registry
oc get imagestream cli -n openshift \
  -o jsonpath='{.status.dockerImageRepository}{"\n"}'

# Workspace health (after restart)
oc get devworkspace -A
oc get pods -n che-kube-admin-devspaces-qcgubv
```

---

## Troubleshooting

### `import-image` — `ServiceUnavailable` or `imagestream` not found

The `image.openshift.io` API may be temporarily unavailable while apiserver or registry operators reconcile.
Wait and retry:

```bash
oc get clusteroperator openshift-apiserver image-registry
sleep 30
oc import-image cli:latest -n openshift --confirm
```

### Registry pod not starting

```bash
oc describe pod -n openshift-image-registry -l docker-registry=default
oc logs -n openshift-image-registry -l docker-registry=default
```

### DevSpaces still `ImagePullBackOff` on `oc-cli`

Confirm the image is in the registry:

```bash
oc get imagestream cli -n openshift
oc describe imagestream cli -n openshift
```

Delete the failed DevWorkspace and create a new one — init containers do not always retry after the registry comes up.

### Push/pull from your workstation (optional)

For `podman push` to the cluster registry from outside the cluster, expose a route and configure auth.
See [image-registry-auth](../../troubleshooting/image-registry-auth/README.md).

---

## Related reading

- [dynamic-storage.md](dynamic-storage.md) — HPP / storage setup (prerequisite)
- [Image registry auth](../../troubleshooting/image-registry-auth/README.md) — routes, `podman login`, RBAC
- [Prometheus monitoring storage](../../troubleshooting/prometheus-monitoring-storage/README.md) — another common post-storage PVC consumer

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author.
See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
