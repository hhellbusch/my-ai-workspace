# Example Diagnostic Script Output

This document shows example output from running `diagnostic-script.sh` for different scenarios.

## Scenario 1: Certificate Expiry Issue

```
================================
kube-controller-manager Diagnostics
================================

Output directory: kcm-diagnostics-20250203-143022

▶ Checking Prerequisites
----------------------------------------
✓ oc CLI found
✓ Logged into cluster: https://api.ocp.example.com:6443
✓ jq found

▶ 1. Checking kube-controller-manager Pod Status
----------------------------------------
✗ Pods in CrashLoopBackOff state

▶ 2. Checking Cluster Operator Status
----------------------------------------
✗ Operator status: Available=False, Degraded=True, Progressing=False

▶ 3. Collecting Logs
----------------------------------------
✓ Current logs saved to kcm-diagnostics-20250203-143022/kcm-current.log
✓ Previous logs saved to kcm-diagnostics-20250203-143022/kcm-previous.log

▶ 4. Analyzing Logs for Error Patterns
----------------------------------------
✗ Certificate/TLS errors detected in logs

▶ 5. Checking Control Plane Dependencies
----------------------------------------
Checking etcd...
✓ etcd pods: 3/3 Running
Checking API server...
✓ API server pods: 3/3 Running

▶ 6. Checking Certificates
----------------------------------------
✓ Client certificate secret exists
✗ Certificate has EXPIRED!

▶ 7. Checking Resource Usage
----------------------------------------
Node resources:
NAME                        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master-0.ocp.example.com    1234m        30%    8192Mi          51%
master-1.ocp.example.com    1123m        28%    7890Mi          49%
master-2.ocp.example.com    1345m        33%    8456Mi          52%
✓ Node resource data collected

Checking for OOMKilled...
✓ No OOMKilled status found

▶ 8. Checking Recent Events
----------------------------------------
Recent events (last 10):
5m    Warning   BackOff    pod/kube-controller-manager-master-0   Back-off restarting failed container
5m    Warning   Failed     pod/kube-controller-manager-master-0   Error: certificate expired
...
✓ Events collected

▶ 9. Collecting Configuration
----------------------------------------
✓ Controller manager configuration saved

▶ 10. Summary and Recommendations
----------------------------------------
Detected issues:
CERTIFICATE_ISSUE
CERTIFICATE_EXPIRED

Recommended actions:

3. REGENERATE CERTIFICATES
   Command: oc delete secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager
   Wait 2-5 minutes for automatic regeneration

✗ Action Required: Certificate issue detected - delete secret to regenerate

▶ 11. Creating Diagnostic Archive
----------------------------------------
✓ Diagnostic archive created: kcm-diagnostics-20250203-143022.tar.gz
Archive size: 128K

▶ Diagnostic Complete
----------------------------------------

Diagnostic data saved to: kcm-diagnostics-20250203-143022/
Archive created: kcm-diagnostics-20250203-143022.tar.gz

Next steps:
1. Review kcm-diagnostics-20250203-143022/RECOMMENDATIONS.txt for specific actions
2. Check logs in kcm-diagnostics-20250203-143022/ for detailed error messages
3. Follow troubleshooting guide for your specific issue

2 issue(s) detected - see RECOMMENDATIONS.txt

For support escalation, provide the archive: kcm-diagnostics-20250203-143022.tar.gz
```

### Resolution Steps Taken:

```bash
# Delete the expired certificate
oc delete secret kube-controller-manager-client-cert-key \
  -n openshift-kube-controller-manager

# Monitor recovery (takes 2-5 minutes)
watch oc get pods -n openshift-kube-controller-manager

# Verify cluster operator
oc get co kube-controller-manager
# NAME                      VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE
# kube-controller-manager   4.14.10   True        False         False      2m
```

---

## Scenario 2: etcd Dependency Issue

