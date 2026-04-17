# Certificate Signing Request (CSR) Management in OpenShift

## Overview

Certificate Signing Requests (CSRs) are how nodes and components in OpenShift request new certificates from the cluster's certificate authority. Understanding how to manage CSRs is critical for cluster operations, especially during:
- Node additions
- Certificate rotation
- Kubelet authentication issues
- Control plane recovery

## 🚨 Emergency Quick Actions - Start Here

**If you have pending CSRs blocking node joins or certificate rotation:**

```bash
# 1. Check pending CSRs (10 seconds)
oc get csr | grep Pending

# 2. View details of pending CSRs
oc get csr -o custom-columns=NAME:.metadata.name,REQUESTOR:.spec.username,AGE:.metadata.creationTimestamp

# 3. Quick approval for known nodes (CAUTION: Verify requestor first!)
# List the requestors to verify they're legitimate
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.spec.username}} - {{.metadata.name}}{{"\n"}}{{end}}{{end}}'

# 4. If requestors are legitimate (system:node:* or node-bootstrapper), approve all
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

**Common scenarios:**

- **New node joining**: Approve CSRs from `system:serviceaccount:openshift-machine-config-operator:node-bootstrapper`
- **Certificate rotation**: Approve CSRs from `system:node:<node-name>` where node-name is a known node
- **Multiple pending after maintenance**: Approve all if during planned maintenance window

**Verify approval worked:**
```bash
# Check all CSRs are now approved
oc get csr | grep -c Approved

# Check nodes are Ready
oc get nodes
```

**⚠️ Security Warning**: Only approve CSRs from known requestors. If you see suspicious requestors, investigate before approving!

---

## 📋 **Table of Contents**

1. [Understanding CSRs](#understanding-csrs)
2. [Viewing CSRs](#viewing-csrs)
3. [Approving CSRs](#approving-csrs)
4. [Filtering and Selective Approval](#filtering-and-selective-approval)
5. [Automated Approval](#automated-approval)
6. [Troubleshooting CSR Issues](#troubleshooting-csr-issues)
7. [Security Considerations](#security-considerations)

---

## Understanding CSRs

### What Are CSRs?

Certificate Signing Requests are used in OpenShift for:
- **Node bootstrap** - New nodes request certificates to join the cluster
- **Certificate rotation** - Nodes request renewed certificates before expiry
- **Kubelet client certificates** - Authentication to API server
- **Kubelet serving certificates** - For serving kubelet API

### CSR Lifecycle

```
1. Component creates a CSR
   ↓
2. CSR submitted to Kubernetes API
   ↓
3. CSR appears in Pending state
   ↓
4. Admin or auto-approver approves CSR
   ↓
5. Certificate issued and stored in CSR status
   ↓
6. Component retrieves signed certificate
   ↓
7. CSR marked as Approved
```

### CSR Types

**Node Bootstrap CSRs:**
- Used when nodes first join the cluster
- Username: `system:serviceaccount:openshift-machine-config-operator:node-bootstrapper`
- Auto-approved in most cases

**Kubelet Client CSRs:**
- For kubelet to authenticate to API server
- Username: `system:node:<node-name>`
- Should be approved if node is legitimate

**Kubelet Serving CSRs:**
- For kubelet's HTTPS endpoint
- Used for metrics collection, logs, exec
- Usually auto-approved after client cert approved

---

## Viewing CSRs

### Basic Viewing

```bash
# List all CSRs
oc get csr

# Output shows:
# NAME        AGE   SIGNERNAME                            REQUESTOR         CONDITION
# csr-xxxxx   10m   kubernetes.io/kube-apiserver-client   system:node:...   Pending
```

### Detailed View

```bash
# Get detailed information about a specific CSR
oc describe csr <csr-name>

# View CSR in YAML format
oc get csr <csr-name> -o yaml

# View all CSRs in YAML
oc get csr -o yaml
```

### Filtering CSRs

```bash
# Show only pending CSRs
oc get csr | grep Pending

# Show only approved CSRs
oc get csr | grep Approved

# Show CSRs for a specific node
oc get csr | grep master-0
```

### Custom Columns

```bash
# Show CSR name, requestor, and status
oc get csr -o custom-columns=NAME:.metadata.name,REQUESTOR:.spec.username,CONDITION:.status.conditions[0].type

# Show with age
oc get csr -o custom-columns=NAME:.metadata.name,AGE:.metadata.creationTimestamp,STATUS:.status.conditions[0].type
```

### Watch for New CSRs

```bash
# Watch for CSRs in real-time
oc get csr -w

