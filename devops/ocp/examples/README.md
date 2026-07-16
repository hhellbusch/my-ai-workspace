---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# OpenShift Configuration Examples

Configuration examples and templates for OpenShift clusters.

## Available Examples

### Bare metal / secondary disk

- **[Secondary disk offload (overview)](bare-metal-secondary-disk/README.md)** — What to move off the OS disk, patterns A–D, `by-path`, 14 TiB layout, use-case index
  - **Use cases:** [index](bare-metal-secondary-disk/use-cases/README.md) · [application PV](bare-metal-secondary-disk/use-cases/application-pv.md) · [CSI pools](bare-metal-secondary-disk/use-cases/csi-raw-disks.md) · [etcd](bare-metal-secondary-disk/use-cases/etcd-master.md) · [registry](bare-metal-secondary-disk/use-cases/disconnected-registry.md) · [container storage](bare-metal-secondary-disk/use-cases/container-storage.md)
- **[`/var/log` on secondary disk (complete)](bare-metal-var-log-disk/README.md)** — Ignition vs script + systemd `MachineConfig` side by side
  - [approach-a-ignition.yaml](bare-metal-var-log-disk/approach-a-ignition.yaml) · [approach-b-script-systemd.yaml](bare-metal-var-log-disk/approach-b-script-systemd.yaml)

### Lab / SNO

- **[SNO on KVM](sno-kvm-lab/README.md)** — Single Node OpenShift home-lab (pfSense DNS, agent installer, ArgoCD bootstrap)
  - **[Dynamic storage (active — HPP)](sno-kvm-lab/dynamic-storage.md)** — end-to-end reproduction guide
  - **[Internal image registry](sno-kvm-lab/image-registry-sno-lab.md)** — post-storage step for DevSpaces (`openshift/cli`)
  - **[Local storage (bootstrap, retired)](sno-kvm-lab/local-storage.md)** — static Local Storage history + host disk attach
  - **Manifests:** [hpp-vdb-mount.yaml](sno-kvm-lab/hpp-vdb-mount.yaml), [hpp.yaml](sno-kvm-lab/hpp.yaml), [storage-smoke-test.yaml](sno-kvm-lab/storage-smoke-test.yaml), [lvms.yaml](sno-kvm-lab/lvms.yaml)

### Data / messaging

- **[Kafka on bare-metal OpenShift with Portworx](kafka-bare-metal-portworx/README.md)** — Rack-aware example for **OCP 4.20+** (Confluent CFK primary; Strimzi/AMQ comparison; Portworx CSI)
  - **[VALIDATION.md](kafka-bare-metal-portworx/VALIDATION.md)** — static review status and cluster-side apply checklist
  - **[Common manifests](kafka-bare-metal-portworx/manifests/common/)** — StorageClass (CSI + legacy), optional kernel tuning, CFK RBAC
  - **[LABELING-COMPARISON.md](kafka-bare-metal-portworx/LABELING-COMPARISON.md)** — zone/region vs custom-rack; Confluent vs Strimzi
  - **[zone-region manifests](kafka-bare-metal-portworx/manifests/zone-region/)** · **[custom-rack manifests](kafka-bare-metal-portworx/manifests/custom-rack/)** — each includes `confluent/` and `strimzi/`

### Networking

- **[NetworkAttachmentDefinition (NAD)](network-attachment-definitions/README.md)** - Configure additional networks and VLANs for pods
  - **[Quick Reference](network-attachment-definitions/QUICK-REFERENCE.md)** - Fast commands for NAD creation and pod attachment ⚡
  - VLAN configuration with macvlan, bridge, SR-IOV
  - IPAM strategies: static, DHCP, whereabouts
  - Multiple network interfaces per pod
  - Complete troubleshooting guide
  - Real-world examples with toolbox containers

- **[OVN-Kubernetes Install Config](ovn-kubernetes-install-config/README.md)** - OpenShift install-config.yaml for OVN-Kubernetes networking
  - [Quick Reference](ovn-kubernetes-install-config/QUICK-REFERENCE.md) - Essential configuration snippets
  - [Examples](ovn-kubernetes-install-config/EXAMPLES.md) - Real-world configurations
  - [Index](ovn-kubernetes-install-config/INDEX.md) - Guide navigation
  - MTU configuration for overlay networks
  - Hybrid networking examples

## Using These Examples

Each example follows this structure:

1. **Overview** - What the configuration is and when to use it
2. **Quick Start** - Fast copy-paste commands to get started
3. **Detailed Configuration** - Complete explanation of all options
4. **Examples** - Real-world use cases with complete configurations
5. **Troubleshooting** - Common issues and solutions
6. **Best Practices** - Recommendations and tips

## Quick Reference

### NetworkAttachmentDefinition (NAD/VLAN)

```bash
# Create VLAN NAD
cat <<EOF | oc apply -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vlan100
spec:
  config: |
    {
      "type": "macvlan",
      "master": "ens3",
      "vlan": 100,
      "ipam": {"type": "static"}
    }
EOF

# Attach pod to VLAN
oc run my-pod \
  --image=ubi:latest \
  --annotations='k8s.v1.cni.cncf.io/networks=vlan100'
```

See: [network-attachment-definitions/](network-attachment-definitions/)

### OVN-Kubernetes MTU

```yaml
networking:
  networkType: OVNKubernetes
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  machineNetwork:
  - cidr: 192.168.0.0/16
```

See: [ovn-kubernetes-install-config/](ovn-kubernetes-install-config/)

## Related Documentation

### Troubleshooting Guides

- [Debug Toolbox Container](../troubleshooting/debug-toolbox-container/README.md) - Use with NADs for VLAN testing
- [AAP SSH MTU Issues](../troubleshooting/aap-ssh-mtu-issues/README.md) - MTU troubleshooting
- [CoreOS Networking](../troubleshooting/coreos-networking-issues/README.md) - Node-level network issues

### Other Examples

- [Ansible Examples](../../ansible/examples/) - Automation and playbooks
- [ArgoCD Examples](../../argo/examples/) - GitOps configurations
- [RHACM Examples](../../rhacm/examples/) - Multi-cluster management

## Contributing

When adding new examples:

1. Create a dedicated directory for the example
2. Include a comprehensive README.md
3. Add a QUICK-REFERENCE.md for fast lookups
4. Provide real-world examples
5. Include troubleshooting section
6. Update this main README

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