```
================================
kube-controller-manager Diagnostics
================================

Output directory: kcm-diagnostics-20250203-145533

▶ Checking Prerequisites
----------------------------------------
✓ oc CLI found
✓ Logged into cluster: https://api.ocp.example.com:6443
✓ jq found

▶ 1. Checking kube-controller-manager Pod Status
----------------------------------------
✗ Pods in CrashLoopBackOff state

▶ 2. Checking Cluster Operator Status
----------------------------------------
✗ Operator status: Available=False, Degraded=True, Progressing=False

▶ 3. Collecting Logs
----------------------------------------
✓ Current logs saved to kcm-diagnostics-20250203-145533/kcm-current.log
✓ Previous logs saved to kcm-diagnostics-20250203-145533/kcm-previous.log

▶ 4. Analyzing Logs for Error Patterns
----------------------------------------
✗ Connection/timeout errors detected in logs
✗ etcd/storage errors detected in logs

▶ 5. Checking Control Plane Dependencies
----------------------------------------
Checking etcd...
✗ etcd pods: 1/3 Running - CHECK ETCD FIRST
Checking API server...
✓ API server pods: 3/3 Running

▶ 6. Checking Certificates
----------------------------------------
✓ Client certificate secret exists
✓ Certificate expires: Feb 10 14:30:22 2025 GMT

▶ 7. Checking Resource Usage
----------------------------------------
Node resources:
NAME                        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master-0.ocp.example.com    1234m        30%    8192Mi          51%
master-1.ocp.example.com    1123m        28%    7890Mi          49%
master-2.ocp.example.com    1345m        33%    8456Mi          52%
✓ Node resource data collected

Checking for OOMKilled...
✓ No OOMKilled status found

▶ 8. Checking Recent Events
----------------------------------------
Recent events (last 10):
2m    Warning   Unhealthy   pod/etcd-master-1   Liveness probe failed
2m    Warning   Unhealthy   pod/etcd-master-2   Liveness probe failed
5m    Warning   Failed      pod/kube-controller-manager-master-0   Error: context deadline exceeded
...
✓ Events collected

▶ 9. Collecting Configuration
----------------------------------------
✓ Controller manager configuration saved

▶ 10. Summary and Recommendations
----------------------------------------
Detected issues:
DEPENDENCY_ISSUE_ETCD
CONNECTIVITY_ISSUE
ETCD_ISSUE

Recommended actions:

1. FIX ETCD FIRST - Controller manager depends on etcd
   Command: oc get pods -n openshift-etcd

7. CHECK ETCD HEALTH
   - Verify etcd members: oc get etcd
   - Check etcd logs: oc logs -n openshift-etcd -l app=etcd

✗ Action Required: Fix etcd before addressing controller manager
✗ Action Required: Connectivity issues detected
✗ Action Required: etcd issues detected

▶ 11. Creating Diagnostic Archive
----------------------------------------
✓ Diagnostic archive created: kcm-diagnostics-20250203-145533.tar.gz
Archive size: 145K

▶ Diagnostic Complete
----------------------------------------

Diagnostic data saved to: kcm-diagnostics-20250203-145533/
Archive created: kcm-diagnostics-20250203-145533.tar.gz

Next steps:
1. Review kcm-diagnostics-20250203-145533/RECOMMENDATIONS.txt for specific actions
2. Check logs in kcm-diagnostics-20250203-145533/ for detailed error messages
3. Follow troubleshooting guide for your specific issue

3 issue(s) detected - see RECOMMENDATIONS.txt

For support escalation, provide the archive: kcm-diagnostics-20250203-145533.tar.gz
```

### Resolution Steps:

In this case, you must fix etcd before the controller manager can work:

```bash
# Check etcd status
oc get pods -n openshift-etcd

# Review etcd logs
oc logs -n openshift-etcd etcd-master-1
oc logs -n openshift-etcd etcd-master-2

# After fixing etcd, controller manager should recover automatically
watch oc get pods -n openshift-kube-controller-manager
```

---

## Scenario 3: OOMKilled (Resource Exhaustion)