# Watch with wider output
oc get csr -o wide -w
```

---

## Approving CSRs

### Approve Single CSR

```bash
# Approve by name
oc adm certificate approve <csr-name>

# Example
oc adm certificate approve csr-8k7mx
```

### Approve Multiple Specific CSRs

```bash
# Approve multiple CSRs by name
oc adm certificate approve csr-abc123 csr-def456 csr-ghi789

# Or using xargs
echo "csr-abc123 csr-def456" | xargs oc adm certificate approve
```

### Approve All Pending CSRs

```bash
# Approve all pending CSRs (be careful!)
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

**Explanation:**
- `.items` - Iterate through all CSRs
- `{{if not .status}}` - Select only CSRs without a status (Pending)
- `{{.metadata.name}}` - Output the CSR name
- `xargs --no-run-if-empty` - Pass names to approve command (skip if empty)

### Interactive Approval

```bash
# View and approve one at a time
for csr in $(oc get csr -o name); do
    echo "CSR: $csr"
    oc get $csr -o yaml | grep -A 5 "username:"
    read -p "Approve? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        oc adm certificate approve $(basename $csr)
    fi
done
```

---

## Filtering and Selective Approval

### Approve CSRs from Specific Node

```bash
# Approve only CSRs from master-0
oc get csr -o go-template='{{range .items}}{{if not .status}}{{if eq .spec.username "system:node:master-0"}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

### Approve Only Kubelet Client CSRs

```bash
# Filter by signer name
oc get csr -o json | jq -r '.items[] | select(.status == {}) | select(.spec.signerName == "kubernetes.io/kube-apiserver-client-kubelet") | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
```

### Approve CSRs from Specific Namespace

```bash
# For service account CSRs from specific namespace
oc get csr -o json | jq -r '.items[] | select(.status == {}) | select(.spec.username | contains("openshift-machine-config-operator")) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
```

### Approve CSRs Matching Pattern

```bash
# Approve CSRs where requestor contains "node"
oc get csr -o json | jq -r '.items[] | select(.status == {}) | select(.spec.username | contains("node")) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
```

### Age-Based Filtering

```bash
# Approve only CSRs older than 5 minutes
FIVE_MIN_AGO=$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%SZ)
oc get csr -o json | jq -r --arg time "$FIVE_MIN_AGO" '.items[] | select(.status == {}) | select(.metadata.creationTimestamp < $time) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
```

---

## Automated Approval

### Check Auto-Approval Status

```bash
# Check if automatic approval is enabled
oc get clusterrolebinding | grep certificate

# Check auto-approver pods
oc get pods -n openshift-cluster-machine-approver
```

### Temporary Auto-Approval Script

```bash
#!/bin/bash
# auto-approve-csrs.sh
# Continuously approve pending CSRs (for maintenance windows)

echo "Starting CSR auto-approval (Ctrl+C to stop)"
while true; do
    PENDING=$(oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}')
    
    if [ -n "$PENDING" ]; then
        echo "$(date): Approving pending CSRs:"
        echo "$PENDING"
        echo "$PENDING" | xargs oc adm certificate approve
    else
        echo "$(date): No pending CSRs"
    fi
    
    sleep 30
done
```

### Conditional Auto-Approval

```bash
#!/bin/bash
# approve-node-csrs.sh
# Only auto-approve CSRs from known nodes

KNOWN_NODES=("master-0" "master-1" "master-2" "worker-0" "worker-1")

while true; do
    for node in "${KNOWN_NODES[@]}"; do
        CSR=$(oc get csr -o json | jq -r --arg node "system:node:$node" '.items[] | select(.status == {}) | select(.spec.username == $node) | .metadata.name')
        
        if [ -n "$CSR" ]; then
            echo "$(date): Approving CSR for $node: $CSR"
            oc adm certificate approve $CSR
        fi
    done
    
    sleep 60
done
```

---

## Troubleshooting CSR Issues

### CSRs Not Being Created

**Check kubelet status:**
```bash
# On the node
oc debug node/<node-name>
chroot /host

# Check kubelet logs
journalctl -u kubelet -n 100 | grep -i "certificate\|csr"

# Check kubelet can reach API server
curl -k https://localhost:6443/healthz
```

**Check if node can authenticate:**
```bash
# Check kubeconfig
cat /var/lib/kubelet/kubeconfig

