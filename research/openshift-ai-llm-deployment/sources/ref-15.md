# Source: ref-15

**URL:** https://docs.nvidia.com/ai-enterprise/deployment/red-hat-ai-factory/latest/nfd-operator.html
**Fetched:** 2026-04-17 17:54:31

---

# Install the Node Feature Discovery (NFD) Operator[#](#install-the-node-feature-discovery-nfd-operator "Link to this heading")

The Node Feature Discovery (NFD) Operator is a prerequisite for the NVIDIA GPU and Network Operators. NFD will perform a discovery and reconciliation loop and apply node labels to each machine that describe the hardware configuration.

The Node Feature Discovery Operator uses vendor PCI IDs to identify hardware in a node. `0x10de` and `15b3` are the PCI vendor IDs assigned to NVIDIA. Inspect the node labels using the OpenShift Container Platform web console or the CLI to verify that the Node Feature Discovery Operator is functioning correctly.

## Install NFD Operator[#](#install-nfd-operator "Link to this heading")

Install the NFD Operator using the Red Hat Software Catalog (Red Hat OperatorHub in versions before 4.20).

**Access the Red Hat OpenShift console**.

1. Navigate to **Ecosystem** -> **Software Catalog**.
2. Search for âNode Feature Discovery Operatorâ (or **NFD**).
3. Select the **Node Feature Discovery Operator**.
4. Click **Install**.
5. Select the desired **Installation mode** (usually âAll namespaces on the cluster (default)â for cluster-wide functionality).
6. Select the **Installed Namespace** (usually `openshift-nfd`).
7. Select the desired **Update approval strategy** (Manual or Automatic).
8. Click **Install**.
9. Wait for the Operator to be installed and its status to change to **Succeeded** on the **Installed Operators** page.

Note

After installation, you will need to create an instance of the `NodeFeatureDiscovery` Custom Resource (CR) to deploy the NFD pods. This is typically done on the **Operator Details** page by clicking **Create instance** on the âNode Feature Discoveryâ API.

For more comprehensive documentation, including installing using the CLI and configuration options, refer to the Red Hat documentation in the [Node Feature Discovery Operator guide](https://docs.openshift.com/container-platform/latest/hardware_enablement/psap-node-feature-discovery-operator.html).

## Verifying NFD node labels using the web console[#](#verifying-nfd-node-labels-using-the-web-console "Link to this heading")

1. In the OpenShift Container Platform web console, click Compute > Nodes from the side menu.
2. Select a worker node that contains a GPU.
3. Click the Details tab.
4. Under Node Labels, verify that the following label is present: `feature.node.kubernetes.io/pci-10de.present=true`

## Verifying NFD node labels using the CLI[#](#verifying-nfd-node-labels-using-the-cli "Link to this heading")

1. Verify that the PCI devices are discovered on the nodes:

   ```
   1oc describe node | egrep 'Roles|pci-10de|pci-15b3'
   2Roles:              control-plane,master,worker
   3                    feature.node.kubernetes.io/pci-10de.present=true
   4                    feature.node.kubernetes.io/pci-10de.sriov.capable=true
   5                    feature.node.kubernetes.io/pci-15b3.present=true
   6                    feature.node.kubernetes.io/pci-15b3.sriov.capable=true
   ```