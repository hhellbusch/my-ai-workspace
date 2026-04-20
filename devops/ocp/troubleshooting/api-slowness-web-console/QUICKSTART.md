# Quick Start: API Slowness Troubleshooting

## 🚨 Emergency? Start Here (60 seconds)

```bash
# 1. Measure the problem
time oc get nodes

# 2. Check critical components
oc get co kube-apiserver etcd

# 3. Check resources
oc adm top nodes -l node-role.kubernetes.io/master=
```

**If slow (>2s)**: Continue to Quick Fixes below  
**If fast (<1s)**: Console-specific issue, see [Console Recovery](#console-specific-issue)

---

## ⚡ Quick Fixes (Try These First)

### Fix 1: Approve Pending CSRs (30 seconds)
```bash
# Check count
oc get csr | grep -c Pending

# If >10, approve them
oc get csr -o name | xargs oc adm certificate approve
```

### Fix 2: Clean Up Completed Pods (30 seconds)
```bash
# Clean up
oc delete pods -A --field-selector=status.phase=Succeeded
oc delete pods -A --field-selector=status.phase=Failed

# Verify improvement
time oc get nodes
```

### Fix 3: Restart Console (Console-Specific)
```bash
# If CLI is fast but console is slow
oc delete pods -n openshift-console -l app=console

# Wait 30 seconds, then test console
```

### Fix 4: Restart API Server (Last Resort)
```bash
# Only if API is consistently slow
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver

# Monitor restart
watch oc get pods -n openshift-kube-apiserver
```

---

## 📊 Run Full Diagnostics (5 minutes)

```bash
cd ocp/troubleshooting/api-slowness-web-console

# Make script executable (first time only)
chmod +x diagnostic-script.sh

# Run diagnostics
./diagnostic-script.sh

# View results
cat api-diagnostics-*.txt
```

The script will:
- ✅ Measure API performance
- ✅ Check all critical components
- ✅ Analyze resource usage
- ✅ Review logs for errors
- ✅ Provide specific recommendations

---

## 📚 Which Guide Should I Read?

### 🔥 Production Emergency
**→ [QUICK-REFERENCE.md](QUICK-REFERENCE.md)**
- 2-minute emergency checks
- Decision tree
- Copy-paste commands
- Quick fixes

### 🔍 First Time Troubleshooting
**→ [README.md](README.md)**
- Complete guide
- 8 root causes explained
- Step-by-step procedures
- Prevention tips

### 🗺️ Need Navigation Help
**→ [INDEX.md](INDEX.md)**
- Guide overview
- Symptom-based navigation
- Workflow examples
- Time estimates

### 📝 Want Overview
**→ [GUIDE-SUMMARY.md](GUIDE-SUMMARY.md)**
- What's included
- Coverage details
- Integration info
- Quick start scenarios

---

## 🎯 Common Scenarios

### Scenario 1: "Web console is really slow"

```bash
# Step 1: Is it API or console-specific?
time oc get nodes

# If <1s (fast): Console-specific
oc logs -n openshift-console -l app=console --tail=50
oc delete pods -n openshift-console -l app=console

# If >2s (slow): API-wide issue
# → Go to Scenario 2
```

### Scenario 2: "Everything is slow (API + Console)"

```bash
# Step 1: Check etcd (most common cause)
oc get co etcd
oc get pods -n openshift-etcd

# Step 2: Check resources
oc adm top nodes -l node-role.kubernetes.io/master=

# Step 3: Run diagnostics
./diagnostic-script.sh

# Step 4: Read the recommendations in output file
cat api-diagnostics-*.txt
```

### Scenario 3: "Intermittent slowness"

```bash
# Monitor over time
watch -n 5 'echo "=== $(date) ==="; time oc get nodes 2>&1 | head -5'

# While monitoring, check:
# - Resource spikes: oc adm top nodes -l node-role.kubernetes.io/master=
# - Recent events: oc get events -A --sort-by='.lastTimestamp' | tail -20
# - API errors: oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=50
```

### Scenario 4: "Slow after cluster change"

```bash
# Check what changed
oc get clusterversion -o yaml | grep -A 10 history

# Check recent events
oc get events -A --sort-by='.lastTimestamp' | tail -50

# Run diagnostics to establish new baseline
./diagnostic-script.sh after-change-$(date +%Y%m%d).txt
```

### Scenario 5: "Service account token has expired" errors

```bash
# Step 1: Run specific diagnostic
./diagnose-token-expiry.sh

# Step 2: Quick check - count errors
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=1000 | \
  grep -c "service account token has expired"

# Step 3: Identify affected service accounts
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=2000 | \
  grep "service account token has expired" | \
  grep -oP 'system:serviceaccount:\K[^"]+' | sort | uniq -c | sort -rn | head -5

# Step 4: Quick fix - restart affected pods
oc delete pod -n <namespace> <pod-name>

# See detailed guide:
cat SERVICE-ACCOUNT-TOKEN-EXPIRY.md
```

### Scenario 6: "Client-side throttling" delays

```bash
# Step 1: Run diagnostic
./diagnose-client-throttling.sh

# Step 2: Count throttling events
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep -c "client-side throttling"

# Step 3: Find which clients are throttled
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep "client-side throttling" | \
  grep -oP 'user="[^"]+' | sed 's/user="//' | \
  sort | uniq -c | sort -rn | head -5

# Step 4: Check for contributing factors
# - High tokenreview volume?
oc logs -n openshift-kube-apiserver -l app=openshift-kube-apiserver --tail=5000 | \
  grep -c "tokenreviews"

# - Crashlooping pods?
oc get pods -A | grep -c CrashLoopBackOff

# - Too many webhooks?
echo "Validating: $(oc get validatingwebhookconfigurations --no-headers | wc -l)"
echo "Mutating: $(oc get mutatingwebhookconfigurations --no-headers | wc -l)"

# See detailed guide:
cat CLIENT-SIDE-THROTTLING.md
```

---

## 📈 Success Criteria

You've fixed it when:

✅ `time oc get nodes` returns in <1 second  
✅ Web console pages load in <3 seconds  
✅ `oc get co` shows all Available=True, Degraded=False  
✅ No pod restarts in control plane for 10+ minutes  
✅ Master node resources <80%  

---

## 🆘 When to Escalate

Escalate to Red Hat Support if:

- Issue persists after following this guide
- Production impact >1 hour
- Multiple control plane components failing
- Data loss risk

**Before escalating, collect:**
```bash
oc adm must-gather
./diagnostic-script.sh
oc adm inspect namespace/openshift-kube-apiserver
oc adm inspect namespace/openshift-etcd
```

---

## 📖 Full Documentation Structure

```
api-slowness-web-console/
│
├── QUICKSTART.md          ← You are here (fastest path)
├── QUICK-REFERENCE.md     ← Emergency commands (2-15 min)
├── README.md              ← Complete guide (30-60 min)
├── INDEX.md               ← Navigation & workflows
├── GUIDE-SUMMARY.md       ← Overview & features
└── diagnostic-script.sh   ← Automated diagnostics
```

**Navigation Tips:**
- **Emergency**: QUICKSTART → QUICK-REFERENCE
- **First diagnosis**: QUICKSTART → diagnostic-script.sh → README
- **Regular check**: diagnostic-script.sh only
- **Learning**: INDEX → README

---

## 💡 Pro Tips

1. **Always measure first**: Use `time` to quantify the problem
2. **Check etcd first**: It's the #1 cause of API slowness
3. **One fix at a time**: Apply, test, measure
4. **Establish baselines**: Run diagnostics when cluster is healthy
5. **Monitor after fixes**: Watch for 15-30 minutes to confirm stability

---

## 🔗 Related Guides

- [Service Account Token Expiry](SERVICE-ACCOUNT-TOKEN-EXPIRY.md) - "token has expired" errors
- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) - When API is completely down
- [kube-controller-manager Issues](../kube-controller-manager-crashloop/README.md) - Controller problems
- [CSR Management](../csr-management/README.md) - Certificate approval

---

## ⏱️ Time Budget Guide

| Task | Time | Document |
|------|------|----------|
| Emergency response | 2-5 min | QUICKSTART + QUICK-REFERENCE |
| Quick fixes | 5-10 min | QUICKSTART (this file) |
| Full diagnostics | 5 min | diagnostic-script.sh |
| First-time analysis | 30-60 min | README.md |
| Regular health check | 5 min | diagnostic-script.sh |

---

**Last Updated**: January 2026  
**Version**: 1.0  
**Compatibility**: OpenShift 4.x

