# CSR Management - Quick Reference Card

## 🚀 **Most Common Commands**

### View CSRs

```bash
# List all CSRs
oc get csr

# Show only pending
oc get csr | grep Pending

# Show with details
oc get csr -o wide

# Describe specific CSR
oc describe csr <csr-name>
```

### Approve CSRs

```bash
# Approve single CSR
oc adm certificate approve <csr-name>

# Approve all pending (SAFE - only approves pending)
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

# Approve CSRs from specific node
oc get csr -o json | jq -r --arg node "system:node:master-1" '.items[] | select(.status == {}) | select(.spec.username == $node) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
```

---

## 📋 **One-Liners**

### Safe Approval (Pending Only)

```bash
# The safest command - only approves CSRs without status
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

### View Pending with Details

```bash
# Show pending CSRs with requestor info
oc get csr -o json | jq -r '.items[] | select(.status == {}) | "\(.metadata.name) - \(.spec.username)"'
```

### Count Pending

```bash
# How many CSRs are pending?
oc get csr -o json | jq '[.items[] | select(.status == {})] | length'
```

### Check If CSR Was Approved

```bash
# Check status of specific CSR
oc get csr <csr-name> -o jsonpath='{.status.conditions[0].type}'
```

---

## 🛠️ **Scripts Available**

### Interactive Approval

```bash
# Approve with confirmation
./approve-all-pending.sh
```

### Node-Specific Approval

```bash
# Approve only CSRs from master-1
./approve-by-node.sh master-1
```

### Auto-Approval Monitor

```bash
# Watch and auto-approve (check every 30s)
./watch-and-approve.sh 30
```

---

## 🔍 **Troubleshooting**

### No CSRs Appearing

```bash
# On the node - check kubelet
oc debug node/<node-name>
chroot /host
journalctl -u kubelet | grep -i csr

# Check if kubelet can create CSRs
oc auth can-i create certificatesigningrequests --as=system:node:<node-name>
```

### CSRs Stuck Pending

```bash
# Check auto-approver
oc get pods -n openshift-cluster-machine-approver

# Check your permissions
oc auth can-i approve certificatesigningrequests
```

### Verify Certificate Issued

```bash
# Check if CSR got a certificate
oc get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d | openssl x509 -text -noout
```

---

## ⚠️ **Safety Checks**

### Before Approving

```bash
# 1. Check requestor
oc get csr <csr-name> -o jsonpath='{.spec.username}'

# 2. Check if node exists
NODE=$(oc get csr <csr-name> -o jsonpath='{.spec.username}' | sed 's/system:node://')
oc get node $NODE

# 3. View certificate request details
oc get csr <csr-name> -o jsonpath='{.spec.request}' | base64 -d | openssl req -text -noout
```

### Audit Recent Approvals

```bash
# Who approved what
oc get events --all-namespaces | grep -i "certificate.*approved"

# Recent CSRs and their status
oc get csr --sort-by=.metadata.creationTimestamp | tail -20
```

---

## 📊 **Common Patterns**

### After Adding Node

```bash
# 1. Check for CSR
oc get csr | grep <node-name>

# 2. Approve
oc adm certificate approve <csr-name>

# 3. Verify node joined
oc get node <node-name>
```

### After Certificate Rotation

```bash
# Approve all node certificate renewals
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

### During Cluster Recovery

```bash
# Watch for CSRs and approve in real-time
watch -n 10 'oc get csr && echo "" && oc get csr -o go-template="{{range .items}}{{if not .status}}{{.metadata.name}}{{\"\\n\"}}{{end}}{{end}}" | xargs --no-run-if-empty oc adm certificate approve'
```

---

## 🎯 **Decision Tree**

```
CSR appears
    ↓
Check requestor (spec.username)
    ↓
    ├─ system:node:<node-name>
    │  ├─ Node exists? → APPROVE
    │  └─ Node unknown? → INVESTIGATE
    │
    ├─ system:serviceaccount:...:node-bootstrapper
    │  └─ New node joining? → APPROVE
    │
    └─ Unknown requestor → DO NOT APPROVE
```

---

## 📞 **Emergency Commands**

### Bulk Delete Old CSRs

```bash
# Delete CSRs older than 1 day
oc get csr -o json | jq -r --arg date "$(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" '.items[] | select(.metadata.creationTimestamp < $date) | .metadata.name' | xargs --no-run-if-empty oc delete csr
```

### Force Node Certificate Refresh

```bash
# On the node
systemctl stop kubelet
rm -f /var/lib/kubelet/pki/kubelet-client*.pem
systemctl start kubelet

# Then approve the new CSR
oc get csr | grep <node-name>
oc adm certificate approve <csr-name>
```

---

## 💡 **Pro Tips**

1. **Always use `--no-run-if-empty`** with xargs to avoid errors when no CSRs are pending

2. **Check requestor before approving** - Never blindly approve unknown requestors

3. **Use jq for complex filtering** - More reliable than grep for JSON

4. **Monitor during maintenance windows** - Use watch-and-approve.sh

5. **Audit regularly** - Check who approved what and when

---

## 🔗 **Related Commands**

### Check Node Certificate Expiry

```bash
# On the node
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout | grep -A 2 Validity
```

### Check Certificate Rotation Config

```bash
# On the node
grep -i rotate /var/lib/kubelet/config.yaml
```

### View All Certificates

```bash
# All secrets containing certificates
oc get secrets --all-namespaces -o json | jq -r '.items[] | select(.type == "kubernetes.io/tls") | "\(.metadata.namespace)/\(.metadata.name)"'
```

---

## 🚨 **Emergency Scenarios**

### All Nodes NotReady - Circular Dependency

**Symptoms:**
- All nodes NotReady
- `system:anonymous` errors
- CSRs approved but no certificate issued
- Network operator healthy but no CNI config

**Quick Check:**
```bash
# Check the pattern
oc get nodes  # All NotReady?
oc get co network  # Available=True?
oc get co kube-controller-manager  # Degraded=True?
oc debug node/master-0 -- chroot /host ls /etc/kubernetes/cni/net.d/  # No CNI config?
```

**Emergency Fix (Sequential, one node at a time):**
```bash
# On master-0 ONLY (never all at once!)
oc debug node/master-0
chroot /host

# Backup first
BACKUP_DIR="/root/kubelet-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR
cp -a /var/lib/kubelet/kubeconfig $BACKUP_DIR/
cp -a /var/lib/kubelet/pki/ $BACKUP_DIR/

# Apply localhost.kubeconfig bootstrap
systemctl stop kubelet
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig
rm -f /var/lib/kubelet/pki/kubelet-client*.pem
systemctl start kubelet

# Wait for node Ready (3-5 minutes)
# Then repeat for master-2, finally master-1
```

See [REAL-WORLD-EXAMPLES.md Example 12](REAL-WORLD-EXAMPLES.md) for full details.

### CSR Approved But No Certificate

**Check if certificate was issued:**
```bash
oc get csr <csr-name> -o jsonpath='{.status.certificate}' | base64 -d
# Empty = not signed despite approval
```

**Check controller-manager:**
```bash
oc get co kube-controller-manager
# If Degraded=True, fix controller-manager first
```

### CSR Approval Hangs From Bastion

**Symptom:** `oc adm certificate approve` times out or shows "http2: client connection lost"

**Fix:** Work from master node with local API access
```bash
oc debug node/master-0
chroot /host
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Now commands work instantly
oc get csr
oc adm certificate approve <csr-name>
```

---

**For detailed documentation, see:** [README.md](README.md)  
**Scripts location:** `/ocp-troubleshooting/csr-management/`





