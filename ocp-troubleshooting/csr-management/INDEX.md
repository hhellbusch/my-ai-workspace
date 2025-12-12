# CSR Management Documentation Index

Quick navigation for Certificate Signing Request troubleshooting in OpenShift.

---

## 📚 **Documentation Structure**

### [README.md](README.md) - Main Documentation
Comprehensive guide covering:
- CSR basics and lifecycle
- Viewing and approving CSRs
- Filtering and automation
- Security considerations
- **NEW:** Circular dependency scenarios
- **NEW:** CSRs approved but not signed troubleshooting
- **NEW:** Emergency bootstrap procedures

### [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Quick Commands
Fast reference for:
- Most common commands
- One-liners
- Troubleshooting patterns
- Decision trees
- **NEW:** Emergency scenarios (all nodes NotReady)
- **NEW:** CSR approval hangs workarounds

### [REAL-WORLD-EXAMPLES.md](REAL-WORLD-EXAMPLES.md) - Field Experience
Real troubleshooting sessions including:
- Examples 1-11: Various CSR scenarios
- **NEW Example 12:** All control plane nodes NotReady - circular dependency recovery
- **NEW Example 13:** CSR approval hanging from bastion

---

## 🚨 **Start Here Based on Your Situation**

### Scenario 1: Pending CSRs Need Approval

**Quick Answer:**
```bash
# Safe approval of all pending
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

📖 **Read:** [README.md - Approving CSRs](README.md#approving-csrs)

---

### Scenario 2: CSR Approval Hangs/Times Out

**Symptoms:**
- `oc adm certificate approve` hangs
- "http2: client connection lost" errors
- Commands timeout from bastion

**Quick Answer:**
```bash
# Work from master node with local API
oc debug node/master-0
chroot /host
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc adm certificate approve <csr-name>
```

📖 **Read:** 
- [QUICK-REFERENCE.md - CSR Approval Hangs](QUICK-REFERENCE.md#csr-approval-hangs-from-bastion)
- [REAL-WORLD-EXAMPLES.md - Example 4 & 13](REAL-WORLD-EXAMPLES.md#example-4-csr-approval-during-remote-api-failure)

---

### Scenario 3: All Nodes NotReady (Critical!)

**Symptoms:**
- All control plane nodes show NotReady
- `system:anonymous` errors in kubelet logs
- Network operator shows Available=True but no CNI config
- Controller-manager degraded

**Quick Check:**
```bash
oc get nodes  # All NotReady?
oc get co network  # Available=True?
oc get co kube-controller-manager  # Degraded=True?
```

**This is a circular dependency scenario!**

📖 **Read Immediately:**
- [REAL-WORLD-EXAMPLES.md - Example 12](REAL-WORLD-EXAMPLES.md#example-12-all-control-plane-nodes-notready---circular-dependency-recovery)
- [README.md - Circular Dependency](README.md#circular-dependency-kubelet-auth--csr--networking)
- [QUICK-REFERENCE.md - Emergency Scenarios](QUICK-REFERENCE.md#emergency-scenarios)

⚠️ **Critical:** Never reboot all control plane nodes simultaneously!

---

### Scenario 4: CSRs Approved But Not Signed

**Symptoms:**
- CSR shows "Approved" status
- But kubelet still reports authentication errors
- Certificate not issued

**Quick Check:**
```bash
# Check if certificate was issued
oc get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d
# Empty output = not signed
```

**Common Cause:** kube-controller-manager degraded

📖 **Read:**
- [README.md - CSRs Approved But Certificate Not Issued](README.md#csrs-approved-but-certificate-not-issued)
- [REAL-WORLD-EXAMPLES.md - Example 12](REAL-WORLD-EXAMPLES.md#example-12-all-control-plane-nodes-notready---circular-dependency-recovery)

---

### Scenario 5: Node Can't Create CSR

**Symptoms:**
- No CSRs appearing for node
- `system:anonymous` errors
- Kubelet can't authenticate to create CSR

**Common Cause:** Bootstrap tokens missing

**Quick Check:**
```bash
oc debug node/<node-name>
chroot /host
ls /etc/kubernetes/bootstrap-secrets/kubeconfig
# If missing, bootstrap tokens are gone
```

📖 **Read:**
- [README.md - CSRs Not Being Created](README.md#csrs-not-being-created)
- [REAL-WORLD-EXAMPLES.md - Example 1 & 7](REAL-WORLD-EXAMPLES.md#example-1-kubelet-authentication-failure-after-etcd-recovery)

---

### Scenario 6: Routine CSR Approval After Node Addition

**Symptoms:**
- New node joining cluster
- CSRs appearing from node-bootstrapper

**Quick Answer:**
```bash
# Verify requestor is legitimate
oc get csr <csr-name> -o jsonpath='{.spec.username}'

