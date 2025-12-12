# Troubleshooting Flowchart: Worker Node TLS Certificate Failure

## Visual Troubleshooting Flow

```
┌─────────────────────────────────────────────────────────────┐
│ PROBLEM: Worker node cannot join cluster                   │
│ ERROR: TLS certificate verification failed                 │
│ ENDPOINT: https://<api-vip>:22623/config/worker           │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
          ┌────────────────────────────────────┐
          │ Step 1: Run Diagnostics            │
          │                                    │
          │ ./diagnose-tls.sh                  │
          └────────────────┬───────────────────┘
                           │
                           ▼
          ┌────────────────────────────────────┐
          │ Step 2: Check Certificate          │
          │                                    │
          │ Is certificate expired?            │
          └────────┬───────────────┬───────────┘
                   │               │
            YES ◄──┘               └──► NO
                   │                   │
                   ▼                   ▼
    ┌──────────────────────┐  ┌───────────────────┐
    │ FIX: Regenerate Cert │  │ Check MCS Pods    │
    │                      │  │                   │
    │ oc delete secret...  │  │ Are they running? │
    │ oc delete pods...    │  └─────┬───────┬─────┘
    └──────────┬───────────┘        │       │
               │               YES◄─┘       └─►NO
               │                   │            │
               ▼                   ▼            ▼
    ┌──────────────────────┐  ┌───────────────────────┐
    │ Verify New Cert      │  │ FIX: Check MCO        │
    │                      │  │                       │
    │ Check expiration     │  │ oc get co machine-... │
    └──────────┬───────────┘  │ oc describe co...     │
               │              └──────────┬────────────┘
               ▼                         │
    ┌──────────────────────┐            │
    │ Cert OK now?         │            │
    └─────┬────────────┬───┘            │
          │            │                │
     YES◄─┘            └─►NO            │
          │               │             │
          │               └─────────────┘
          │                       │
          ▼                       ▼
┌─────────────────────┐  ┌───────────────────┐
│ Step 3: Test        │  │ Check Network     │
│ Connectivity        │  │                   │
│                     │  │ Can reach API VIP?│
│ curl https://...    │  └─────┬───────┬─────┘
└──────┬──────────────┘        │       │
       │                  YES◄─┘       └─►NO
       ▼                       │           │
┌─────────────────────┐        │           ▼
│ Endpoint responds?  │        │  ┌────────────────────┐
└───┬──────────────┬──┘        │  │ FIX: Check HAProxy │
    │              │           │  │ & VIP Config       │
YES◄┘              └─►NO       │  │                    │
    │                 │        │  │ systemctl status.. │
    │                 │        │  │ oc get infra...    │
    │                 │        │  └────────────────────┘
    │                 │        │
    │                 └────────┘
    │                          │
    ▼                          ▼
┌─────────────────────┐  ┌───────────────────┐
│ Step 4: Time Sync   │  │ Advanced Troubl.  │
│                     │  │                   │
│ Is time correct?    │  │ See README.md     │
└───┬──────────────┬──┘  └───────────────────┘
    │              │
YES◄┘              └─►NO
    │                 │
    │                 ▼
    │      ┌──────────────────────┐
    │      │ FIX: Time Sync       │
    │      │                      │
    │      │ Fix BMC time or      │
    │      │ Add NTP MachineConf  │
    │      └───────────┬──────────┘
    │                  │
    └──────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │ RETRY WORKER         │
    │                      │
    │ Power off           │
    │ Wait 10s            │
    │ Power on            │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ Monitor Progress     │
    │                      │
    │ watch oc get bmh     │
    └──────────┬───────────┘
               │
               ▼
┌──────────────────────────────┐
│ Success: Worker Joins        │
│                              │
│ States:                      │
│ registering → inspecting     │
│ → provisioning → provisioned │
│ → Node Ready                 │
└──────────────────────────────┘
```

---

## Decision Matrix

| Symptom | Most Likely Cause | Quick Check | Fix |
|---------|-------------------|-------------|-----|
| x509: certificate has expired | Certificate expired (70%) | `openssl s_client ... \| ... -dates` | Delete secret, restart pods |
| Connection refused | MCS pods not running (15%) | `oc get pods ... -l k8s-app=mcs` | Check MCO, restart pods |
| Connection timeout | Network/VIP issue (10%) | `curl -kv https://vip:22623` | Check HAProxy, VIP config |
| TLS handshake timeout | Time sync issue (5%) | Check BMC/worker time | Fix time at BMC or add NTP |

---

## Quick Diagnostic Tree

### Start Here ⬇️

**Q1: Can you connect to the MCS endpoint at all?**
```bash
curl -k -s -o /dev/null -w "%{http_code}\n" https://${API_VIP}:22623/healthz
```

- **200 or 404** → Connection OK, proceed to Q2
- **000 or timeout** → Network/connectivity issue
  - Check HAProxy on masters
  - Verify API VIP configuration
  - Test from master node

