# SNO on KVM — Lab Setup Guide

Single Node OpenShift (SNO) cluster running in a KVM virtual machine, bridged onto a home LAN managed by pfSense. Intended as a local lab for testing ArgoCD, operator management, and GitOps workflows.

---

## Placeholders Used in This Guide

Replace these with your actual values before running any commands.

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `<LAN_NIC>` | Host machine's LAN network interface | `enp8s0`, `eno1`, `eth0` |
| `<HOST_IP>` | Host machine's current LAN IP address | `192.168.1.50` |
| `<GATEWAY_IP>` | Router / pfSense LAN IP | `192.168.1.1` |
| `<LAN_SUBNET>` | LAN subnet in CIDR notation | `192.168.1.0/24` |
| `<SNO_IP>` | Static IP to assign the SNO cluster node | `192.168.1.210` (outside DHCP pool) |
| `<LOCAL_DOMAIN>` | pfSense local domain (**System → General Setup → Domain**) | `home.lab` |
| `<CLUSTER_NAME>` | OCP cluster name (used as DNS subdomain) | `sno` |

---

## Reference Architecture

```
pfSense Router (<GATEWAY_IP>)
    └── General LAN (<LAN_SUBNET>)
            ├── Host Machine — <LAN_NIC> → br-lan bridge
            │       └── KVM VM: <CLUSTER_NAME> (<SNO_IP>)
            │               └── OCP SNO Cluster
            └── Other LAN devices (DHCP pool — outside <SNO_IP>)
```

The SNO node IP must be **outside your DHCP pool** to avoid conflicts.
Check your pool range at **Services → DHCP Server → LAN → Range** and pick an IP above or below it.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Host OS | Fedora / RHEL with KVM/libvirt |
| Host RAM | 32 GB minimum, 64 GB+ recommended |
| Host CPU | 8+ cores recommended |
| Host Disk | 250 GB free on `/var/lib/libvirt/images` |
| OCP Version | 4.16–4.18 |
| RH Account | Developer account (free at developers.redhat.com) |
| Pull Secret | Downloaded from console.redhat.com |

---

## Part 1 — Host Preparation

### 1.1 Install KVM and supporting tools

```bash
sudo dnf install -y \
  qemu-kvm \
  libvirt \
  libvirt-daemon-kvm \
  virt-install \
  virt-manager \
  bridge-utils \
  NetworkManager \
  nmstate

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm $(whoami)
# Log out and back in for group changes to take effect
```

### 1.2 Find your LAN NIC name

```bash
ip link show
# Look for the interface connected to your LAN (e.g. enp8s0, eno1, eth0)
# This becomes <LAN_NIC> throughout this guide
```

### 1.3 Create a Linux bridge over `<LAN_NIC>`

This allows the VM to appear directly on your LAN with its own IP rather than sitting behind libvirt NAT.

> **Warning**: The step that takes down `<LAN_NIC>` will briefly drop your LAN connection.
> Run from a **local terminal** (not SSH), or have IPMI/iDRAC access ready.

```bash
# Create the bridge
sudo nmcli con add type bridge con-name br-lan ifname br-lan autoconnect yes

# Set static IP on the bridge (host machine keeps same LAN IP)
sudo nmcli con modify br-lan \
  ipv4.method manual \
  ipv4.addresses "<HOST_IP>/24" \
  ipv4.gateway "<GATEWAY_IP>" \
  ipv4.dns "<GATEWAY_IP>" \
  ipv4.dns-search "<LOCAL_DOMAIN>" \
  bridge.stp no

# Enslave <LAN_NIC> to the bridge
sudo nmcli con add type bridge-slave con-name br-lan-slave ifname <LAN_NIC> master br-lan autoconnect yes

# Bring up the bridge (brief LAN outage — run locally)
sudo nmcli con down "Wired connection 1" 2>/dev/null || sudo nmcli con down <LAN_NIC> 2>/dev/null
sudo nmcli con up br-lan
sudo nmcli con up br-lan-slave
```