# Approve
oc adm certificate approve <csr-name>
```

📖 **Read:**
- [README.md - Scenario 1: Node Bootstrap](README.md#scenario-1-node-bootstrap)
- [REAL-WORLD-EXAMPLES.md - Example 3](REAL-WORLD-EXAMPLES.md#example-3-new-node-addition)

---

### Scenario 7: Certificate Rotation Issues

**Symptoms:**
- Certificates expired
- Automatic rotation not working

**Quick Check:**
```bash
# Check rotation enabled
oc debug node/<node-name> -- chroot /host grep rotateCertificates /var/lib/kubelet/config.yaml

# Check certificate expiry
oc debug node/<node-name> -- chroot /host openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -enddate
```

📖 **Read:**
- [README.md - Certificate Rotation Not Working](README.md#certificate-rotation-not-working)
- [REAL-WORLD-EXAMPLES.md - Example 2](REAL-WORLD-EXAMPLES.md#example-2-multiple-nodes-after-maintenance-window)

---

## 🛠️ **Available Scripts**

Located in: `/ocp-troubleshooting/csr-management/`

- `approve-all-pending.sh` - Interactive approval of pending CSRs
- `approve-by-node.sh` - Approve CSRs for specific node
- `watch-and-approve.sh` - Continuous monitoring and auto-approval

📖 **Usage:** See [README.md - Automated Approval](README.md#automated-approval)

---

## 🔍 **Diagnostic Commands**

### Quick Health Check
```bash
# View all CSRs
oc get csr

# Check only pending
oc get csr | grep Pending

# Check cluster operators
oc get co kube-controller-manager
oc get co network

# Check all nodes
oc get nodes
```

### Deep Dive
```bash
# Check if CSR was signed
oc get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d

# Check kubelet authentication
oc debug node/<node-name> -- chroot /host journalctl -u kubelet -n 50 | grep -i "anonymous\|forbidden"

# Check CNI config
oc debug node/<node-name> -- chroot /host ls -la /etc/kubernetes/cni/net.d/

# Check bootstrap secrets
oc debug node/<node-name> -- chroot /host ls /etc/kubernetes/bootstrap-secrets/
```

---

## 📖 **Learning Path**

### New to CSRs?
1. Start: [README.md - Understanding CSRs](README.md#understanding-csrs)
2. Then: [README.md - Viewing CSRs](README.md#viewing-csrs)
3. Then: [README.md - Approving CSRs](README.md#approving-csrs)
4. Practice: [REAL-WORLD-EXAMPLES.md](REAL-WORLD-EXAMPLES.md)

### Troubleshooting Active Issue?
1. Match your scenario above
2. Follow quick answer
3. Read detailed documentation if needed

### Want Reference Commands?
- Use: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

---

## 🆕 **What's New (December 2025)**

### New Content Added
- **Circular dependency scenarios** (all nodes NotReady)
- **CSRs approved but not signed** troubleshooting
- **Emergency bootstrap procedures** using localhost.kubeconfig
- **Sequential recovery** for multi-node control plane
- **Controller-manager degradation** impact on CSR signing
- **Container/kubelet desync** scenarios

### New Examples
- **Example 12:** All nodes NotReady - complete recovery procedure
- **Example 13:** CSR approval hanging workarounds

### Enhanced Sections
- Troubleshooting section expanded
- Security considerations updated
- Emergency scenarios quick reference

---

## 📞 **Related Documentation**

- [bare-metal-node-inspection-timeout/](../bare-metal-node-inspection-timeout/) - CSR issues during node provisioning
- [kube-controller-manager-crashloop/](../kube-controller-manager-crashloop/) - Controller manager issues affecting CSR signing

---

**Last Updated:** December 9, 2025  
**Tested On:** OpenShift 4.18.14

