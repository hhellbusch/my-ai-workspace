# API Slowness Troubleshooting Flowchart

## Visual Decision Tree

```
┌─────────────────────────────────────────┐
│  API or Web Console Slow?               │
│  Start Here                             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Step 1: Measure the Problem            │
│  $ time oc get nodes                    │
└──────────────┬──────────────────────────┘
               │
               ▼
        ┌──────┴──────┐
        │             │
    <1 second    >2 seconds
        │             │
        ▼             ▼
┌──────────────┐  ┌──────────────────────┐
│ Console      │  │ API-Wide Problem     │
│ Specific     │  │ (Critical)           │
└──────┬───────┘  └──────┬───────────────┘
       │                 │
       │                 ▼
       │          ┌──────────────────────┐
       │          │ Step 2: Check etcd   │
       │          │ $ oc get co etcd     │
       │          │ $ oc get pods -n     │
       │          │   openshift-etcd     │
       │          └──────┬───────────────┘
       │                 │
       │          ┌──────┴──────┐
       │          │             │
       │      Degraded      Available
       │          │             │
       │          ▼             ▼
       │   ┌─────────────┐  ┌──────────────┐
       │   │ FIX etcd    │  │ Step 3:      │
       │   │ FIRST       │  │ Check API    │
       │   │             │  │ Server       │
       │   │ See:        │  └──────┬───────┘
       │   │ README →    │         │
       │   │ etcd        │         ▼
       │   │ Performance │  ┌──────────────┐
       │   └─────────────┘  │ $ oc get co  │
       │                    │   kube-api   │
       │                    │   server     │
       │                    └──────┬───────┘
       │                           │
       │                    ┌──────┴──────┐
       │                    │             │
       │                Degraded      Available
       │                    │             │
       │                    ▼             ▼
       │             ┌─────────────┐  ┌──────────────┐
       │             │ FIX API     │  │ Step 4:      │
       │             │ Server      │  │ Check        │
       │             │             │  │ Resources    │
       │             │ See:        │  └──────┬───────┘
       │             │ README →    │         │
       │             │ API Server  │         ▼
       │             │ Issues      │  ┌──────────────┐
       │             └─────────────┘  │ $ oc adm top │
       │                              │   nodes -l   │
       │                              │   master=    │
       │                              └──────┬───────┘
       │                                     │
       │                              ┌──────┴──────┐
       │                              │             │
       │                          >80% CPU    <80% CPU
       │                              │             │
       │                              ▼             ▼
       │                       ┌─────────────┐  ┌──────────────┐
       │                       │ Resource    │  │ Step 5:      │
       │                       │ Constraints │  │ Run Full     │
       │                       │             │  │ Diagnostics  │
       │                       │ See:        │  └──────┬───────┘
       │                       │ README →    │         │
       │                       │ Control     │         ▼
       │                       │ Plane       │  ┌──────────────┐
       │                       │ Resources   │  │ $ ./         │
       │                       └─────────────┘  │   diagnostic │
       │                                        │   -script.sh │
       │                                        └──────┬───────┘
       │                                               │
       │                                               ▼
       │                                        ┌──────────────┐
       │                                        │ Review       │
       │                                        │ Output &     │
       │                                        │ Follow       │
       │                                        │ Recommenda-  │
       │                                        │ tions        │
       │                                        └──────────────┘
       │
       ▼
┌──────────────────────┐
│ Console-Specific     │
│ Troubleshooting      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Check Console Pods   │
│ $ oc get pods -n     │
│   openshift-console  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Check Console Logs   │
│ $ oc logs -n         │
│   openshift-console  │
│   -l app=console     │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Restart Console      │
│ $ oc delete pods -n  │
│   openshift-console  │
│   -l app=console     │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Test Console         │
│ (Open in browser)    │
└──────────────────────┘
```

## Quick Decision Points

### Decision Point 1: How Slow?

**Measure:**
```bash
time oc get nodes
```

**Decision:**
- **<1s**: Console-specific → Go to Console Path
- **1-2s**: Degraded but functional → Run diagnostics
- **>2s**: Critical → Emergency path
- **>5s**: Severe → Check etcd immediately

### Decision Point 2: Is etcd Healthy?

**Check:**
```bash
oc get co etcd
oc get pods -n openshift-etcd
```