Verify the bridge is up:

```bash
ip addr show br-lan
# Should show <HOST_IP>/24

bridge link show
# Should show <LAN_NIC> as a slave of br-lan

resolvectl status br-lan
# Should show DNS Server: <GATEWAY_IP> and DNS Domain: <LOCAL_DOMAIN>
```

> **Note on search domain**: If `resolvectl status br-lan` does not show `DNS Domain: <LOCAL_DOMAIN>`,
> your Linux workstation is not receiving the domain from pfSense. This is common when using a static
> IP rather than DHCP. The `ipv4.dns-search` setting in the `nmcli` command above fixes this.
> Also confirm **Services → DHCP Server → LAN → Domain Name** is set to `<LOCAL_DOMAIN>` in pfSense
> so that DHCP clients also receive the search domain automatically.

---

## Part 2 — pfSense Configuration

### 2.1 DHCP Static Mapping

Prevents pfSense from assigning `<SNO_IP>` to any other device.

1. Go to **Services → DHCP Server → LAN**
2. Confirm the **Domain Name** field is set to `<LOCAL_DOMAIN>`
3. Scroll to **Static Mappings** → click **Add**
4. Fill in:
   - **MAC Address**: `52:54:00:c0:ff:ee` *(the MAC we will assign the VM — memorable QEMU prefix)*
   - **IP Address**: `<SNO_IP>`
   - **Hostname**: `<CLUSTER_NAME>`
5. Save and Apply

### 2.2 DNS Host Overrides

> **pfSense DNS Resolver note**: The **Host** field must not contain dots. pfSense concatenates
> `<Host>.<Domain>` to form the FQDN. The subdomain part of the cluster name goes into **Domain**.

1. Go to **Services → DNS Resolver → Host Overrides** → click **Add** for each row:

| Host | Domain | IP Address | Resulting FQDN |
|------|--------|------------|----------------|
| `api` | `<CLUSTER_NAME>.<LOCAL_DOMAIN>` | `<SNO_IP>` | `api.<CLUSTER_NAME>.<LOCAL_DOMAIN>` |
| `api-int` | `<CLUSTER_NAME>.<LOCAL_DOMAIN>` | `<SNO_IP>` | `api-int.<CLUSTER_NAME>.<LOCAL_DOMAIN>` |

2. Save and Apply

### 2.3 Wildcard DNS for Apps

Required for all OpenShift routes (`*.apps.<CLUSTER_NAME>.<LOCAL_DOMAIN>`).

1. Go to **Services → DNS Resolver → Custom Options**
2. Add (no leading spaces — Unbound is whitespace-sensitive):

```
server:
local-zone: "apps.<CLUSTER_NAME>.<LOCAL_DOMAIN>." redirect
local-data: "apps.<CLUSTER_NAME>.<LOCAL_DOMAIN>. A <SNO_IP>"
```

3. Save and Apply, then restart DNS Resolver

### 2.4 Verify DNS from the host

```bash
nslookup api.<CLUSTER_NAME>.<LOCAL_DOMAIN> <GATEWAY_IP>
nslookup api-int.<CLUSTER_NAME>.<LOCAL_DOMAIN> <GATEWAY_IP>
nslookup console-openshift-console.apps.<CLUSTER_NAME>.<LOCAL_DOMAIN> <GATEWAY_IP>
# All three should return <SNO_IP>
```

All three must resolve correctly before proceeding. The installer will fail at bootstrap if DNS is not working.

---

## Part 3 — Download OpenShift Tools

### 3.1 Get your pull secret

Download from: https://console.redhat.com/openshift/install/pull-secret

Save it to `~/pull-secret.json`.

### 3.2 Download openshift-install and oc CLI

