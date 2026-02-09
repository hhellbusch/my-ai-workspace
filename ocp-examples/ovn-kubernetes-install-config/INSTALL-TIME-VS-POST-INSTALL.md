# Install-Time vs Post-Installation Configuration

## Summary of Schema Verification

**Verification Date:** 2026-02-02  
**Source:** [OKD 4.18 Installation Configuration Parameters](https://docs.okd.io/4.18/installing/installing_bare_metal/upi/installation-config-parameters-bare-metal.html)

---

## Key Finding

Red Hat's official install-config.yaml schema documentation **only explicitly documents ONE parameter** for OVN-Kubernetes install-time configuration:

### ✅ Officially Documented for Install-Time

```yaml
networking:
  ovnKubernetesConfig:
    ipv4:
      internalJoinSubnet: 100.64.0.0/16
```

**From Official Documentation:**
> "Configures the IPv4 join subnet that is used internally by ovn-kubernetes. This subnet must not overlap with any other subnet that OKD is using, including the node network. The size of the subnet must be larger than the number of nodes. You cannot change the value after installation."

**Default:** `100.64.0.0/16`

---

## ❓ Not in Install-Config.yaml Schema Documentation

The following parameters are **documented for post-installation Day 2 operations** but are **NOT** explicitly listed in the install-config.yaml schema reference:

### Gateway Configuration
- `gatewayConfig.ipv4.internalMasqueradeSubnet`
- `gatewayConfig.ipv4.internalTransitSwitchSubnet`
- `gatewayConfig.routingViaHost`

### Top-Level Parameters
- `mtu`
- `genevePort`

### Security Configuration
- `ipsecConfig.mode`

### Audit Configuration
- `policyAuditConfig.*`

---

## Comparison Table

| Parameter | Install-Time Support | Post-Install Support | Requires Disruption |
|-----------|---------------------|---------------------|---------------------|
| `ipv4.internalJoinSubnet` | ✅ Documented | ✅ Yes | ⚠️ OVN pod restart |
| `ipv6.internalJoinSubnet` | ✅ Documented | ✅ Yes | ⚠️ OVN pod restart |
| `gatewayConfig.ipv4.internalMasqueradeSubnet` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `gatewayConfig.ipv4.internalTransitSwitchSubnet` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `gatewayConfig.routingViaHost` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `mtu` | ❓ Not documented | ✅ Yes | 🔴 Node reboot |
| `genevePort` | ❓ Not documented | ✅ Yes | 🔴 Node reboot |
| `ipsecConfig.mode` | ❓ Not documented | ✅ Yes | ✅ No disruption |
| `policyAuditConfig` | ❓ Not documented | ✅ Yes | ✅ No disruption |

**Legend:**
- ✅ = Supported/Documented
- ❓ = Not in schema documentation
- ⚠️ = Brief disruption (~30 seconds)
- 🔴 = Requires node reboot

---

## Recommended Approach

### Option 1: Post-Installation Configuration (Recommended)

**This is the officially documented method for all parameters except internalJoinSubnet.**

**Steps:**
1. Install OpenShift with default OVN-Kubernetes settings
2. After installation completes, configure custom subnets via Day 2 operations
3. Use `oc patch network.operator.openshift.io cluster` to apply configuration

**Advantages:**
- ✅ Officially documented by Red Hat
- ✅ All parameters supported
- ✅ Can test defaults first, then customize
- ✅ Can be performed anytime after installation

**Example:**
```bash
# After installation, configure all OVN subnets
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "ipv4": {
          "internalJoinSubnet": "10.245.0.0/16"
        },
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.0.0/17",
            "internalTransitSwitchSubnet": "10.246.0.0/16"
          }
        }
      }
    }
  }
}'
```

---

### Option 2: Install-Time Configuration (Limited)

**Only internalJoinSubnet is officially documented for install-time configuration.**

**Use When:**
- You need to set `internalJoinSubnet` before first boot
- Default 100.64.0.0/16 conflicts with existing infrastructure
- You cannot perform Day 2 operations immediately after install

**Install-config.yaml Example:**
```yaml
networking:
  networkType: OVNKubernetes
  ovnKubernetesConfig:
    ipv4:
      internalJoinSubnet: 10.245.0.0/16  # ✅ Officially documented
    # Other parameters not in schema docs - use post-install method
```

**Then Configure Remaining Parameters Post-Install:**
```bash
# After installation, configure gateway parameters
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.0.0/17",
            "internalTransitSwitchSubnet": "10.246.0.0/16"
          }
        }
      }
    }
  }
}'
```

---

## Official Documentation References

### Install-Time Configuration
- [OKD 4.18 Installation Configuration Parameters](https://docs.okd.io/4.18/installing/installing_bare_metal/upi/installation-config-parameters-bare-metal.html)
  - Documents `networking.ovnKubernetesConfig.ipv4.internalJoinSubnet` in install-config.yaml schema

### Post-Installation Configuration
- [Configuring OVN-Kubernetes Subnets (OpenShift 4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets)
- [Configuring OVN-Kubernetes Subnets (OpenShift 4.17)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/ovn-kubernetes_network_plugin/configure-ovn-kubernetes-subnets)
- [Cluster Network Operator (OpenShift 4.15)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/networking/cluster-network-operator)

---

## FAQ

### Q: Can I configure all parameters at install time in install-config.yaml?

**A:** Only `ipv4.internalJoinSubnet` is officially documented in the install-config.yaml schema. Other parameters should be configured post-installation using the officially documented method.

### Q: Will parameters not in the schema documentation work if I add them to install-config.yaml?

**A:** They may work, but it's not documented or officially supported. The recommended approach is to use post-installation configuration for all parameters except `internalJoinSubnet`.

### Q: Why does the installer accept other parameters if they're not documented?

**A:** The installer may parse and accept additional parameters, but Red Hat's official documentation only covers `internalJoinSubnet` for install-time configuration. Undocumented behavior should not be relied upon for production deployments.

### Q: Can I change internalJoinSubnet after installation?

**A:** Yes, but it requires OVN pod restart and can take up to 30 minutes to propagate. The official documentation states "You cannot change the value after installation" in the install-config.yaml context, but it can be changed via the network operator.

### Q: What's the safest approach?

**A:** For production:
1. Install with default settings or configure only `internalJoinSubnet` at install time if needed
2. After installation, use `oc patch network.operator.openshift.io cluster` to configure all other parameters
3. This follows Red Hat's officially documented procedures

---

## Conclusion

**For Production Deployments:**
- ✅ Use post-installation configuration as your primary method
- ✅ This is the officially documented and supported approach
- ✅ Allows validation with defaults before customization
- ✅ Follows Red Hat's best practices

**For Install-Time Configuration:**
- ✅ Only use for `internalJoinSubnet` if you must configure it before first boot
- ⚠️ All other parameters should be configured post-installation

---

**Last Updated:** 2026-02-02  
**Verified Against:** OKD 4.18 / OpenShift 4.18 Official Documentation