**Decision:**
- **Available=True, Degraded=False, All pods Running**: etcd is OK → Continue
- **Degraded=True OR pods not running**: etcd is the problem → Fix etcd first
- **Available=False**: Critical etcd issue → Emergency recovery

### Decision Point 3: Is API Server Healthy?

**Check:**
```bash
oc get co kube-apiserver
oc get pods -n openshift-kube-apiserver
```

**Decision:**
- **Available=True, All pods Running**: API server OK → Check resources
- **Degraded=True**: API server issues → Check logs
- **Pods restarting**: Crash loop → Fix API server

### Decision Point 4: Are Resources Constrained?

**Check:**
```bash
oc adm top nodes -l node-role.kubernetes.io/master=
```

**Decision:**
- **CPU >80% OR Memory >80%**: Resource constraints → Scale or optimize
- **CPU <60% AND Memory <60%**: Resources OK → Check objects/logs
- **Disk full**: Critical → Clean up immediately

### Decision Point 5: Too Many Objects?

**Check:**
```bash
echo "Pods: $(oc get pods -A --no-headers | wc -l)"
echo "Events: $(oc get events -A --no-headers | wc -l)"
```

**Decision:**
- **Events >50,000**: Critical → Clean up events
- **Events >20,000**: Warning → Plan cleanup
- **Pods >5,000**: High → Check for completed pods
- **All normal**: → Run full diagnostics

## Emergency Quick Path

```
Emergency (API >5s response)?
    ↓
YES → Follow this path:
    ↓
1. Check etcd (30 sec)
   $ oc get co etcd
    ↓
2. Approve CSRs (30 sec)
   $ oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
    ↓
3. Clean pods (30 sec)
   $ oc delete pods -A --field-selector=status.phase=Succeeded
   $ oc delete pods -A --field-selector=status.phase=Failed
    ↓
4. Test improvement (10 sec)
   $ time oc get nodes
    ↓
5. If still slow → Restart API server (2 min)
   $ oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
    ↓
6. If still slow → Collect diagnostics & escalate
   $ oc adm must-gather
```

## Root Cause Identification Flow

```
API Slow → What's the pattern?

├─ Consistent slow (always >2s)
│  └─ Most likely: etcd performance
│     → README.md → Section 1: etcd Performance Issues
│
├─ Intermittent slow (sometimes fast, sometimes slow)
│  └─ Most likely: Resource spikes or network
│     → README.md → Section 5: Network Latency Issues
│     → README.md → Section 4: Control Plane Resource Constraints
│
├─ Slow for specific operations (e.g., list pods)
│  └─ Most likely: Too many objects
│     → README.md → Section 3: Large Number of Objects
│
├─ Slow after changes (upgrade, config change)
│  └─ Most likely: Configuration or webhooks
│     → README.md → Section 6: Certificate Verification Issues
│     → README.md → Section 7: Excessive Webhook Calls
│
└─ Console slow but CLI fast
   └─ Console-specific issue
      → README.md → Console-Specific Recovery
```

## Symptom-to-Root-Cause Map

| Symptom | Most Likely Cause | Go To |
|---------|------------------|-------|
| Consistent 2-5s response | etcd latency | README → etcd Performance |
| Timeouts (>30s) | etcd or API server down | Emergency procedures |
| High CPU on masters | High request rate or resource constraints | README → High API Request Rate |
| Slow list operations | Too many objects | README → Large Number of Objects |
| Intermittent timeouts | Network or webhooks | README → Network Latency |
| Console slow, CLI fast | Console pods or OAuth | Console-Specific Recovery |
| Slow after upgrade | Configuration or certificates | README → Certificate Issues |
| "context deadline exceeded" | etcd timeout | README → etcd Performance |
| Certificate errors in logs | Certificate rotation | README → Certificate Verification |
| Webhook timeout errors | Webhook issues | README → Excessive Webhook Calls |

## Time-Based Troubleshooting Path

### Path 1: 2-Minute Emergency (Production Down)

```
1. QUICKSTART.md → Emergency section (30 sec read)
2. Run 3 quick checks (1 min)
3. Try quick fix #1 or #2 (30 sec)
Total: 2 minutes
```

### Path 2: 15-Minute Rapid Response