**Q2: Is the certificate valid?**
```bash
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0
```

- **Certificate will not expire** → Cert OK, proceed to Q3
- **Certificate will expire** → Certificate expired
  - Delete secret: `oc delete secret machine-config-server-tls -n openshift-machine-config-operator`
  - Restart pods: `oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server`
  - Verify new cert, then retry

**Q3: Are MCS pods running?**
```bash
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
```

- **All Running** → MCS healthy, proceed to Q4
- **Not running or crashing** → MCS unhealthy
  - Check MCO: `oc get clusteroperator machine-config`
  - Review logs: `oc logs -n openshift-machine-config-operator ...`
  - Check why pods can't start

**Q4: Is worker node time correct?**

- Access BMC console during worker boot
- Check time displayed
- **Time correct** → See advanced troubleshooting
- **Time wrong** → Time sync issue
  - Fix BMC/BIOS time
  - Or add NTP MachineConfig
  - Retry worker provisioning

---

## Phase-Based Troubleshooting

### Phase 1: Pre-Boot (Before Worker Powers On)

✅ **Checks to perform:**
```bash
# 1. MCS pods healthy
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 2. Certificate valid
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 3. Endpoint accessible
curl -kv https://${API_VIP}:22623/healthz

# 4. Worker MachineConfig exists
oc get machineconfig | grep worker
```

❌ **If any fail:**
- Fix before powering on worker
- No point booting worker if MCS isn't ready

---

### Phase 2: During Boot (Worker Booting)

**What's happening:**
1. Worker boots from ISO/PXE
2. Minimal ignition runs
3. Worker reaches out to fetch full ignition from MCS
4. **← TLS error happens here**

**How to observe:**
- BMC virtual console (best option)
- Check BareMetalHost events: `oc describe baremetalhost <worker>`
- Watch Metal3 logs: `oc logs -n openshift-machine-api deployment/metal3`

**Red flags:**
- Worker boots but never progresses
- Repeating boot cycles
- Console shows ignition fetch errors

---

### Phase 3: Post-Boot (After Ignition Fetch)

**If ignition fetch succeeds:**

```bash
# Worker should appear as node
oc get nodes | grep <worker-name>

# CSRs should appear
oc get csr | grep <worker-name>

# Approve CSRs if needed
oc get csr -o name | xargs oc adm certificate approve

# Node should become Ready
watch oc get node <worker-name>
```

**If still failing here:**
- Different issue (not TLS/MCS)
- Check CSR management: [../csr-management/](../csr-management/)
- Check networking: [../coreos-networking-issues/](../coreos-networking-issues/)

---

## Common Error Messages → Root Cause

### Error: "x509: certificate has expired"

**Root Cause:** MCS certificate expired

**Verification:**
```bash
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates
```

**Fix:**
```bash
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
```

---

### Error: "certificate signed by unknown authority"

**Root Cause:** CA bundle mismatch between cluster and worker ignition

**Verification:**
```bash
# Check CA in worker machineconfig
oc get machineconfig 99-worker-generated-registries -o yaml | grep -A 20 ca-bundle

# Compare with actual CA
oc get configmap -n openshift-kube-apiserver kube-apiserver-server-ca -o yaml
```

**Fix:**
```bash
# Force machineconfig regeneration
oc patch machineconfig 99-worker-generated-registries --type merge -p '{"metadata":{"annotations":{"force-refresh":"'$(date +%s)'"}}}'
```

---

### Error: "connection refused"

**Root Cause:** MCS pods not running or firewall blocking

**Verification:**
```bash
# Check pods
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check HAProxy on masters
for node in $(oc get nodes -l node-role.kubernetes.io/master -o name); do
  oc debug $node -- chroot /host systemctl status haproxy
done
```

**Fix:**
```bash
# If pods not running
oc get clusteroperator machine-config
oc describe clusteroperator machine-config

# If HAProxy issue
# Restart haproxy on affected masters via oc debug
```

---

### Error: "connection timeout" or "i/o timeout"

**Root Cause:** Network connectivity issue between worker and API VIP

**Verification:**
```bash
# From existing node, test connectivity
oc debug node/master-0 -- chroot /host bash -c "ping -c 3 ${API_VIP} && nc -zv ${API_VIP} 22623"

# Check VIP configuration
oc get infrastructure cluster -o yaml | grep -A 10 apiVIP
```

**Fix:**
- Verify API VIP is on correct network
- Check provisioning network configuration
- Verify worker can reach control plane network
- Check firewall rules

---

### Error: "TLS handshake timeout"

**Root Cause:** Slow network or time synchronization issue

**Verification:**
```bash
# Check latency
oc debug node/master-0 -- chroot /host ping -c 10 ${API_VIP}

# Time sync requires BMC console access to worker
# Check time shown during boot
```

**Fix:**
- If latency high: investigate network
- If time wrong: fix BMC time or add NTP to worker MachineConfig

---

## Recovery Checklist

