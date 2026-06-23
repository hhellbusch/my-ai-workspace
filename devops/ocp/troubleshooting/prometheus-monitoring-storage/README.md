# Prometheus and Alertmanager storage (`StorageClass`) on OpenShift

This guide explains how to set **`storageClassName`** (and size) for the Cluster Monitoring Operator (CMO) stack—platform Prometheus, Alertmanager, and user-workload monitoring—and why **PVCs or pods** often appear stuck in **Pending**.

For a home-lab SNO cluster without cloud CSI, see [SNO local storage](../../examples/sno-kvm-lab/local-storage.md) (`local-storage` StorageClass).

## Official documentation

Use the version that matches your OpenShift minor release (replace `4.xx` or use `latest` on docs.redhat.com).

| Topic | Red Hat documentation |
|--------|------------------------|
| Core platform monitoring (persistent storage, prerequisites) | [Monitoring stack for Red Hat OpenShift — Configuring core platform monitoring — Storing and recording data](https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html/configuring_core_platform_monitoring/storing-and-recording-data) |
| User workload monitoring | [Monitoring stack for Red Hat OpenShift — Configuring user workload monitoring — Storing and recording data](https://docs.redhat.com/en/documentation/monitoring_stack_for_red_hat_openshift/latest/html/configuring_user_workload_monitoring/storing-and-recording-data-uwm) |
| `volumeClaimTemplate` field semantics | [Kubernetes — PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) |

The procedures below follow the same **ConfigMap** + **`volumeClaimTemplate`** pattern described in those chapters.

---

## Core platform monitoring (`openshift-monitoring`)

**ConfigMap:** `cluster-monitoring-config` in namespace **`openshift-monitoring`**.

```bash
oc -n openshift-monitoring edit configmap cluster-monitoring-config
```

Under `data.config.yaml`, set storage per component using **`volumeClaimTemplate.spec`**. Common keys:

| Component | YAML key under `config.yaml` |
|-----------|------------------------------|
| Prometheus (platform metrics) | `prometheusK8s` |
| Alertmanager | `alertmanagerMain` |

**Example** (replace placeholders; adjust sizes for your environment):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusK8s:
      volumeClaimTemplate:
        spec:
          storageClassName: <storage_class>
          resources:
            requests:
              storage: 40Gi
    alertmanagerMain:
      volumeClaimTemplate:
        spec:
          storageClassName: <storage_class>
          resources:
            requests:
              storage: 10Gi
```

- If you **omit** `storageClassName`, the cluster’s **default** `StorageClass` is used (standard Kubernetes behavior).
- Red Hat documents that monitoring **must** use **`Filesystem`** volume mode (not raw **`Block`** volumes) for Prometheus, and that Prometheus requires **POSIX-compliant** file systems—verify NFS and similar backends with the vendor if applicable.

---

## User workload monitoring (`openshift-user-workload-monitoring`)

**ConfigMap:** `user-workload-monitoring-config` in namespace **`openshift-user-workload-monitoring`**.

```bash
oc -n openshift-user-workload-monitoring edit configmap user-workload-monitoring-config
```

| Component | YAML key under `config.yaml` |
|-----------|------------------------------|
| Prometheus (user-defined projects) | `prometheus` |
| Thanos Ruler | `thanosRuler` |

**Example:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-workload-monitoring-config
  namespace: openshift-user-workload-monitoring
data:
  config.yaml: |
    prometheus:
      volumeClaimTemplate:
        spec:
          storageClassName: <storage_class>
          resources:
            requests:
              storage: 40Gi
    thanosRuler:
      volumeClaimTemplate:
        spec:
          storageClassName: <storage_class>
          resources:
            requests:
              storage: 10Gi
```

**Notes from Red Hat docs:**

- User workload settings apply only if an administrator has **enabled monitoring for user-defined projects**.
- Saving these ConfigMaps can **redeploy or restart** monitoring workloads; plan for brief impact.

---

## Why PVCs or workloads end up “stuck”

Distinguish **`Pending` on a PVC** from **`Pending` on a Pod**; they have different causes.

### PVC stuck in `Pending` (storage binding / provisioning)

Typical causes:

1. **Wrong or missing `StorageClass`** — No provisioner runs, or the class name does not exist.
2. **No default `StorageClass`** — Claims that rely on the default never get a class assigned automatically.
3. **Static / local volumes** — Red Hat documents that with **local** persistence you need **PVs ready to be claimed**. For components with **multiple replicas**, you need **enough PVs** (the docs illustrate that Prometheus and Alertmanager use **two replicas** each, so **four PVs** can be required for the full core stack when using local static storage—not dynamic provisioning).
4. **`volumeBindingMode: WaitForFirstConsumer`** — The PVC may stay unbound until a pod can be scheduled that references it; if scheduling fails, storage and scheduling issues get tangled.
5. **Backend / quota / topology** — Insufficient capacity, storage quotas, zone or topology mismatches, or CSI driver errors.

**Quick checks:**

```bash
oc -n openshift-monitoring describe pvc <pvc-name>
oc get storageclass
oc get pv
oc get events -n openshift-monitoring --sort-by='.lastTimestamp' | tail -30
```

Read the **Events** section on the PVC and on the related pod; the message usually states whether the problem is provisioning, no matching PV, or waiting for a consumer.

### Pod stuck in `Pending` (scheduling, not storage)

Red Hat documents that if monitoring pods remain **Pending** after setting **`nodeSelector`**, you should inspect **pod events** for **taints and tolerations** mismatches. That is a **scheduler** issue, not necessarily a PVC problem.

```bash
oc -n openshift-monitoring describe pod <pod-name>
```

### Config changes and resizing

Documentation warns that changes to monitoring ConfigMaps can **restart** affected components. **Resizing** volumes used by these **StatefulSets** is not a simple in-place PVC edit on OpenShift; the official guides describe a **manual** process (update ConfigMap, patch PVC, and carefully handle pod/StatefulSet lifecycle) when you must grow storage.

---

## Related material in this repo

- [Portworx CSI CrashLoop](../portworx-csi-crashloop/README.md) — general CSI / storage driver failures that can also block monitoring PVCs if Portworx is the default class.