```bash
OCP_VERSION="4.18.0"

curl -L -o /tmp/openshift-install-linux.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz"
tar xf /tmp/openshift-install-linux.tar.gz -C /tmp
sudo mv /tmp/openshift-install /usr/local/bin/
openshift-install version

curl -L -o /tmp/openshift-client-linux.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux.tar.gz"
tar xf /tmp/openshift-client-linux.tar.gz -C /tmp
sudo mv /tmp/oc /usr/local/bin/
oc version --client
```

### 3.3 Generate SSH keypair (if needed)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
```

---

## Part 4 — Build the Agent Installer ISO

### 4.1 Create the install directory

```bash
mkdir -p ~/sno-install
cd ~/sno-install
```

### 4.2 Create install-config.yaml

Replace the `YOUR_*` placeholders and the `<*>` placeholders before saving.

```yaml
apiVersion: v1
baseDomain: <LOCAL_DOMAIN>
metadata:
  name: <CLUSTER_NAME>
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: <LAN_SUBNET>
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 1
  hyperthreading: Enabled
platform:
  none: {}
pullSecret: 'YOUR_PULL_SECRET'
sshKey: 'YOUR_SSH_PUBLIC_KEY'
```

### 4.3 Create agent-config.yaml

```yaml
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: <CLUSTER_NAME>
rendezvousIP: <SNO_IP>
hosts:
- hostname: <CLUSTER_NAME>
  interfaces:
  - name: enp1s0
    macAddress: 52:54:00:c0:ff:ee
  networkConfig:
    interfaces:
    - name: enp1s0
      type: ethernet
      state: up
      ipv4:
        enabled: true
        address:
        - ip: <SNO_IP>
          prefix-length: 24
        dhcp: false
    dns-resolver:
      config:
        server:
        - <GATEWAY_IP>
    routes:
      config:
      - destination: 0.0.0.0/0
        next-hop-address: <GATEWAY_IP>
        next-hop-interface: enp1s0
```

> **Note on NIC name inside the VM**: virtio NICs in KVM VMs typically appear as `enp1s0`.
> If the install fails at networking, open the VNC console and run `ip link show` to check
> the actual name, then update `agent-config.yaml` and regenerate the ISO.

### 4.4 Generate the ISO

```bash
cd ~/sno-install
openshift-install agent create image
# Output: ~/sno-install/agent.x86_64.iso

sudo cp ~/sno-install/agent.x86_64.iso /var/lib/libvirt/images/agent-sno.iso
```

---

## Part 5 — Create and Boot the VM

### 5.1 Create the VM disk

```bash
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/sno.qcow2 200G
```

### 5.2 Install the VM

```bash
sudo virt-install \
  --name sno \
  --ram 32768 \
  --vcpus 16 \
  --disk path=/var/lib/libvirt/images/sno.qcow2,format=qcow2,bus=virtio \
  --disk path=/var/lib/libvirt/images/agent-sno.iso,device=cdrom \
  --network bridge=br-lan,mac=52:54:00:c0:ff:ee,model=virtio \
  --boot uefi,hd,cdrom \
  --os-variant rhel9.0 \
  --graphics vnc,listen=127.0.0.1,port=5910 \
  --noautoconsole \
  --import
```

### 5.3 Open VNC console (optional)

```bash
# Forward VNC port from the host to your local workstation
ssh -L 5910:127.0.0.1:5910 user@<HOST_IP>
# Then connect any VNC viewer to localhost:5910
```

Or use `virt-manager` for a GUI console.

---

## Part 6 — Monitor Installation

```bash
cd ~/sno-install

# Phase 1: Bootstrap (10–20 min)
openshift-install agent wait-for bootstrap-complete --log-level=info

# Phase 2: Full install (30–60 min more)
openshift-install agent wait-for install-complete --log-level=info
```

When complete you will see:

```
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run:
     export KUBECONFIG=/home/user/sno-install/auth/kubeconfig
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.<CLUSTER_NAME>.<LOCAL_DOMAIN>
INFO Login to the console with user: kubeadmin, and password: XXXXX-XXXXX-XXXXX-XXXXX
```

---

## Part 7 — Post-Install Verification

```bash
export KUBECONFIG=~/sno-install/auth/kubeconfig