```
================================
kube-controller-manager Diagnostics
================================

Output directory: kcm-diagnostics-20250203-151245

▶ Checking Prerequisites
----------------------------------------
✓ oc CLI found
✓ Logged into cluster: https://api.ocp.example.com:6443
✓ jq found

▶ 1. Checking kube-controller-manager Pod Status
----------------------------------------
✗ Pods in CrashLoopBackOff state

▶ 2. Checking Cluster Operator Status
----------------------------------------
✗ Operator status: Available=False, Degraded=True, Progressing=False

▶ 3. Collecting Logs
----------------------------------------
✓ Current logs saved to kcm-diagnostics-20250203-151245/kcm-current.log
⚠ No previous logs available (pod may not have crashed yet)

▶ 4. Analyzing Logs for Error Patterns
----------------------------------------
✗ Out of memory errors detected

▶ 5. Checking Control Plane Dependencies
----------------------------------------
Checking etcd...
✓ etcd pods: 3/3 Running
Checking API server...
✓ API server pods: 3/3 Running

▶ 6. Checking Certificates
----------------------------------------
✓ Client certificate secret exists
✓ Certificate expires: Feb 10 14:30:22 2025 GMT

▶ 7. Checking Resource Usage
----------------------------------------
Node resources:
NAME                        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master-0.ocp.example.com    3456m        86%    15234Mi         95%
master-1.ocp.example.com    3123m        78%    14890Mi         93%
master-2.ocp.example.com    3567m        89%    15456Mi         96%
✓ Node resource data collected

Checking for OOMKilled...
✗ Pod was OOMKilled - memory exhaustion detected

▶ 8. Checking Recent Events
----------------------------------------
Recent events (last 10):
1m    Warning   OOMKilled   pod/kube-controller-manager-master-0   Container killed due to OOM
3m    Warning   BackOff     pod/kube-controller-manager-master-0   Back-off restarting failed container
...
✓ Events collected

▶ 9. Collecting Configuration
----------------------------------------
✓ Controller manager configuration saved

▶ 10. Summary and Recommendations
----------------------------------------
Detected issues:
RESOURCE_ISSUE
OOM_KILLED

Recommended actions:

4. ADDRESS RESOURCE CONSTRAINTS
   - Check master node resources: oc adm top nodes
   - May require scaling master nodes (infrastructure change)

✗ Action Required: Resource exhaustion - may need infrastructure scaling

▶ 11. Creating Diagnostic Archive
----------------------------------------
✓ Diagnostic archive created: kcm-diagnostics-20250203-151245.tar.gz
Archive size: 112K

▶ Diagnostic Complete
----------------------------------------

Diagnostic data saved to: kcm-diagnostics-20250203-151245/
Archive created: kcm-diagnostics-20250203-151245.tar.gz

Next steps:
1. Review kcm-diagnostics-20250203-151245/RECOMMENDATIONS.txt for specific actions
2. Check logs in kcm-diagnostics-20250203-151245/ for detailed error messages
3. Follow troubleshooting guide for your specific issue

2 issue(s) detected - see RECOMMENDATIONS.txt

For support escalation, provide the archive: kcm-diagnostics-20250203-151245.tar.gz
```

### Resolution Steps:

This requires infrastructure-level action:

```bash
# Verify master node resources are at capacity
oc adm top nodes

# Check what's consuming memory on master nodes
oc adm node-logs --role=master --path=journal --unit=kubelet

# Options:
# 1. Add more master nodes (recommended for production)
# 2. Increase master node resources (requires infrastructure change)
# 3. Investigate if there's a memory leak or unusual consumption
```

---

## Scenario 4: Healthy Cluster (No Issues)