# Check for bootstrap token or certificate
grep -A 3 "client-certificate\|token" /var/lib/kubelet/kubeconfig
```

### CSRs Stuck in Pending

**Check cluster-machine-approver:**
```bash
# Check if auto-approver is running
oc get pods -n openshift-cluster-machine-approver

# Check logs
oc logs -n openshift-cluster-machine-approver deployment/machine-approver-controller
```

**Check permissions:**
```bash
# Verify you can approve CSRs
oc auth can-i approve certificatesigningrequests

# Should return: yes
```

### CSR Denied

**Check why CSR was denied:**
```bash
# Get CSR details
oc get csr <csr-name> -o yaml

# Look for conditions
oc get csr <csr-name> -o jsonpath='{.status.conditions[*]}' | jq .
```

**Common reasons for denial:**
- Invalid request
- Node not in allowed list
- Security policy violation

### Too Many Pending CSRs

**Bulk cleanup:**
```bash
# Delete old pending CSRs (older than 1 hour)
ONE_HOUR_AGO=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)
oc get csr -o json | jq -r --arg time "$ONE_HOUR_AGO" '.items[] | select(.status == {}) | select(.metadata.creationTimestamp < $time) | .metadata.name' | xargs --no-run-if-empty oc delete csr
```

### Certificate Rotation Not Working

**Check rotation configuration:**
```bash
# On the node
cat /var/lib/kubelet/config.yaml | grep -i rotate

# Should show:
# rotateCertificates: true
```

**Force certificate rotation:**
```bash
# On the node
systemctl stop kubelet
rm -f /var/lib/kubelet/pki/kubelet-client*.pem
systemctl start kubelet

# Then approve the new CSR
```

### CSRs Approved But Certificate Not Issued

**Symptoms:**
- CSR shows "Approved" but no certificate in status
- Kubelet still can't authenticate after approval
- System:anonymous errors persist

**Check if certificate was issued:**
```bash
# Get CSR name
CSR_NAME=<your-csr-name>

# Check for certificate
oc get csr $CSR_NAME -o jsonpath='{.status.certificate}' | base64 -d

# If empty, certificate wasn't issued despite approval
```

**Check controller-manager:**
```bash
# Controller-manager signs certificates
oc get co kube-controller-manager

# If degraded, CSRs won't be signed
oc describe co kube-controller-manager

# Check controller-manager logs (use crictl if oc logs fails)
oc debug node/master-0
chroot /host
CONTROLLER_ID=$(crictl ps | grep kube-controller-manager | awk '{print $1}')
crictl logs $CONTROLLER_ID 2>&1 | tail -100 | grep -i "csr\|sign\|certificate"
```

**Common causes:**
- kube-controller-manager degraded (often due to networking)
- Certificate signer controller not running
- RBAC issues preventing signing
- API server connectivity problems

**Resolution:**
- Fix controller-manager degradation first
- Then delete and recreate CSR
- New CSR should be signed immediately after approval

### Circular Dependency: Kubelet Auth → CSR → Networking

**The Problem:**

```
kubelet needs certificate
    ↓
requires CSR signing
    ↓
requires controller-manager healthy
    ↓
controller-manager needs networking
    ↓
networking needs CNI config
    ↓
CNI config requires kubelet working
    ↓
STUCK - circular dependency
```

**Symptoms:**
- All nodes NotReady
- System:anonymous errors in kubelet
- CSRs approved but not signed
- Network operator healthy but pods can't start
- No CNI config files

**Check for this scenario:**
```bash
# All nodes NotReady?
oc get nodes

# Network operator healthy?
oc get co network  # Should show Available=True

# But no CNI config?
oc debug node/master-0 -- chroot /host ls /etc/kubernetes/cni/net.d/
# Only whereabouts.d/, missing 10-ovn-kubernetes.conf

# Controller-manager degraded?
oc get co kube-controller-manager  # Shows Degraded=True

# Bootstrap secrets missing?
oc debug node/master-0 -- chroot /host ls /etc/kubernetes/bootstrap-secrets/
# Directory doesn't exist
```

**Emergency Bootstrap Solution:**

Use localhost.kubeconfig temporarily to break the cycle:

```bash
# On affected node
oc debug node/master-0
chroot /host

# BACKUP FIRST
BACKUP_DIR="/root/kubelet-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR
cp -a /var/lib/kubelet/kubeconfig $BACKUP_DIR/
cp -a /var/lib/kubelet/pki/ $BACKUP_DIR/

# Apply localhost.kubeconfig
systemctl stop kubelet
cp /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig \
   /var/lib/kubelet/kubeconfig
