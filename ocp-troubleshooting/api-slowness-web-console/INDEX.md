# Index: API Slowness and Web Console Performance Troubleshooting

## Guide Overview

This guide helps diagnose and resolve OpenShift API slowness and web console performance issues.

## Files in This Guide

### 📘 [README.md](README.md)
**Comprehensive troubleshooting guide** - Start here for in-depth analysis

**Contents:**
- Overview and symptoms
- Emergency quick checks
- Quick diagnosis steps
- 8 common root causes with detailed resolution steps
- Step-by-step troubleshooting process
- Emergency recovery procedures
- Data collection for support
- Prevention and best practices
- Performance tuning

**Use when:**
- First-time encountering API slowness
- Need to understand root causes
- Quick fixes haven't worked
- Need detailed resolution procedures
- Building long-term prevention strategy

**Estimated time:** 30-60 minutes for complete troubleshooting

---

### ⚡ [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
**Fast diagnostic commands and decision tree** - For rapid response

**Contents:**
- Emergency first steps (2 minutes)
- Quick decision tree
- Fast diagnostic commands
- Common quick fixes (4 proven fixes)
- Copy-paste command blocks
- One-liner health check
- Monitoring script

**Use when:**
- Need immediate answers
- Production emergency
- Already familiar with the issue
- Need specific commands quickly
- Want to run quick health checks

**Estimated time:** 2-15 minutes

---

### 🔧 [diagnostic-script.sh](diagnostic-script.sh)
**Automated diagnostic tool** - Run comprehensive checks automatically

**Contents:**
- Automated health checks
- Performance measurements
- Resource utilization
- Object counts
- Log analysis
- Structured output with recommendations

**Use when:**
- Need comprehensive data collection
- Want automated analysis
- Preparing for support case
- Need baseline metrics
- Regular health checks

**Usage:**
```bash
chmod +x diagnostic-script.sh
./diagnostic-script.sh
```

**Output:** Detailed report saved to timestamped file

**Estimated time:** 3-5 minutes to run

---

### 🔑 [SERVICE-ACCOUNT-TOKEN-EXPIRY.md](SERVICE-ACCOUNT-TOKEN-EXPIRY.md)
**Specialized guide for token expiry errors** - "service account token has expired"

**Contents:**
- 6 common root causes for token expiry
- Specific diagnostic commands
- Time synchronization checks
- Service CA troubleshooting
- Token controller issues
- Automated diagnostic script

**Use when:**
- Seeing "token has expired" in API logs
- Authentication failures
- Many 401 errors
- Pods unable to reach API

**Companion script:**
```bash
./diagnose-token-expiry.sh
```

**Estimated time:** 15-30 minutes

---

## Quick Navigation by Symptom

### 🐌 Web Console Loading Slowly

1. **Check if it's console-specific or API-wide:**
   ```bash
   time oc get nodes
   ```
   - If fast (<1s): [Console-Specific Issues](#console-specific-flow)
   - If slow (>2s): [API-Wide Issues](#api-wide-flow)

2. **Console-Specific Flow:**
   - Quick Reference → "Scenario 1: Console Slow but CLI Works"
   - README → "Console-Specific Recovery"

3. **API-Wide Flow:**
   - Quick Reference → "Emergency First Steps"
   - README → "Common Root Causes"

---

### ⏱️ API Commands Timing Out

**Immediate action:**
1. Quick Reference → "Emergency First Steps"
2. Check etcd health (most common cause)
3. README → "etcd Performance Issues"

**Decision point:**
- etcd degraded → Fix etcd first
- etcd healthy → Check API server and resources

---

### 📊 High Control Plane Resource Usage

**Immediate action:**
1. Quick Reference → "Check Resources"
2. README → "Control Plane Resource Constraints"

**Quick checks:**
```bash
oc adm top nodes -l node-role.kubernetes.io/master=
oc adm top pods -n openshift-kube-apiserver
oc adm top pods -n openshift-etcd
```

---

### 🔄 Intermittent Slowness

**Diagnosis approach:**
1. Run diagnostic script to capture baseline
2. Monitor during slow periods:
   ```bash
   watch -n 5 'time oc get nodes'
   ```
3. README → "Network Latency Issues" or "High API Request Rate"

---

### 🚨 Production Emergency

**Fastest path to resolution:**

1. **Minute 1-2:** Quick Reference → "Emergency First Steps"
   ```bash
   time oc get nodes
   oc get co kube-apiserver etcd
   ```

2. **Minute 3-5:** Apply quick fixes:
   ```bash
   # Approve pending CSRs
   oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
   
   # Clean completed pods
   oc delete pods -A --field-selector=status.phase=Succeeded
   oc delete pods -A --field-selector=status.phase=Failed
   ```

3. **Minute 6-10:** If not improved:
   ```bash
   # Restart console (if console-specific)
   oc delete pods -n openshift-console -l app=console
   
   # OR restart API server (if API-wide)
   oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
   ```

4. **Minute 11+:** If still not resolved:
   - Run diagnostic script
   - Check README for specific root cause
   - Collect must-gather if escalating

---

## Common Workflows

### Workflow 1: First-Time Diagnosis (Comprehensive)

```
1. README.md → "Quick Diagnosis" section
   └─ Measure API response time
   └─ Check health of critical components
   └─ Identify symptoms

2. README.md → "Common Root Causes"
   └─ Match your symptoms to root cause
   └─ Follow specific diagnosis steps
   └─ Apply resolution

3. Verify improvement
   └─ Re-run initial measurements
   └─ Compare before/after

4. README.md → "Prevention and Best Practices"
   └─ Set up monitoring
   └─ Configure alerts
```

**Time estimate:** 30-60 minutes

---

### Workflow 2: Rapid Response (Emergency)

```
1. QUICK-REFERENCE.md → "Emergency First Steps"
   └─ 2-minute health check
   └─ Identify if etcd, API, or resources

2. QUICK-REFERENCE.md → "Common Quick Fixes"
   └─ Apply 1-2 quick fixes
   └─ Test improvement

3. If not resolved → README.md
   └─ Detailed diagnosis of specific issue

4. If still not resolved → diagnostic-script.sh
   └─ Collect comprehensive data
   └─ Prepare for escalation
```

**Time estimate:** 5-20 minutes

---

### Workflow 3: Regular Health Check

```
1. Run diagnostic script
   └─ ./diagnostic-script.sh
   └─ Review output

2. If issues found → QUICK-REFERENCE.md
   └─ Address specific findings

3. Track trends over time
   └─ Compare reports weekly
   └─ Identify growth patterns

4. README.md → "Prevention and Best Practices"
   └─ Adjust based on findings
```

**Time estimate:** 5 minutes per check

---

### Workflow 4: Post-Change Validation

```
After cluster changes (upgrade, config change, etc.):

1. QUICK-REFERENCE.md → "One-Liner Health Check"
   └─ Quick before/after comparison

2. Monitor for 15-30 minutes
   └─ watch -n 60 './quick-api-check.sh'

3. If degradation noticed → README.md
   └─ "Step-by-Step Troubleshooting Process"
   └─ Focus on recent changes

4. Document findings
   └─ What changed
   └─ What broke
   └─ How it was fixed
```

**Time estimate:** 15-45 minutes

---

## Root Cause Quick Finder

| Symptom | Most Likely Cause | Go To |
|---------|------------------|-------|
| Consistent slow (>2s) | etcd performance | README → etcd Performance Issues |
| High CPU on masters | Resource constraints or high request rate | README → sections 2 & 4 |
| Slow list operations | Too many objects | README → Large Number of Objects |
| Intermittent timeouts | Network latency or webhooks | README → sections 5 & 7 |
| Console slow, CLI fast | Console-specific issue | README → Console-Specific Recovery |
| Slow after changes | Configuration or audit logging | README → sections 6 & 8 |
| Certificate errors | Certificate issues | README → Certificate Verification |
| Context deadline exceeded | etcd timeout | README → etcd Performance Issues |

---

## Command Quick Reference

### Most Used Commands (Copy-Paste)

```bash
# Measure API performance
time oc get nodes

# Check critical components
oc get co kube-apiserver etcd

# Check resources
oc adm top nodes -l node-role.kubernetes.io/master=

# Quick fix: Approve CSRs
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve

# Quick fix: Clean pods
oc delete pods -A --field-selector=status.phase=Succeeded

# Console restart
oc delete pods -n openshift-console -l app=console

# Collect diagnostics
oc adm must-gather
```

---

## Related Guides

### Within This Repository

- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) - Monitoring from control plane nodes
- [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md) - Controller manager issues
- [CSR Management](../csr-management/README.md) - Certificate signing requests
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) - Base system networking