```
================================
kube-controller-manager Diagnostics
================================

Output directory: kcm-diagnostics-20250203-153015

▶ Checking Prerequisites
----------------------------------------
✓ oc CLI found
✓ Logged into cluster: https://api.ocp.example.com:6443
✓ jq found

▶ 1. Checking kube-controller-manager Pod Status
----------------------------------------
✓ Pods Running with 2 restarts

▶ 2. Checking Cluster Operator Status
----------------------------------------
✓ Operator Available and not Degraded

▶ 3. Collecting Logs
----------------------------------------
✓ Current logs saved to kcm-diagnostics-20250203-153015/kcm-current.log
⚠ No previous logs available (pod may not have crashed yet)

▶ 4. Analyzing Logs for Error Patterns
----------------------------------------

▶ 5. Checking Control Plane Dependencies
----------------------------------------
Checking etcd...
✓ etcd pods: 3/3 Running
Checking API server...
✓ API server pods: 3/3 Running

▶ 6. Checking Certificates
----------------------------------------
✓ Client certificate secret exists
✓ Certificate expires: Feb 10 14:30:22 2025 GMT

▶ 7. Checking Resource Usage
----------------------------------------
Node resources:
NAME                        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
master-0.ocp.example.com    1234m        30%    8192Mi          51%
master-1.ocp.example.com    1123m        28%    7890Mi          49%
master-2.ocp.example.com    1345m        33%    8456Mi          52%
✓ Node resource data collected

Checking for OOMKilled...
✓ No OOMKilled status found

▶ 8. Checking Recent Events
----------------------------------------
Recent events (last 10):
10m   Normal   Created   pod/kube-controller-manager-master-0   Created container kube-controller-manager
10m   Normal   Started   pod/kube-controller-manager-master-0   Started container kube-controller-manager
...
✓ Events collected

▶ 9. Collecting Configuration
----------------------------------------
✓ Controller manager configuration saved

▶ 10. Summary and Recommendations
----------------------------------------
✓ No critical issues detected in automated analysis
However, manual review of logs is recommended:
- Review: kcm-diagnostics-20250203-153015/kcm-previous.log
- Review: kcm-diagnostics-20250203-153015/kcm-current.log

▶ 11. Creating Diagnostic Archive
----------------------------------------
✓ Diagnostic archive created: kcm-diagnostics-20250203-153015.tar.gz
Archive size: 95K

▶ Diagnostic Complete
----------------------------------------

Diagnostic data saved to: kcm-diagnostics-20250203-153015/
Archive created: kcm-diagnostics-20250203-153015.tar.gz

Next steps:
1. Review kcm-diagnostics-20250203-153015/RECOMMENDATIONS.txt for specific actions
2. Check logs in kcm-diagnostics-20250203-153015/ for detailed error messages
3. Follow troubleshooting guide for your specific issue

No automated issues detected - manual review recommended

For support escalation, provide the archive: kcm-diagnostics-20250203-153015.tar.gz
```

---

## Files Created in Diagnostic Directory

Each diagnostic run creates the following files:

```
kcm-diagnostics-YYYYMMDD-HHMMSS/
├── kcm-pods.json                      # Pod details in JSON format
├── kcm-pods.txt                       # Human-readable pod status
├── cluster-operator.json              # Cluster operator status
├── kcm-current.log                    # Current container logs
├── kcm-previous.log                   # Previous (crashed) container logs
├── detected-issues.txt                # List of detected issue types
├── certificate-errors.txt             # Certificate-related errors (if any)
├── connectivity-errors.txt            # Connection errors (if any)
├── oom-errors.txt                     # OOM errors (if any)
├── config-errors.txt                  # Configuration errors (if any)
├── etcd-errors.txt                    # etcd-related errors (if any)
├── webhook-errors.txt                 # Webhook errors (if any)
├── etcd-pods.txt                      # etcd pod status
├── apiserver-pods.txt                 # API server pod status
├── secrets.txt                        # List of secrets
├── certificate-details.txt            # Certificate information
├── certificate-dates.txt              # Certificate validity dates
├── node-resources.txt                 # Node resource usage
├── pod-describe.txt                   # Detailed pod description
├── events.txt                         # Recent events
├── kubecontrollermanager-config.yaml  # Controller manager configuration
└── RECOMMENDATIONS.txt                # Generated recommendations
```

## Using the Diagnostic Output

1. **Quick Assessment**: Look at the console output for color-coded status
2. **Detailed Analysis**: Review the RECOMMENDATIONS.txt file
3. **Deep Dive**: Examine specific log files for your detected issue type
4. **Support Case**: Attach the .tar.gz archive to your support case

## Interpreting Exit Colors

- 🟢 **Green (✓)**: Component is healthy
- 🟡 **Yellow (⚠)**: Warning - may need attention
- 🔴 **Red (✗)**: Critical issue - action required