```
1. QUICK-REFERENCE.md → Emergency First Steps (2 min)
2. Run all quick fixes (5 min)
3. Run diagnostic script (5 min)
4. Review output and apply recommendation (3 min)
Total: 15 minutes
```

### Path 3: 60-Minute Comprehensive Analysis

```
1. Run diagnostic script (5 min)
2. Read relevant README sections (20 min)
3. Apply detailed fixes (20 min)
4. Monitor and verify (15 min)
Total: 60 minutes
```

## File Navigation by Urgency

```
URGENT (Production Emergency)
    ↓
QUICKSTART.md (this file)
    ↓
QUICK-REFERENCE.md
    ↓
Apply quick fixes
    ↓
Still broken? → diagnostic-script.sh
    ↓
Still broken? → README.md (specific section)
    ↓
Still broken? → Escalate with must-gather

─────────────────────────────────────

PLANNED (Troubleshooting Session)
    ↓
INDEX.md (understand structure)
    ↓
diagnostic-script.sh (collect data)
    ↓
README.md (comprehensive analysis)
    ↓
Apply fixes from README
    ↓
Implement prevention from README

─────────────────────────────────────

LEARNING (Understanding the System)
    ↓
GUIDE-SUMMARY.md (overview)
    ↓
INDEX.md (navigation)
    ↓
README.md (complete guide)
    ↓
QUICK-REFERENCE.md (commands)
```

## Success Verification Flow

```
Applied a fix?
    ↓
Wait 2 minutes for stabilization
    ↓
Test: time oc get nodes
    ↓
    ├─ <1s → SUCCESS! Monitor for 15 min
    │         ↓
    │     Still good?
    │         ├─ YES → Fixed! Document what worked
    │         └─ NO → Regression, try next fix
    │
    └─ >1s → Not fixed yet
              ↓
          Try next fix OR
          Run diagnostics for more data
```

## Escalation Decision Flow

```
Worked through guide?
    ↓
Issue resolved?
    ├─ YES → Document solution, implement prevention
    │
    └─ NO → Check escalation criteria:
            ↓
        ┌───┴───┐
        │       │
    Any of these?
    - Issue persists after guide
    - Production impact >1 hour
    - Multiple control plane components failing
    - Data loss risk
    - etcd degraded with no clear cause
        │
        ├─ YES → ESCALATE
        │         ↓
        │     Collect:
        │     - must-gather
        │     - diagnostic script output
        │     - What was tried
        │         ↓
        │     Open Red Hat support case
        │
        └─ NO → Continue troubleshooting
                Review README for additional root causes
```

## Color-Coded Severity Guide

When using the diagnostic script, look for these indicators:

- **✓ (Green)**: Healthy, no action needed
- **⚠ (Yellow)**: Warning, monitor or plan fix
- **✗ (Red)**: Critical, immediate action required

**Priority:**
1. Fix all ✗ (Red) items first
2. Address ⚠ (Yellow) items during maintenance
3. Monitor ✓ (Green) items for trends

## Quick Command Reference by Stage

### Stage 1: Initial Assessment (30 seconds)
```bash
time oc get nodes
oc get co kube-apiserver etcd
```

### Stage 2: Quick Health Check (1 minute)
```bash
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd
oc adm top nodes -l node-role.kubernetes.io/master=
```

### Stage 3: Quick Fixes (2 minutes)
```bash
oc get csr | grep Pending | awk '{print $1}' | xargs oc adm certificate approve
oc delete pods -A --field-selector=status.phase=Succeeded
oc delete pods -A --field-selector=status.phase=Failed
```

### Stage 4: Full Diagnostics (5 minutes)
```bash
./diagnostic-script.sh
cat api-diagnostics-*.txt
```

### Stage 5: Targeted Fix (varies)
Follow recommendations from diagnostic output or README

### Stage 6: Verification (15 minutes)
```bash
watch -n 60 'time oc get nodes'
oc get co
oc get pods -n openshift-kube-apiserver
```

---

**Navigation:**
- **Start here**: [QUICKSTART.md](QUICKSTART.md)
- **Emergency commands**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **Complete guide**: [README.md](README.md)
- **Guide overview**: [INDEX.md](INDEX.md)

**Last Updated**: January 2026

