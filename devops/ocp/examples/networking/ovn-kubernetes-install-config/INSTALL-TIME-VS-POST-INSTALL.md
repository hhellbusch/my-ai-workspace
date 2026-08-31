---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# Install-Time vs Post-Installation Configuration

**Freeze vs thaw:** [install-config-immutability.md](../../../notes/install-config-immutability.md) is the catalog of what stays frozen.
This page is about **whether a field appears in the installer schema**, which is a different question.

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

The following fields were **not** in the OKD 4.18 install-config schema table we checked.
That does **not** mean they are all Day-2. Freeze/thaw is in the catalog.

Day-2 (CNO / product chapters): masquerade, transit, `routingViaHost`, IPsec, policy audit, overlay **MTU migration**.

**Frozen** after install: `genevePort` (set at install if 6081 conflicts). Overlay MTU is not a raw field patch.

---

## Comparison Table

| Parameter | Install-Time Support | Post-Install Support | Requires Disruption |
|-----------|---------------------|---------------------|---------------------|
| `ipv4.internalJoinSubnet` | ✅ Documented | ✅ Yes | ⚠️ OVN pod restart |
| `ipv6.internalJoinSubnet` | ✅ Documented | ✅ Yes | ⚠️ OVN pod restart |
| `gatewayConfig.ipv4.internalMasqueradeSubnet` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `gatewayConfig.ipv4.internalTransitSwitchSubnet` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `mtu` | ❓ Not documented | ⚠️ Migration only (not a raw `mtu` patch) | 🔴 Node reboot |
| `genevePort` | ❓ Not documented | **No** (CNO rejects) | — |
| `gatewayConfig.routingViaHost` | ❓ Not documented | ✅ Yes | ⚠️ OVN pod restart |
| `ipsecConfig.mode` | ❓ Not documented | ✅ Yes | ⚠️ MTU drop for ESP |
| `policyAuditConfig` | ❓ Not documented | ✅ Yes | ✅ No disruption |

**Legend:**
- ✅ = Supported/Documented
- ❓ = Not in schema documentation
- ⚠️ = Brief disruption (~30 seconds)
- 🔴 = Requires node reboot

---

## Recommended Approach

### Option 1: Post-Installation Configuration (Recommended)

**This is the documented method for join / transit / masquerade, IPsec, and related CNO fields.**
Do **not** use it for `genevePort` (CNO rejects). Overlay MTU uses the migration chapter, not a raw `mtu` patch.

**Steps:**
1. Install OpenShift with default OVN-Kubernetes settings
2. After installation completes, configure custom subnets via Day 2 operations
3. Use `oc patch network.operator.openshift.io cluster` to apply configuration

**Advantages:**
- ✅ Officially documented by Red Hat for join/transit/masquerade
- ✅ Can test defaults first, then customize those internals
- ✅ Can be performed anytime after installation
- ❌ Does not apply to `genevePort`

**Example:**
```bash
# After installation, configure OVN internal subnets (join / masquerade / transit)
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

**A:** They may work, but schema silence is not support. `genevePort` **must** be set at install if you need a non-default port — CNO rejects later changes. Overlay MTU after install is a **migration**, not a raw field. Join/transit/masquerade/IPsec are Day-2.

### Q: Why does the installer accept other parameters if they're not documented?

**A:** The installer may parse and accept additional parameters, but Red Hat's official documentation only covers `internalJoinSubnet` for install-time configuration. Undocumented behavior should not be relied upon for production deployments.

### Q: Can I change internalJoinSubnet after installation?

**A:** Yes, but it requires OVN pod restart and can take up to 30 minutes to propagate. The official documentation states "You cannot change the value after installation" in the install-config.yaml context, but it can be changed via the network operator.

### Q: What's the safest approach?

**A:** For production:
1. Install with default settings or configure only `internalJoinSubnet` at install time if needed
2. After installation, use `oc patch network.operator.openshift.io cluster` for join/transit/masquerade and IPsec as needed
3. Do not patch `genevePort`. Overlay MTU: migration chapter, not a raw `mtu` patch.
4. Freeze/thaw: [install-config-immutability.md](../../../notes/install-config-immutability.md)

---

## Conclusion

**For Production Deployments:**
- ✅ Join/transit/masquerade and IPsec have documented Day-2 patches
- ❌ `genevePort` is frozen (CNO `isOVNKubernetesChangeSafe`)
- ⚠️ Overlay MTU: [migration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html-single/advanced_networking/index) — chapter 2, *Advanced networking*

**For Install-Time Configuration:**
- Set `internalJoinSubnet` at install if the default `100.64.0.0/16` collides (also Day-2 if you miss it)
- Set `genevePort` at install if 6081 conflicts — you cannot change it later

**Last Updated:** 2026-08-31 (freeze/thaw aligned with CNO release-4.20 + OCP 4.20 catalog; schema hunt dated 2026-02-02 / OKD 4.18)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