### OpenShift Documentation

- [API Server Architecture](https://docs.openshift.com/container-platform/latest/architecture/control-plane.html)
- [etcd Performance](https://docs.openshift.com/container-platform/latest/scalability_and_performance/recommended-performance-scale-practices/recommended-etcd-practices.html)
- [Web Console](https://docs.openshift.com/container-platform/latest/web_console/web-console.html)

---

## Tips for Using This Guide

### 1. Start Appropriate to Situation

- **Emergency/Production:** Quick Reference first
- **First diagnosis:** README comprehensive guide
- **Regular check:** Diagnostic script
- **Familiar issue:** Quick Reference for specific commands

### 2. Use Decision Trees

Follow the decision trees in Quick Reference to quickly narrow down the issue.

### 3. Measure Before and After

Always establish baseline measurements before applying fixes:
```bash
# Before
time oc get nodes > before.txt

# Apply fix

# After
time oc get nodes > after.txt

# Compare
```

### 4. One Fix at a Time

Apply one fix, test, measure. This helps identify what actually worked.

### 5. Document Your Path

Note what you tried and results. Useful for:
- Support cases
- Team knowledge sharing
- Similar issues in the future

---

## Success Criteria

You've successfully resolved the issue when:

✅ API response time < 1s for simple queries  
✅ Web console pages load in < 3s  
✅ All cluster operators Available=True, Degraded=False  
✅ Control plane pods stable (no restarts)  
✅ Master node resources < 80%  
✅ No persistent errors in API server logs  
✅ Performance stable for 30+ minutes  

---

## Escalation Path

### When to Escalate

- Issue persists after following complete guide
- Production impact > 1 hour
- Data loss risk identified
- Multiple control plane components failing
- etcd degradation with no clear cause

### Before Escalating

Collect these artifacts:

```bash
# 1. Must-gather
oc adm must-gather

# 2. Specific namespace inspections
oc adm inspect namespace/openshift-kube-apiserver
oc adm inspect namespace/openshift-etcd

# 3. Run diagnostic script
./diagnostic-script.sh

# 4. Capture performance data
time oc get nodes > performance-baseline.txt
oc adm top nodes -l node-role.kubernetes.io/master= > resources.txt
```

### Red Hat Support Case

Include in support case:
- Symptom description with timeline
- Must-gather output
- Diagnostic script output
- What was tried and results
- Current impact to operations

---

## Feedback and Improvements

This guide is maintained as part of the OpenShift troubleshooting repository.

To contribute improvements:
1. Document new scenarios encountered
2. Add commands that worked for you
3. Note any errors or unclear sections
4. Share timing data for different fixes

---

## Version History

- **v1.0** - Initial comprehensive guide for API slowness and web console performance
  - 8 common root causes covered
  - Emergency procedures included
  - Diagnostic automation provided