rm -f /var/lib/kubelet/pki/kubelet-client*.pem
systemctl start kubelet

# Wait 2-3 minutes for pods to start and create CNI config
```

**Important notes:**
- localhost.kubeconfig is a temporary bootstrap solution
- Only use when bootstrap secrets are missing and nodes NotReady
- Apply to one node at a time (never reboot all control plane nodes)
- See REAL-WORLD-EXAMPLES.md Example 12 for full procedure

---

## Security Considerations

### Before Approving CSRs

**Always verify:**

1. **Requestor Identity**
   ```bash
   oc get csr <csr-name> -o jsonpath='{.spec.username}'
   ```

2. **Request Content**
   ```bash
   # Decode and view the certificate request
   oc get csr <csr-name> -o jsonpath='{.spec.request}' | base64 -d | openssl req -text -noout
   ```

3. **Signer Name**
   ```bash
   oc get csr <csr-name> -o jsonpath='{.spec.signerName}'
   ```

4. **Node Existence**
   ```bash
   # If CSR is for system:node:master-3
   oc get node master-3
   ```

### Red Flags

**DO NOT approve if:**
- ❌ Requestor is unknown or suspicious
- ❌ Node name doesn't match expected nodes
- ❌ Certificate request contains unexpected SANs
- ❌ CSR appears during unexpected time (e.g., no maintenance window)
- ❌ Multiple CSRs from same node in short time (possible compromise)

### Audit CSR Approvals

```bash
# View CSR approval history
oc get events --all-namespaces | grep -i "certificate.*approved"

# Check who approved CSRs
oc get csr -o json | jq -r '.items[] | select(.status.conditions[]?.type == "Approved") | "\(.metadata.name) approved by \(.status.conditions[].message)"'
```

---

## Quick Reference

### Most Common Commands

```bash
# View all CSRs
oc get csr

# View only pending
oc get csr | grep Pending

# Approve all pending (use with caution)
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

# Approve specific CSR
oc adm certificate approve <csr-name>

# View CSR details
oc describe csr <csr-name>

# Delete old CSRs
oc delete csr <csr-name>
```

### Decision Tree

```
CSR appears
    ↓
Is requestor recognized?
    ├─ No → INVESTIGATE, do not approve
    └─ Yes → Continue
         ↓
Is node expected to exist?
    ├─ No → INVESTIGATE
    └─ Yes → Continue
         ↓
Is certificate request valid?
    ├─ No → DENY
    └─ Yes → APPROVE
```

---

## Examples from Real Scenarios

### Scenario 1: Node Bootstrap

```bash
# New node joins cluster
# CSR appears:
# NAME: csr-abcd1234
# REQUESTOR: system:serviceaccount:openshift-machine-config-operator:node-bootstrapper

# Verify node is expected
oc get machines -n openshift-machine-api

# If legitimate, approve
oc adm certificate approve csr-abcd1234
```

### Scenario 2: Certificate Rotation

```bash
# Node's certificate expiring
# CSR appears:
# NAME: csr-efgh5678
# REQUESTOR: system:node:worker-0

# Verify node exists
oc get node worker-0

# Check node is Ready
oc get node worker-0 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# If node is legitimate, approve
oc adm certificate approve csr-efgh5678
```

### Scenario 3: Kubelet Authentication Recovery

```bash
# After kubelet authentication fix
# CSR appears from master-1

# Check the CSR
oc get csr | grep master-1

# View details
oc describe csr <csr-for-master-1>

# Verify master-1 is a known node
oc get node master-1

# Approve
oc adm certificate approve <csr-for-master-1>

# Verify certificate was issued
oc get csr <csr-for-master-1> -o jsonpath='{.status.certificate}' | base64 -d | openssl x509 -text -noout
```

### Scenario 4: Multiple Nodes After Maintenance

```bash
# After cluster maintenance, multiple nodes need certificates

# View all pending
oc get csr

# Approve all if maintenance was planned
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

# Verify all nodes are Ready
oc get nodes
```

---

## Related Documentation

- [OpenShift Certificate Management](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/security/certificate_types_descriptions)
- [Kubernetes CSR API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/)
- [Kubelet TLS Bootstrap](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/)

---

## See Also

- [bare-metal-node-inspection-timeout/](../bare-metal-node-inspection-timeout/) - CSR approval during node provisioning
- [kube-controller-manager-crashloop/](../kube-controller-manager-crashloop/) - Control plane certificate issues

---

**Last Updated:** December 3, 2025  
**Tested On:** OpenShift 4.18.14


