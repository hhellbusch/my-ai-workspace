# OVN-Kubernetes Install Configuration - Documentation Index

Complete guide for configuring OVN-Kubernetes networking at OpenShift install time.

## Quick Navigation

### 🚀 Getting Started
- **New to OVN-Kubernetes?** → Start with [README.md](./README.md)
- **Need quick config?** → Go to [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Need complete examples?** → See [EXAMPLES.md](./EXAMPLES.md)
- **Just installed?** → Follow [VERIFICATION.md](./VERIFICATION.md)

### 📄 Documentation Files

| File | Purpose | When to Use |
|------|---------|-------------|
| [README.md](./README.md) | Complete reference guide | Understanding all configuration options |
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Quick copy-paste configs | Need a working config fast |
| [EXAMPLES.md](./EXAMPLES.md) | Complete install-config.yaml examples | Platform-specific configurations |
| [VERIFICATION.md](./VERIFICATION.md) | Post-install verification | After installation completes |
| [install-config-template.yaml](./install-config-template.yaml) | Annotated template | Starting a new configuration |
| [INDEX.md](./INDEX.md) | This file - documentation index | Finding what you need |

---

## Documentation Structure

### README.md - Complete Reference Guide
**Size:** ~1000 lines | **Read Time:** 30-45 minutes

**Contents:**
- Overview of OVN-Kubernetes configuration
- Complete parameter reference with descriptions
- Network subnet planning and requirements
- Common configuration scenarios
- Pre-installation checklist
- Troubleshooting guide

**Use this when:**
- You need to understand what each parameter does
- Planning network architecture
- Troubleshooting configuration issues
- Learning OVN-Kubernetes networking

**Key Sections:**
- Configuration Parameters (all options explained)
- Network Subnet Planning (avoiding overlaps)
- Common Scenarios (with explanations)
- Troubleshooting (fixing common issues)

---

### QUICK-REFERENCE.md - Fast Solutions
**Size:** ~800 lines | **Read Time:** 10-15 minutes

**Contents:**
- Quick copy-paste configurations
- Minimal configs for common scenarios
- Verification commands
- Quick fixes for common issues
- Pre-installation validation checklist

**Use this when:**
- You know what you want to configure
- Need a working config immediately
- Want verification commands
- Need to fix a specific issue quickly

**Scenarios Covered:**
- Minimal configuration (defaults)
- Custom internal subnets
- IPsec encryption
- Jumbo frames
- Custom Geneve port
- Dual stack (IPv4+IPv6)

---

### EXAMPLES.md - Complete Configurations
**Size:** ~1200 lines | **Read Time:** 20-30 minutes

**Contents:**
- Complete install-config.yaml examples
- Platform-specific configurations (Bare Metal, vSphere, AWS, Azure)
- Production-ready examples
- Cluster topology variations

**Use this when:**
- Starting a new installation
- Need platform-specific config
- Want a complete, working example
- Comparing your config to a reference

**Examples Included:**
1. Bare Metal with Custom OVN Subnets
2. Bare Metal with IPsec Encryption
3. VMware vSphere with Jumbo Frames
4. AWS with Custom OVN Configuration
5. Bare Metal Dual Stack (IPv4+IPv6)
6. Bare Metal Compact Cluster (3 nodes)

---

### VERIFICATION.md - Post-Install Testing
**Size:** ~1100 lines | **Read Time:** 25-35 minutes

**Contents:**
- Comprehensive verification procedures
- Step-by-step testing guide
- Functional tests for all networking components
- Performance validation
- Troubleshooting failed verification

**Use this when:**
- Installation just completed
- Validating configuration changes
- Troubleshooting network issues
- Performance testing

**Verification Steps:**
1. Quick verification (5 minutes)
2. Network operator status
3. OVN pod verification
4. Configuration verification
5. Node-level verification
6. Functional testing (pod-to-pod, external)
7. IPsec verification (if enabled)
8. Performance validation

---

### install-config-template.yaml - Annotated Template
**Size:** ~500 lines | **Read Time:** 15-20 minutes

**Contents:**
- Complete install-config.yaml template
- Inline comments for every option
- Pre-installation checklist
- Post-installation commands

**Use this when:**
- Creating a new install-config.yaml from scratch
- Understanding what each field does
- Need a starting point with all options

**Features:**
- Every parameter documented inline
- Common values provided
- Alternative options shown
- Pre-flight checklist included

---

## Quick Decision Tree

### "What should I read?"

```
START
  │
  ├─ Installing OpenShift for first time?
  │    └─> Read: README.md (overview)
  │        Then: install-config-template.yaml (create config)
  │        Then: EXAMPLES.md (compare to examples)
  │        Then: VERIFICATION.md (after install)
  │
  ├─ Already know what to configure?
  │    └─> Read: QUICK-REFERENCE.md
  │        Copy appropriate section
  │
  ├─ Need a complete example for your platform?
  │    └─> Read: EXAMPLES.md
  │        Find matching scenario
  │
  ├─ Just finished installation?
  │    └─> Read: VERIFICATION.md
  │        Run all verification steps
  │
  ├─ Having network issues?
  │    └─> Read: README.md#troubleshooting
  │        Or: VERIFICATION.md#troubleshooting-failed-verification
  │
  └─ Need to understand specific parameter?
       └─> Read: README.md#configuration-parameters
           Or: install-config-template.yaml (inline comments)
```

---

## Common Use Cases

### Use Case 1: First Time Installation

**Path:**
1. Read [README.md](./README.md) - Overview and concepts (30 min)
2. Copy [install-config-template.yaml](./install-config-template.yaml) (5 min)
3. Customize based on your environment (20 min)
4. Compare with [EXAMPLES.md](./EXAMPLES.md) (10 min)
5. Validate with pre-install checklist (10 min)
6. Run installation (60-90 min)
7. Verify with [VERIFICATION.md](./VERIFICATION.md) (30 min)

**Total Time:** ~3-4 hours

---

### Use Case 2: Quick Installation (Know What You Want)

**Path:**
1. Open [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) (2 min)
2. Copy relevant configuration section (3 min)
3. Customize network CIDRs (5 min)
4. Run pre-installation validation (5 min)
5. Run installation (60-90 min)
6. Quick verification (5 min)

**Total Time:** ~1.5-2 hours

---

### Use Case 3: Troubleshooting Existing Cluster

**Path:**
1. Check symptoms in [README.md#troubleshooting](./README.md#troubleshooting) (10 min)
2. Run verification commands from [VERIFICATION.md](./VERIFICATION.md) (20 min)
3. Compare your config with [EXAMPLES.md](./EXAMPLES.md) (10 min)
4. Fix issues using [QUICK-REFERENCE.md#common-issues-and-quick-fixes](./QUICK-REFERENCE.md#common-issues-and-quick-fixes) (varies)

**Total Time:** Variable depending on issue

---

### Use Case 4: Learning OVN-Kubernetes

**Path:**
1. Read [README.md#overview](./README.md#overview) (10 min)
2. Study [README.md#network-subnet-planning](./README.md#network-subnet-planning) (20 min)
3. Review [README.md#configuration-parameters](./README.md#configuration-parameters) (20 min)
4. Study scenarios in [README.md#common-scenarios](./README.md#common-scenarios) (20 min)
5. Review complete examples in [EXAMPLES.md](./EXAMPLES.md) (30 min)
6. Understand verification in [VERIFICATION.md](./VERIFICATION.md) (30 min)

**Total Time:** ~2 hours

---

## Configuration Complexity Levels

### Level 1: Basic (Default Configuration)
**Time:** 15 minutes  
**File:** [QUICK-REFERENCE.md#minimal-configuration](./QUICK-REFERENCE.md#minimal-configuration)

Use OVN-Kubernetes with all defaults:
- Standard MTU (1400)
- Default internal subnets
- No encryption
- No special features

**Good for:**
- Lab environments
- Learning
- Simple deployments
- Networks with no conflicts

---

### Level 2: Custom Subnets (Recommended)
**Time:** 30 minutes  
**File:** [QUICK-REFERENCE.md#custom-internal-subnets-recommended](./QUICK-REFERENCE.md#custom-internal-subnets-recommended)

Customize OVN internal subnets:
- Custom join subnet
- Custom transit subnet
- Larger masquerade subnet

**Good for:**
- Production environments
- Networks with RFC 6598 conflicts
- Avoiding network overlaps
- **This is the recommended production configuration**

---

### Level 3: Advanced Features
**Time:** 45-60 minutes  
**File:** [README.md#common-scenarios](./README.md#common-scenarios)

Add advanced features:
- IPsec encryption
- Custom MTU (jumbo frames)
- Custom Geneve port
- Network policy auditing

**Good for:**
- Security-sensitive environments
- High-performance requirements
- Compliance requirements
- Custom network setups

---

### Level 4: Complex (Dual Stack)
**Time:** 90+ minutes  
**File:** [EXAMPLES.md#example-5-bare-metal-dual-stack-ipv4ipv6](./EXAMPLES.md#example-5-bare-metal-dual-stack-ipv4ipv6)

Full dual stack IPv4+IPv6:
- Both IPv4 and IPv6 networks
- Dual stack services
- IPv6 routing

**Good for:**
- IPv6 requirements
- Future-proofing
- Modern network environments
- Advanced users only

---

## Configuration Parameters Quick Reference

### Parameters You MUST Configure
- `machineNetwork` - Your physical network CIDR
- `platform.baremetal.apiVIP` - API server VIP (bare metal only)
- `platform.baremetal.ingressVIP` - Ingress VIP (bare metal only)
- `pullSecret` - Red Hat pull secret
- `sshKey` - SSH public key

### Parameters You SHOULD Configure
- `ipv4.internalJoinSubnet` - Avoid default conflicts
- `gatewayConfig.ipv4.internalTransitSwitchSubnet` - Avoid default conflicts
- `gatewayConfig.ipv4.internalMasqueradeSubnet` - Size for your cluster

### Parameters You MAY Configure
- `mtu` - Only if using jumbo frames or specific requirements
- `genevePort` - Only if port 6081 conflicts
- `ipsecConfig.mode` - Only if encryption required
- `policyAuditConfig` - Only if audit logging needed

### Parameters That Can Change Post-Install
- `ipsecConfig.mode` ✅
- `policyAuditConfig.*` ✅

### Parameters That CANNOT Change Post-Install
- `mtu` ❌
- `genevePort` ❌
- `ipv4.internalJoinSubnet` ❌
- `gatewayConfig.ipv4.*` ❌

---

## Verification Checklist

After installation, verify these in order:

### Quick Check (5 minutes)
- [ ] All cluster operators available
- [ ] Network operator not degraded
- [ ] All OVN pods running
- [ ] All nodes ready

**Commands:** [VERIFICATION.md#quick-verification](./VERIFICATION.md#quick-verification)

### Configuration Check (10 minutes)
- [ ] Network type is OVNKubernetes
- [ ] Internal subnets configured correctly
- [ ] MTU configured correctly
- [ ] Geneve port configured correctly

**Commands:** [VERIFICATION.md#configuration-verification](./VERIFICATION.md#configuration-verification)

### Functional Check (15 minutes)
- [ ] Pod-to-pod communication works
- [ ] Pod-to-service communication works
- [ ] External connectivity works
- [ ] DNS resolution works

**Commands:** [VERIFICATION.md#functional-testing](./VERIFICATION.md#functional-testing)

---

## Getting Help

### For Configuration Questions
- Read: [README.md](./README.md)
- Check: [EXAMPLES.md](./EXAMPLES.md)
- Template: [install-config-template.yaml](./install-config-template.yaml)

### For Installation Issues
- Quick fixes: [QUICK-REFERENCE.md#common-issues-and-quick-fixes](./QUICK-REFERENCE.md#common-issues-and-quick-fixes)
- Detailed troubleshooting: [README.md#troubleshooting](./README.md#troubleshooting)

### For Post-Install Issues
- Verification: [VERIFICATION.md](./VERIFICATION.md)
- Troubleshooting: [VERIFICATION.md#troubleshooting-failed-verification](./VERIFICATION.md#troubleshooting-failed-verification)

### External Resources
- [Red Hat OpenShift Documentation](https://docs.openshift.com/container-platform/latest/networking/ovn_kubernetes_network_provider/about-ovn-kubernetes.html)
- [OVN-Kubernetes GitHub](https://github.com/ovn-org/ovn-kubernetes)
- Red Hat Support Portal (for customers)

---

## Document Maintenance

**Last Updated:** 2026-02-02  
**Tested Versions:** OpenShift 4.14, 4.15, 4.16, 4.17, 4.18  
**Next Review:** 2026-06-02

### Change History
- 2026-02-02: Initial documentation creation
  - Complete reference guide
  - Quick reference for common scenarios
  - Full examples for all platforms
  - Comprehensive verification procedures
  - Annotated template file

---

## Quick Links Summary

| What I Need | File to Read | Estimated Time |
|-------------|--------------|----------------|
| Learn the basics | [README.md](./README.md) | 30-45 min |
| Quick config | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | 10-15 min |
| Complete example | [EXAMPLES.md](./EXAMPLES.md) | 20-30 min |
| Verify installation | [VERIFICATION.md](./VERIFICATION.md) | 25-35 min |
| Start from scratch | [install-config-template.yaml](./install-config-template.yaml) | 15-20 min |

**Total documentation size:** ~4,800 lines  
**Complete read time:** ~2-3 hours  
**Practical read time:** 15-45 minutes (targeted sections)

---

**Start here:** [README.md](./README.md)

