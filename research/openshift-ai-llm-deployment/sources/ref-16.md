# Source: ref-16

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-nvidia-gpus_install
**Fetched:** 2026-04-17 17:54:32

---

1. [Home](/)
2. [Products](/en/products)
3. [Red Hat OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/)
4. [2.16](/en/documentation/red_hat_openshift_ai_self-managed/2.16/)
5. [Installing and uninstalling OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/)
6. Chapter 8. Enabling NVIDIA GPUs

# Chapter 8. Enabling NVIDIA GPUs

---

Before you can use NVIDIA GPUs in OpenShift AI, you must install the NVIDIA GPU Operator.

Important

If you are using OpenShift AI in a disconnected self-managed environment, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/enabling-nvidia-gpus_install) instead.

**Prerequisites**

* You have logged in to your OpenShift cluster.
* You have the `cluster-admin` role in your OpenShift cluster.
* You have installed an NVIDIA GPU and confirmed that it is detected in your environment.

**Procedure**

1. To enable GPU support on an OpenShift cluster, follow the instructions here: [NVIDIA GPU Operator on Red Hat OpenShift Container Platform](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/index.html) in the NVIDIA documentation.

   Important

   After you install the Node Feature Discovery (NFD) Operator, you must create an instance of NodeFeatureDiscovery. In addition, after you install the NVIDIA GPU Operator, you must create a ClusterPolicy and populate it with default values.
2. Delete the **migration-gpu-status** ConfigMap.

   1. In the OpenShift web console, switch to the **Administrator** perspective.
   2. Set the **Project** to **All Projects** or **redhat-ods-applications** to ensure you can see the appropriate ConfigMap.
   3. Search for the **migration-gpu-status** ConfigMap.
   4. Click the action menu (⋮) and select **Delete ConfigMap** from the list.

      The **Delete ConfigMap** dialog appears.
   5. Inspect the dialog and confirm that you are deleting the correct ConfigMap.
   6. Click **Delete**.
3. Restart the dashboard replicaset.

   1. In the OpenShift web console, switch to the **Administrator** perspective.
   2. Click **Workloads**  **Deployments**.
   3. Set the **Project** to **All Projects** or **redhat-ods-applications** to ensure you can see the appropriate deployment.
   4. Search for the **rhods-dashboard** deployment.
   5. Click the action menu (⋮) and select **Restart Rollout** from the list.
   6. Wait until the **Status** column indicates that all pods in the rollout have fully restarted.

**Verification**

* The reset **migration-gpu-status** instance is present on the **Instances** tab on the `AcceleratorProfile` custom resource definition (CRD) details page.
* From the **Administrator** perspective, go to the **Operators**  **Installed Operators** page. Confirm that the following Operators appear:

  + NVIDIA GPU
  + Node Feature Discovery (NFD)
  + Kernel Module Management (KMM)
* The GPU is correctly detected a few minutes after full installation of the Node Feature Discovery (NFD) and NVIDIA GPU Operators. The OpenShift command line interface (CLI) displays the appropriate output for the GPU worker node. For example:

  ```
  # Expected output when the GPU is detected properly
  oc describe node <node name>
  ...
  Capacity:
    cpu:                4
    ephemeral-storage:  313981932Ki
    hugepages-1Gi:      0
    hugepages-2Mi:      0
    memory:             16076568Ki
    nvidia.com/gpu:     1
    pods:               250
  Allocatable:
    cpu:                3920m
    ephemeral-storage:  288292006229
    hugepages-1Gi:      0
    hugepages-2Mi:      0
    memory:             12828440Ki
    nvidia.com/gpu:     1
    pods:               250
  ```

Note

In OpenShift AI 2.16, Red Hat supports the use of accelerators within the same cluster only. Red Hat does not support remote direct memory access (RDMA) between accelerators, or the use of accelerators across a network, for example, by using technology such as NVIDIA GPUDirect or NVLink.

After installing the NVIDIA GPU Operator, create an accelerator profile as described in [Working with accelerator profiles](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/working_with_accelerators/#working-with-accelerator-profiles_accelerators).