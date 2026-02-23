# Troubleshooting a Failed OpenShift Installation

## Overview

This guide helps you troubleshoot an OpenShift Container Platform (OCP) installation that did not complete successfully. It is written for system administrators and OpenShift installers who may be **new to Linux**—we explain concepts and commands as we go so you can both fix the issue and learn.

**You will learn:**

- What happens during an OCP install and where it can fail
- How to tell which phase of the install you're stuck in
- Which commands to run and what they mean
- When to use other, more specific troubleshooting guides

**When to use this guide:** Your `openshift-install` run is stuck, timed out, or reported an error before the cluster was fully ready.

---

## Quick Links

- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Fast command reference if you're already familiar with the process ⚡
- **[INDEX.md](INDEX.md)** - Navigate this guide by symptom or phase
- **[Control Plane Kubeconfigs / Installation Monitoring](../control-plane-kubeconfigs/INSTALL-MONITORING.md)** - Detailed install-phase timeline and monitoring

---

## Concepts You'll Need

These short explanations will help you follow the rest of the guide. If you already know them, you can skip to [What Does a Failed Install Look Like?](#what-does-a-failed-install-look-like).

### Terminal and shell

- **Terminal** (or "command line"): A window where you type text commands instead of clicking. On Windows you might use PowerShell or Command Prompt; on Linux or macOS you use a terminal (e.g. bash, zsh).
- **Prompt**: The line that appears before your cursor, e.g. `[user@host ~]$`. You type commands after it and press Enter.
- **Command**: A program you run by typing its name and sometimes options, e.g. `oc get nodes`, `ssh core@10.0.0.1`.

### Your installation host

- **Installation host**: The machine where you ran `openshift-install create cluster` (or the equivalent). It might be your laptop, a bastion, or a VM. You need network access from here to the cluster (and often SSH to nodes).

### OpenShift install phases (simplified)

An OCP install roughly goes through:

1. **Bootstrap** – A temporary node runs a small control plane so the real control plane can start.
2. **Control plane** – Three (or more) master nodes start etcd, API server, controller manager, scheduler.
3. **Cluster operators** – OpenShift components (networking, DNS, console, etc.) start and become "Available."
4. **Install complete** – All operators are healthy; you can use the web console and run workloads.

If the install "fails," it is stuck or errored in one of these phases.

### Bootstrap node

- **Bootstrap node**: A short-lived machine that runs the cluster long enough for the permanent control plane to take over. After that, it is torn down. If the install fails before "bootstrap complete," the bootstrap node may still be running; we might need to SSH to it or check its logs.

### Kubeconfig

- **Kubeconfig**: A file that tells `oc` (and `kubectl`) *which cluster* to talk to and *how to authenticate*. During install you get a kubeconfig at `auth/kubeconfig` in your install directory. If the API is not reachable from your laptop, we sometimes use a **localhost kubeconfig** on a control plane node to talk to the API on that same node.

### Cluster operators

- **Cluster operators**: OpenShift’s way of managing core services (networking, DNS, storage, etc.). Each has a status: **Available**, **Progressing**, **Degraded**. The install is not "complete" until the right set of operators are Available and not Degraded. We check them with `oc get clusteroperators` or `oc get co`.

### CSRs (Certificate Signing Requests)

- **CSR**: When a node or component needs a certificate to join or talk to the cluster, it creates a Certificate Signing Request. Someone (or something) must **approve** that request. If CSRs are left **Pending**, nodes can stay "Not Ready" and the install can appear stuck. We look at CSRs with `oc get csr` and approve them when appropriate.

### SSH

- **SSH**: A way to log in to another machine over the network. Example: `ssh core@10.0.0.5` means "log in as user `core` on the machine at 10.0.0.5." On OpenShift nodes the default user is usually `core`. You need the right SSH key (often the one you passed to the installer) and network reachability.

---

## What Does a Failed Install Look Like?

Symptoms depend on **where** the install stopped.

| Phase | What you see | What it means |
|-------|----------------|---------------|
| **Bootstrap** | `wait-for bootstrap-complete` never finishes; or install fails before that | Bootstrap node or control plane did not come up in time. |
| **After bootstrap** | Bootstrap completed but you cannot run `oc` from your laptop (connection refused, timeout, or TLS error) | API server not reachable or not accepting connections (e.g. certificate or network issue). |
| **API up, operators stuck** | `oc` works but `oc get co` shows operators Progressing or Degraded for a long time | One or more cluster operators are not becoming healthy. |
| **Workers not joining** | Control plane looks good but worker nodes stay Not Ready or never appear | Often CSRs not approved, or TLS/certificate issues on workers. |
| **Bare metal only** | Node stuck in "inspecting" or "provisioning" | Bare metal host not passing inspection or provisioning. See [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md). |

The rest of this guide walks you through **finding which phase you're in** and **what to do next**.

---

## Before You Start: Gather This Information

Collect these so you (or support) can understand the environment:

1. **Install method** – e.g. IPI (Installer-Provisioned Infrastructure) or UPI (User-Provisioned), and platform (AWS, vSphere, bare metal, etc.).
2. **Install directory** – The directory where you ran `openshift-install` (e.g. `~/clusterconfigs`). It contains `metadata.json`, `auth/kubeconfig`, and logs.
3. **What you ran** – Did you run `wait-for bootstrap-complete` or `wait-for install-complete`? What exact command failed or is still running?
4. **Error messages** – Any error text from the installer or from `oc` (copy or screenshot).
5. **Access** – Can you SSH to bootstrap or control plane nodes? (IPs are often in your install config or from the cloud/VM console.)

---

## Step-by-Step Troubleshooting Workflow

### Step 1: Confirm where you're running commands

All commands in this section assume you're on a machine that can reach the cluster:

- **From your installation host**: You need the install directory and (once the API is up) the kubeconfig. Set it once:
  ```bash
  export KUBECONFIG=/path/to/your/install/dir/auth/kubeconfig
  ```
  Replace `/path/to/your/install/dir` with your actual path (e.g. `~/clusterconfigs`).

- **From a control plane node**: After SSH (`ssh core@<control-plane-ip>`), we sometimes use the localhost kubeconfig (explained when needed).

**Tip:** `echo $KUBECONFIG` shows the current kubeconfig path. If it's empty, `oc` won't know which cluster to use.

---

### Step 2: Check the installation log

The installer writes a log in the install directory. Look for the last errors:

```bash
# Go to your install directory (replace with your path)
cd /path/to/your/install/dir

# Show the last 100 lines of the install log
tail -100 .openshift_install.log
```

- **What to look for:** Lines containing "error", "failed", "timeout", or "FATAL". They often point to bootstrap, API, or a specific operator.
- **Learning:** `tail -100` means "show the last 100 lines of this file." It's a quick way to see the most recent activity.

---

### Step 3: Determine which phase you're in

Use this flow:

#### 3a) Can you run `oc` from the installation host?

From the install host, with `KUBECONFIG` set to `auth/kubeconfig`:

```bash
oc get nodes
oc get clusteroperators
```

- **If both commands work:** You're in the phase where the API is up but something (often operators or nodes) is not ready. Go to [Step 5: API works, install not complete](#step-5-api-works-install-not-complete).
- **If you get connection refused, timeout, or TLS/certificate errors:** The API is not reachable or not trusted. Go to [Step 4: API not reachable](#step-4-api-not-reachable).
- **If you don't have a kubeconfig yet or the install failed very early:** You're likely in the bootstrap phase. Go to [Step 4: API not reachable](#step-4-api-not-reachable) (we'll check bootstrap there).

#### 3b) Did bootstrap complete?

If you have an install directory, you can check whether the installer thinks bootstrap finished:

```bash
# From install directory; this exits 0 if bootstrap completed, else it waits or fails
./openshift-install wait-for bootstrap-complete --log-level=info
```

- If it **succeeds** (exits 0): Bootstrap is done; the problem is later (API reachability or operators).
- If it **hangs or fails**: The failure is at or before bootstrap. Continue with Step 4.

---

### Step 4: API not reachable (or bootstrap not complete)

In this situation you cannot (or could not) use `oc` from the install host. We need to see what’s happening on the bootstrap or control plane nodes.

#### Option A: You have SSH to a control plane node

If you have the IP of a control plane node (from your install config or cloud/VM console):

```bash
# Replace with the real IP and ensure your SSH key is used (often -i path/to/key)
ssh core@<control-plane-ip>
```

Once on the node, check if the API is running **locally** and use the localhost kubeconfig:

```bash
# Set kubeconfig to talk to the API on this same node
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# See if the API responds
oc get nodes
oc get co
```

- **If these work:** The API is up on that node but not reachable from outside (e.g. load balancer, firewall, or certificate). See [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) if you see TLS/cert errors from your laptop; otherwise check network/firewall and kubeconfig server address.
- **If you get "connection refused" or "No route to host":** The API server may not be running yet or the node is still starting. Check whether bootstrap completed and give it more time, or check control plane node status (see Option B).
- **If you get TLS or certificate errors even here:** The serving certificate on the API may be wrong. See [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md).

**Learning:** The **localhost** kubeconfig talks to `https://localhost:6443` on the node you’re SSH’d into, so it bypasses load balancers and external networking. That’s why it can work when your laptop cannot reach the API.

#### Option B: Bootstrap not complete – check bootstrap node

If bootstrap has not completed, the bootstrap node may still exist. You need its IP (from install config or cloud). Then:

```bash
# SSH to bootstrap node (replace IP and key path)
ssh core@<bootstrap-ip>

# Watch the service that brings up the temporary control plane
sudo journalctl -u bootkube.service -f
```

- **What to look for:** Repeated errors or "Failed" lines. Common issues: etcd not forming, certificates, or network between bootstrap and masters.
- **Learning:** `journalctl -u bootkube.service -f` shows logs for the `bootkube` service and follows new lines (`-f` = follow). Press Ctrl+C to stop.

If you don’t have SSH to bootstrap or control plane, use cloud/VM console access to get logs from the bootstrap or first control plane node (same `journalctl` command where possible).

#### Option C: Bare metal – nodes stuck inspecting or provisioning

If you’re on bare metal and nodes are stuck in **inspecting** or **provisioning**, use the dedicated guide: [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md).

---

### Step 5: API works, install not complete

Once `oc get nodes` and `oc get co` work (from install host or from a control plane node with localhost kubeconfig), focus on **why the install hasn’t finished**.

#### 5a) Check for pending CSRs

Nodes need approved certificates to join. If CSRs are stuck in **Pending**, nodes stay Not Ready:

```bash
# List CSRs; look for Pending
oc get csr

# Or only pending ones
oc get csr | grep Pending
```

**What you see:** Columns are typically NAME, AGE, SIGNERNAME, REQUESTOR, CONDITION. CONDITION can be **Pending** or **Approved**.

If you see **Pending** CSRs for nodes you expect (e.g. requestor `system:node:master-0` or `system:serviceaccount:openshift-machine-config-operator:node-bootstrapper`), approve them:

```bash
# Approve all pending CSRs (only if you're sure these are your cluster's nodes)
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

Then recheck nodes:

```bash
oc get nodes
```

**Learning:** `xargs` takes the list of CSR names and runs `oc adm certificate approve` for each. `--no-run-if-empty` avoids running the command when there are no pending CSRs (Linux). On macOS, omit that flag if the command fails. For more control and explanation, see [CSR Management](../csr-management/README.md).

#### 5b) Check cluster operators

See which operators are not Available or are Degraded:

```bash
# Full list
oc get clusteroperators

# Only problematic ones (Available=False or Degraded=True)
oc get co | grep -v "True.*False.*False"
```

**What you see:** Columns are typically NAME, AVAILABLE, PROGRESSING, DEGRADED, SINCE. We want AVAILABLE=True, PROGRESSING=False, DEGRADED=False for install to be complete.

- If **kube-controller-manager** or **kube-apiserver** is Degraded or not Available, see [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md) and [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) as needed.
- For **other operators**, click the operator name in the console or run `oc describe co <name>` and read the "Message" / "Reason" for the failing condition. Often it’s a dependency (e.g. network or DNS) or a known bug; the message may point to a specific guide.

#### 5c) Monitor installation progress

For a phase-by-phase timeline and what to run during install, use [Installation Monitoring](../control-plane-kubeconfigs/INSTALL-MONITORING.md). It explains bootstrap vs. control plane vs. operator bring-up and gives watch commands.

#### 5d) Workers not joining (workers stay Not Ready or missing)

If control plane looks good but workers never become Ready:

- Check **pending CSRs** (Step 5a) and approve them.
- For **TLS/certificate errors** when workers join, see [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md).
- For **bare metal** workers stuck in inspecting/provisioning, see [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md).

---

### Step 6: Collect diagnostics before changing more

Before you try bigger fixes (or open a support case), collect standard diagnostics.

**If the API is reachable** (from install host or a control plane node with localhost kubeconfig):

```bash
# From install host, with working KUBECONFIG
oc adm must-gather --dest-dir=./must-gather-$(date +%Y%m%d-%H%M%S)
```

This creates a directory with cluster state, operator status, and logs. **Learning:** `must-gather` is OpenShift’s standard way to capture support-level information; the `date` in the path avoids overwriting previous runs. If the API is not reachable from the install host but you can SSH to a control plane node, run `must-gather` from that node after setting the localhost kubeconfig (see Step 4 Option A).

**If the API is not reachable** (bootstrap or early control plane failure), use the installer’s **gather bootstrap** to collect logs for debugging or a support case. You must have provided an SSH key during install and have the bootstrap node (and optionally masters) reachable:

```bash
# From install directory (IPI – installer-provisioned infrastructure)
./openshift-install gather bootstrap --dir .

# UPI (user-provisioned): specify bootstrap and master addresses
./openshift-install gather bootstrap --dir . \
  --bootstrap <bootstrap-ip> \
  --master <master-1-ip> --master <master-2-ip> --master <master-3-ip>
```

**Learning:** For *failed* installs, Red Hat recommends `openshift-install gather bootstrap`; for *running* clusters, use `oc adm must-gather`. See [Red Hat: Gathering data about your cluster](#red-hat-and-openshift-resources) below.

---

## When to Use Other Guides

| Situation | Guide to use |
|-----------|----------------|
| You need the exact install timeline and monitoring commands | [Control Plane Kubeconfigs / Installation Monitoring](../control-plane-kubeconfigs/INSTALL-MONITORING.md) |
| Pending CSRs and certificate approval | [CSR Management](../csr-management/README.md) |
| TLS/certificate errors to the API (e.g. "certificate signed by unknown authority") | [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) |
| kube-controller-manager crash looping | [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md) |
| Bare metal node stuck in inspecting or provisioning | [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) |
| Worker nodes failing with TLS/cert errors | [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md) |
| Suspected node-level networking (e.g. CoreOS) | [CoreOS Networking Issues](../coreos-networking-issues/README.md) |
| Install failed and you want to destroy the cluster but lost metadata | [Destroy Cluster Without Metadata](../destroy-cluster-without-metadata/README.md) |

---

## When to Retry vs. Destroy and Start Over

- **Retry in place** when: The cluster is partially up (API works, some operators up), and the fix is clear (e.g. approve CSRs, fix one operator). Give operators time to settle (e.g. 15–30 minutes) after fixes.
- **Destroy and reinstall** when: Bootstrap never succeeded and you have no path to fix it; or the cluster is in a bad state and support or your team agrees. Use `openshift-install destroy cluster --dir=.` from the install directory if you still have the metadata file. If you lost it, see [Destroy Cluster Without Metadata](../destroy-cluster-without-metadata/README.md).

---

## Verification After Fixes

Once you believe the install has completed:

```bash
# All operators should be Available, not Degraded
oc get clusteroperators | grep -v "True.*False.*False"
# (Ideally only the header line; no extra lines.)

# All nodes Ready
oc get nodes

# From install directory, wait for install complete (if not already)
./openshift-install wait-for install-complete
```

If `wait-for install-complete` succeeds and you can log in to the web console, the install is complete.

---

## Red Hat and OpenShift Resources

Official Red Hat and OpenShift documentation that complement this guide:

| Resource | Description |
|----------|-------------|
| [Troubleshooting installation issues](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/validation_and_troubleshooting/installing-troubleshooting) | Official install troubleshooting: gathering logs, determining where issues occur, network/firewall checks. *(Replace `latest` with your OCP version, e.g. `4.19`, if the link does not resolve.)* |
| [Validation and troubleshooting (index)](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/validation_and_troubleshooting/index) | Entry point for validation, install troubleshooting, and cluster health. |
| [Gathering data about your cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/support/gathering-cluster-data) | When to use `openshift-install gather bootstrap` (failed install) vs. `oc adm must-gather` (running cluster); prerequisites and options. |
| [Understanding the OpenShift must-gather](https://access.redhat.com/articles/4591521) | Red Hat Customer Portal article on what must-gather collects and how to use it for support cases. |
| [OpenShift Container Platform documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest) | Main product docs: installation, administration, scaling. |
| [Red Hat Customer Portal](https://access.redhat.com/) | Support cases, knowledge base, product downloads, and subscriptions. |
| [OpenShift CLI (oc) reference](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html) | Command reference for `oc`. |

---

## Glossary

| Term | Meaning |
|------|---------|
| **Bootstrap** | Short-lived node that runs the cluster until the real control plane is up. |
| **Control plane** | Master nodes running etcd, API server, controller manager, scheduler. |
| **Cluster operator (co)** | OpenShift component that manages a part of the cluster (network, DNS, etc.). |
| **CSR** | Certificate Signing Request; must be approved for nodes/components to get certs. |
| **Kubeconfig** | File that tells `oc`/`kubectl` which cluster and credentials to use. |
| **Localhost kubeconfig** | Kubeconfig on a node that talks to the API on that same node (localhost:6443). |
| **Install host** | Machine where you run `openshift-install`. |
| **IPI** | Installer-Provisioned Infrastructure (installer creates VMs, networks, etc.). |
| **UPI** | User-Provisioned Infrastructure (you create machines and network; installer uses them). |

---

*This guide is part of the [OpenShift Troubleshooting](../README.md) set. AI-assisted drafting was used during creation.*
