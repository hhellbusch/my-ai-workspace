# Quick Reference: Control Plane Kubeconfigs

## One-Line Commands

### Set Kubeconfig and Watch Cluster Operators

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig && oc get co -w
```

### Check All Cluster Operators Status

```bash
oc --kubeconfig=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig get co
```

### Show Only Unhealthy Operators

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig && oc get co | grep -v "True.*False.*False"
```

## Kubeconfig Paths (Copy-Paste Ready)

### Primary Kubeconfig (Localhost)

```bash
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

### Load Balancer Kubeconfig

```bash
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-ext.kubeconfig
```

### Kubelet Kubeconfig

```bash
/etc/kubernetes/kubeconfig
```

## Essential Commands

### Export Kubeconfig (Required First Step)

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
```

### Watch Cluster Operators

```bash
oc get co -w                    # Live watch
watch -n 2 'oc get co'         # Refresh every 2 seconds
```

### Get Specific Operator Details

```bash
oc get co <operator-name> -o yaml
oc describe co <operator-name>
```

### List All Operators with Status

```bash
oc get co -o wide
```

### Check Nodes

```bash
oc get nodes
oc get nodes -o wide
```

### Check Cluster Version

```bash
oc get clusterversion
oc get clusterversion -o json | jq '.items[0].status.conditions'
```

## Quick Health Check

```bash
# Set kubeconfig
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

# Check API health
curl -k https://localhost:6443/healthz

# Check cluster operators
oc get co

# Check nodes
oc get nodes

# Check cluster version
oc get clusterversion
```

## Installation Monitoring One-Liner

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig && watch -n 5 'echo "=== Nodes ===" && oc get nodes && echo "" && echo "=== Cluster Operators ===" && oc get co && echo "" && echo "=== Cluster Version ===" && oc get clusterversion'
```

## Troubleshooting Commands

### Check if API Server is Running

```bash
crictl pods | grep kube-apiserver
crictl ps | grep kube-apiserver
```

### View API Server Logs

```bash
crictl logs $(crictl ps --name kube-apiserver -q)
```

### Verify Kubeconfig Exists

```bash
ls -la /etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/
```

### Test API Connectivity

```bash
curl -k https://localhost:6443/healthz
curl -k https://localhost:6443/readyz
```

## Filtering Operators

### Show Only Available Operators

```bash
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Available" and .status=="True")) | .metadata.name'
```

### Show Only Degraded Operators

```bash
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Degraded" and .status=="True")) | .metadata.name'
```

### Show Operators Not Progressing

```bash
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select(.type=="Progressing" and .status=="False")) | .metadata.name'
```

### Show All Unhealthy Operators

```bash
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True") or (.type=="Progressing" and .status=="True" and .reason!="AsExpected"))) | .metadata.name' | sort -u
```

## Common Operator Names

```
authentication
baremetal
cloud-controller-manager
cloud-credential
cluster-autoscaler
config-operator
console
csi-snapshot-controller
dns
etcd
image-registry
ingress
insights
kube-apiserver
kube-controller-manager
kube-scheduler
kube-storage-version-migrator
machine-api
machine-approver
machine-config
marketplace
monitoring
network
node-tuning
openshift-apiserver
openshift-controller-manager
openshift-samples
operator-lifecycle-manager
operator-lifecycle-manager-catalog
operator-lifecycle-manager-packageserver
service-ca
storage
```

## Watch Specific Operators

```bash
# Watch etcd operator
oc get co etcd -w

# Watch kube-apiserver operator
oc get co kube-apiserver -w

# Watch all control plane operators
watch 'oc get co | grep -E "(etcd|kube-apiserver|kube-controller-manager|kube-scheduler)"'
```

## Comprehensive Status Check

```bash
#!/bin/bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig

echo "=== Cluster Version ==="
oc get clusterversion
echo ""

echo "=== Nodes ==="
oc get nodes
echo ""

echo "=== Cluster Operators ==="
oc get co
echo ""

echo "=== Problematic Operators ==="
oc get co -o json | jq -r '.items[] | select(.status.conditions[] | select((.type=="Available" and .status=="False") or (.type=="Degraded" and .status=="True"))) | .metadata.name' | sort -u || echo "None found"
echo ""

echo "=== API Server Health ==="
curl -k https://localhost:6443/healthz
echo ""
```

## Tips

1. **Always export KUBECONFIG first** or use `--kubeconfig` flag with every command
2. **Use `-w` flag** to watch resources update in real-time
3. **Use `watch` command** for continuous monitoring with a refresh interval
4. **During installation**, operators will gradually become Available
5. **Some operators depend on others** - order matters during installation
6. **etcd, kube-apiserver, kube-controller-manager, kube-scheduler** are critical and should come up first

