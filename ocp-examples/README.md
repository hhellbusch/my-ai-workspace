# OpenShift Configuration Examples

Configuration examples and templates for OpenShift clusters.

## Available Examples

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

- [Debug Toolbox Container](../ocp-troubleshooting/debug-toolbox-container/README.md) - Use with NADs for VLAN testing
- [AAP SSH MTU Issues](../ocp-troubleshooting/aap-ssh-mtu-issues/README.md) - MTU troubleshooting
- [CoreOS Networking](../ocp-troubleshooting/coreos-networking-issues/README.md) - Node-level network issues

### Other Examples

- [Ansible Examples](../ansible-examples/) - Automation and playbooks
- [ArgoCD Examples](../argo-examples/) - GitOps configurations
- [RHACM Examples](../rhacm-examples/) - Multi-cluster management

## Contributing

These examples are part of a personal knowledge base. When adding new examples:

1. Create a dedicated directory for the example
2. Include a comprehensive README.md
3. Add a QUICK-REFERENCE.md for fast lookups
4. Provide real-world examples
5. Include troubleshooting section
6. Update this main README

---

**AI Disclosure:** This documentation was created with AI assistance to provide comprehensive OpenShift configuration examples.