oc get clusterversion
oc get clusteroperators
oc get nodes

# Check for any non-running pods
oc get pods -A | grep -v Running | grep -v Completed
```

Expected node output for a healthy SNO:

```
NAME              STATUS   ROLES                         AGE   VERSION
<CLUSTER_NAME>    Ready    control-plane,master,worker   1h    v1.31.x
```

---

## Part 8 — Bootstrap ArgoCD + Operators Installer

Once the cluster is healthy, follow the operators-installer example guide at:
`argo/examples/examples/operators-installer/README.md`

Quick bootstrap:

```bash
# Install OpenShift GitOps operator (bootstraps ArgoCD)
oc apply -f argo/examples/examples/operators-installer/argocd/operators-root-app.yaml

# Apply custom ArgoCD health check for Manual-approval Subscriptions
oc apply -f argo/examples/examples/operators-installer/argocd/argocd-cm-subscription-health.yaml
```

---

## Troubleshooting

### VM cannot reach the gateway

- Verify bridge: `bridge link show` — `<LAN_NIC>` should appear as a slave of `br-lan`
- Verify the VM MAC matches pfSense static mapping: `sudo virsh domiflist sno`
- Verify pfSense DHCP static mapping is saved and applied

### DNS not resolving

```bash
# Test directly against pfSense DNS
nslookup api.<CLUSTER_NAME>.<LOCAL_DOMAIN> <GATEWAY_IP>

# Check host resolver config
resolvectl status br-lan
```

- Confirm Custom Options in pfSense DNS Resolver have no leading spaces before `server:`
- Restart DNS Resolver in pfSense after any changes

### Search domain not working on the host

```bash
# Check if the domain appears as a search domain
resolvectl status br-lan | grep "DNS Domain"

# If missing, add it manually
sudo nmcli con modify br-lan ipv4.dns-search "<LOCAL_DOMAIN>"
sudo nmcli con up br-lan
```

Note: `.local` domains resolve via mDNS (Avahi) regardless of DNS config — custom local domain names
require the search domain to be explicitly configured.

### Installation stalls at bootstrap

```bash
# SSH into the node once it has an IP
ssh core@<SNO_IP>

sudo journalctl -u bootkube -f
sudo journalctl -u kubelet -f
```

### Wrong NIC name inside VM

```bash
# Connect via VNC and check
ip link show
# If different from enp1s0, update agent-config.yaml and regenerate the ISO
```

### VM boots from disk instead of ISO

```bash
sudo virsh destroy sno
sudo virsh start sno
# Quickly open VNC and press F12 for boot menu, then select CDROM
```

---

## Cleanup

```bash
# Remove the VM
sudo virsh destroy sno
sudo virsh undefine sno --nvram
sudo rm /var/lib/libvirt/images/sno.qcow2
sudo rm /var/lib/libvirt/images/agent-sno.iso

# Remove the bridge and restore <LAN_NIC> to direct LAN
sudo nmcli con down br-lan
sudo nmcli con delete br-lan
sudo nmcli con delete br-lan-slave
sudo nmcli con up "Wired connection 1" 2>/dev/null || sudo nmcli con up <LAN_NIC> 2>/dev/null
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Check VM status | `sudo virsh list --all` |
| Start VM | `sudo virsh start sno` |
| Graceful stop | `sudo virsh shutdown sno` |
| Force stop | `sudo virsh destroy sno` |
| Serial console | `sudo virsh console sno` (Ctrl+] to exit) |
| Check cluster | `oc get clusterversion` |
| Watch operators | `watch oc get clusteroperators` |
| kubeadmin password | `cat ~/sno-install/auth/kubeadmin-password` |
| Web console | `https://console-openshift-console.apps.<CLUSTER_NAME>.<LOCAL_DOMAIN>` |