After applying any fix, use this checklist:

### ✓ Post-Fix Verification

```bash
# 1. Certificate is valid
[ ] echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0

# 2. MCS pods running
[ ] oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server | grep Running

# 3. Endpoint responds
[ ] curl -k -s -o /dev/null -w "%{http_code}" https://${API_VIP}:22623/healthz
    # Should return 200 or 404

# 4. Worker MachineConfigPool ready
[ ] oc get machineconfigpool worker | grep -E "True.*False.*False"

# 5. HAProxy healthy on masters
[ ] for node in $(oc get nodes -l node-role.kubernetes.io/master -o name); do
      oc debug $node -- chroot /host systemctl is-active haproxy
    done
```

### ✓ Retry Worker Provisioning

```bash
# 1. Power off worker
[ ] oc patch baremetalhost <worker> -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'

# 2. Wait
[ ] sleep 10

# 3. Power on worker
[ ] oc patch baremetalhost <worker> -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# 4. Monitor
[ ] watch oc get baremetalhost <worker> -n openshift-machine-api
```

### ✓ Success Indicators

```bash
# 1. BareMetalHost progresses
[ ] oc get baremetalhost <worker> -n openshift-machine-api
    # STATE: provisioning → provisioned

# 2. Node appears
[ ] oc get nodes | grep <worker>

# 3. CSRs created (may need approval)
[ ] oc get csr | grep <worker>

# 4. Node becomes Ready
[ ] oc get node <worker> | grep Ready
```

---

## When All Else Fails

### Nuclear Option: Complete MCS Reset

⚠️ **WARNING:** This restarts MCS for entire cluster. Schedule maintenance window.

```bash
# 1. Backup current state
oc get secret machine-config-server-tls -n openshift-machine-config-operator -o yaml > /tmp/mcs-tls-backup.yaml
oc get all -n openshift-machine-config-operator -o yaml > /tmp/mco-backup.yaml

# 2. Delete MCS TLS secret
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# 3. Force delete all MCS pods
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server --force --grace-period=0

# 4. Wait for recreation (may take 2-3 minutes)
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -w

# 5. Verify new setup
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text

# 6. Test endpoint
curl -kv https://${API_VIP}:22623/healthz

# 7. Retry all pending workers
for worker in $(oc get baremetalhost -n openshift-machine-api -o name); do
  oc patch $worker -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
done
sleep 10
for worker in $(oc get baremetalhost -n openshift-machine-api -o name); do
  oc patch $worker -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
done
```

---

## Escalation Path

### When to Escalate to Red Hat Support

Escalate if:
- [ ] Certificate is valid but TLS errors persist
- [ ] MCS pods won't stay running after multiple restarts
- [ ] Fresh certificate doesn't resolve issue
- [ ] Multiple cluster certificates showing issues (cluster-wide problem)
- [ ] HAProxy/keepalived failures on control plane
- [ ] Issue persists after all documented solutions attempted

### Data to Collect

Before opening support case:

```bash
# 1. Run diagnostic script
./diagnose-tls.sh
# Save the entire output directory

# 2. Collect must-gather
oc adm must-gather --dest-dir=/tmp/must-gather

# 3. Specific MCS/MCO data
oc get all -n openshift-machine-config-operator -o yaml > /tmp/mco-all.yaml
oc get machineconfig -o yaml > /tmp/machineconfigs.yaml
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-server --all-containers > /tmp/mcs-logs.txt

# 4. Certificate dumps
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 -showcerts 2>/dev/null > /tmp/mcs-certs-full.txt

# 5. BareMetalHost details
oc get baremetalhost -n openshift-machine-api -o yaml > /tmp/baremetalhosts.yaml
oc get events -n openshift-machine-api --sort-by='.lastTimestamp' > /tmp/bmh-events.txt
```

---

## Additional Flowcharts

### Certificate Rotation Flow

```
Certificate Expired
       ↓
Delete TLS Secret
       ↓
Restart MCS Pods
       ↓
Kubernetes generates new secret (via cert-manager/operator)
       ↓
MCS pods mount new secret
       ↓
New certificate served on :22623
       ↓
Workers can fetch ignition with valid cert
```

### Worker Boot Flow

```
BareMetalHost online: true
       ↓
Metal3 operator detects
       ↓
Ironic prepares virtual media (ISO)
       ↓
BMC mounts ISO
       ↓
Server boots from ISO
       ↓
Minimal ignition executes
       ↓
Worker contacts MCS at :22623  ← TLS verification happens here
       ↓
[Success] Full ignition downloaded
       ↓
Worker applies full config
       ↓
Kubelet starts
       ↓
Node joins cluster
       ↓
CSRs created and approved
       ↓
Node becomes Ready
```

---

**Next Steps:**
1. Use the decision matrix to identify your specific scenario
2. Follow the quick diagnostic tree
3. Apply the appropriate fix
4. Use the recovery checklist to verify
5. Escalate if needed with collected data

