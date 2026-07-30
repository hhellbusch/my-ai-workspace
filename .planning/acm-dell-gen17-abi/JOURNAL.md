# Engineering Journal — ACM / Dell Gen17 / iDRAC10 / ABI

Living log of observations, hypotheses, tests, and outcomes. One dated entry per working session or significant finding.

**Format per entry:** Situation → Evidence → Hypothesis → Test → Result → Next

---

## 2026-07-02 — Session 0: Kickoff

### Situation

Starting collaborative troubleshooting for OpenShift provisioning on Dell Gen17 (iDRAC10) through ACM. Install method described as ABI (Agent-Based Installer). No prior Gen17/iDRAC10 content in this workspace.

### Evidence gathered (workspace + public docs)

| Source | Finding |
|--------|---------|
| Workspace `devops/rhacm/` | CIM hub setup, bare-metal CR patterns, agent rootfs SSL troubleshooting — no Gen17-specific notes |
| Prior session Dec 2025 | Dell + iDRAC (pre-10) + Mellanox NIC caused BMO inspection hang (`mlx5_query_module_id`); used `idrac-virtualmedia://` BMC URL |
| OCP 4.20/4.21 release notes | iDRAC10 **1.20.25.00, 1.20.60.50, 1.20.70.50** verified for **IPI Redfish virtual media**; **not tested with provisioning network** |
| OCP bare-metal docs | Dell virtual media requires `idrac-virtualmedia://`; `redfish-virtualmedia://` fails on Dell |
| Assisted Installer docs | Redfish API boot path documented for iDRAC (`VirtualMedia.InsertMedia` on `Managers/iDRAC.Embedded.1`) |

### Hypothesis (untested)

Failure may fall into one of these buckets — need user evidence to rank:

1. **Hub / CIM** — `AgentServiceConfig`, assisted-service routes, proxy gap, mirror/`osImages`
2. **Boot media delivery** — virtual media attach on iDRAC10, wrong Redfish path, eHTML5 console plugin
3. **Early agent boot** — rootfs download / TLS / firewall (see existing RHACM troubleshooting guide)
4. **Hardware discovery** — NIC/firmware/Gen17-specific inventory quirks (Mellanox pattern from prior session)
5. **Workflow mismatch** — ABI ISO workflow vs ACM CIM discovery ISO / `InfraEnv` expectations

### Test

None yet — awaiting current-state inputs from operator.

### Result

Project scaffold created: `BRIEF.md`, this journal, `whats-next.md`.

### Next

Collect baseline from operator (see questions in session thread). Run hub audit (`cim-hub-setup.md` quick audit) if hub access available.

### Open questions

- [x] Install path → **ACM CIM / Assisted** (`InfraEnv` + discovery ISO)
- [ ] ACM / MCE / OCP versions?
- [ ] Exact stall phase (early boot rootfs vs agent registered vs install pulling images)
- [ ] iDRAC10 firmware version?
- [ ] Connected vs disconnected / mirror registry?
- [ ] Node count and roles (compact 3-node vs workers)?
- [ ] Is `InfraEnv.spec.proxy` set? Is `proxy/cluster` `trustedCA` configured?

---

## 2026-07-02 — Session 1: Path confirmed, proxy/cert hunch

### Situation

Operator confirms **ACM CIM / Assisted path** (not standalone `openshift-install agent`). ACM appears able to orchestrate iDRAC virtual-media boot from the discovery ISO. Install subsequently **stalls** — exact symptom not yet observed firsthand. Team hunch: **corporate proxy** or **certificate trust** gap.

### Evidence

- Virtual media boot orchestration working → past BMC/Redfish attach phase (Gen17/iDRAC10 path viable at least this far).
- Stall location **unknown** — could be early RHCOS live boot, agent→hub registration, validation, or image pull during install.
- Workspace docs flag a **three-layer proxy model**; fixing hub proxy does **not** fix install-target proxy:

| Layer | Who | Config surface | Typical symptom if wrong |
|-------|-----|----------------|--------------------------|
| Hub egress | `assisted-service`, `assisted-image-service` pods | Cluster `Proxy` + pod env injection | `InfraEnv` `ImageCreated=False`; hub can't cache ISO/rootfs |
| Install target → hub | Booting agents on provisioning VLAN | `InfraEnv.spec.proxy` + `noProxy` for hub ingress | `curl: (35) reset by peer` or timeout pulling rootfs from `assisted-image-service` |
| Install target → registries | Nodes during OCP install | Cluster install proxy (via `AgentClusterInstall` / install config) | Agents register then install hangs pulling container images |

- Certificate trust splits similarly:
  - **TLS inspection proxy** → needs `proxy/cluster.spec.trustedCA` on hub; install hosts need CA in discovery ISO path via proxy config
  - **Hub ingress cert** → install network must trust or reach hub without inspection
  - **BMC CA** (separate) — less likely if virtual media boot already works

### Hypothesis (ranked)

1. **Install-target proxy missing on `InfraEnv`** — hosts on provisioning VLAN need proxy to reach `*.apps.<hub>` or Red Hat, but only hub-side proxy was configured.
2. **TLS inspection without trusted CA** — `SSL certificate problem` on agents; or middlebox **RST** masquerading as `Connection reset by peer`.
3. **`noProxy` too narrow** — hub ingress domain traverses proxy when it should be direct (or vice versa).
4. **Install-phase image pull** — agents registered and approved, but cluster install proxy / mirror / pull-secret path broken (different from discovery ISO boot).
5. **DNS on install VLAN** — `assisted-image-service-multicluster-engine.apps.<domain>` resolves differently than from hub.

### Test plan (for whoever has eyes on the system)

**Phase A — Locate the stall** (determines which proxy layer matters):

```bash
# On hub — do agents exist?
oc get agents -A
oc get infraenv -A
oc get agentclusterinstall -A

# Per agent — state and validation
oc get agent <name> -n <ns> -o jsonpath='phase={.status.debugInfo.state} info={.status.debugInfo.stateInfo}{"\n"}'
oc get agent <name> -n <ns> -o yaml | grep -A30 'validationsInfo\|stateInfo\|messages'

# InfraEnv — ISO generated? proxy set?
oc get infraenv <name> -n <ns> -o yaml | grep -A10 'proxy:\|ImageCreated\|isoDownloadURL'
```

| Observation | Stall phase | Focus |
|-------------|-------------|-------|
| No `Agent` CRs | Early boot / rootfs / agent start | `assisted-image-service` curl test from install VLAN; [agent-install-rootfs-ssl-failure.md](../../devops/rhacm/troubleshooting/agent-install-rootfs-ssl-failure.md) |
| Agents `discovering` / `known` | Agent→hub or validation | Agent `stateInfo`, assisted-service logs |
| Agents `ready`, install not starting | Approval / requirements | `AgentClusterInstall` conditions, `provisionRequirements` |
| Install `installing` then hang | Image pull / proxy during install | Install proxy, mirror, pull secret |

**Phase B — Proxy/cert from install network** (jump host on provisioning VLAN):

```bash
HUB_DOMAIN=<hub-apps-domain>
AIS="assisted-image-service-multicluster-engine.${HUB_DOMAIN}"
ASVC="assisted-service-multicluster-engine.${HUB_DOMAIN}"

dig +short "$AIS"
curl -v "https://${AIS}/boot-artifacts/rootfs?arch=x86_64&version=<ocp-version>" 2>&1 | tail -30
curl -vk "https://${ASVC}/api/assisted-install/v2/infra-envs" 2>&1 | tail -20

# If corporate proxy required on this VLAN:
curl -v -x http://<proxy>:<port> "https://${AIS}/boot-artifacts/rootfs?arch=x86_64&version=<ocp-version>"
```

**Phase C — Hub proxy alignment**:

```bash
oc get proxy cluster -o yaml
oc set env pod -n multicluster-engine -l app=assisted-image-service --list | grep -i proxy
oc set env pod -n multicluster-engine -l app=assisted-service --list | grep -i proxy
oc get proxy cluster -o jsonpath='trustedCA={.spec.trustedCA.name}{"\n"}'
```

### Result

Pending — awaiting phase identification and curl/agent output.

### Next

1. Someone with console or iDRAC KVM access captures **boot screen / serial** at stall point.
2. Run Phase A on hub; paste agent `stateInfo` and `InfraEnv` proxy block.
3. Run Phase B from install VLAN if network team can reach it.

---

## 2026-07-02 — Session 2: Dropped traffic on 9999 / 6385

### Situation

Nodes are booting (virtual media / discovery ISO path working). Network team reports **dropped traffic on TCP 9999 and 6385**. Prior proxy/cert hunch may be a red herring for this symptom — or an earlier-phase issue already passed.

### Evidence

| Port | Service | Direction | Network |
|------|---------|-----------|---------|
| **9999** | Ironic Python Agent (IPA) on each bare-metal node (ramdisk/live image) | **Inbound to node** from Ironic conductor | `provisioning` VLAN **or** `machineNetwork` / baremetal VLAN when provisioning network disabled |
| **6385** | Ironic API | **Inbound to bootstrap**, later control-plane nodes | Same — conductor/API plane during OCP install |
| **6180** / **6183** | HTTP(S) image server for Redfish virtual media | **BMC (OOB) → bootstrap/CP** | OOB management network → machine network |
| **443** | Assisted service / image service | Install host → hub ingress | Routable install network → hub (discovery phase) |

Ports 9999/6385 are **IPI/Ironic** ports documented in [OCP bare-metal IPI prerequisites](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_bare_metal/installer-provisioned-infrastructure). They are **not** Assisted Installer discovery ports (discovery agent uses **HTTPS outbound to hub only**).

**Implication:** Traffic on 9999/6385 means the workflow has likely entered the **OpenShift install / Ironic provisioning phase** (post-discovery), where bootstrap runs Ironic and conductor talks to IPA on each node. This is plain TCP — **not TLS/proxy** — so corporate HTTPS proxy and `trustedCA` fixes do not apply to these ports.

**Gen17 / iDRAC10 note (OCP 4.20):** Provisioning network **not tested** with iDRAC10. Red Hat recommends **virtual media** (`idrac-virtualmedia://`). With virtual media and no provisioning network, Ironic IPA traffic (9999) should traverse the **machine/baremetal network**, not a separate provisioning VLAN.

### Hypothesis (ranked)

1. **East-west firewall** between bootstrap/conductor IP and node IPs blocking TCP 9999 (most likely if drops observed during install).
2. **Wrong VLAN** — Ironic traffic expected on machine network but nodes/firewall still modeled for provisioning network (or vice versa).
3. **OOB virtual-media path blocked** — BMC cannot reach bootstrap on 6180/6183 (related, separate from 9999).
4. **Provisioning network enabled in install-config** but not cabled/firewalled for Gen17 virtual-media path (misconfiguration vs Red Hat guidance).
5. Proxy/cert issue on **443 to hub** — still valid for discovery phase, but **does not explain 9999/6385 drops**.

### Test plan

**A. Confirm install phase on hub:**

```bash
oc get agents -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,ROLE:.spec.role,STATE:.status.debugInfo.state,HOST:.spec.hostname
oc get agentclusterinstall -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} state={.status.debugInfo.state}{"\n"}{end}'
```

| Agent state | Meaning |
|-------------|---------|
| `discovering` / `known` | Still discovery — 9999 drops may be premature or from a parallel IPI attempt |
| `installing` | Ironic phase active — 9999/6385 firewall is the lead |
| `installing-pending-user-action` | Boot order / disk boot issue (different problem) |

**B. Characterize dropped flows (network team):**

Record for each drop: **src IP, dst IP, dst port, VLAN**, and whether dst is a **node machine IP** or **bootstrap/CP IP**.

| Pattern | Interpretation |
|---------|----------------|
| bootstrap/CP → node:9999 DROP | Open **TCP 9999 inbound to nodes** from bootstrap + CP ironic conductor IPs |
| client → bootstrap:6385 DROP | Open **TCP 6385** to bootstrap (then CP nodes after pivot) |
| BMC → CP:6180/6183 DROP | Virtual media image fetch blocked — open from OOB net to CP |
| node → hub:443 DROP | Back to proxy/cert / assisted-service path |

**C. Firewall rules to request (virtual media, no provisioning network):**

```
# Ironic conductor → IPA on each node (machine network)
ALLOW TCP <bootstrap-ip>, <cp-node-ips> → <all-node-machine-ips>:9999

# Ironic API (install clients / internal)
ALLOW TCP <installer-sources> → <bootstrap-ip>, <cp-node-ips>:6385

# Virtual media image streaming (OOB → machine network)
ALLOW TCP <bmc-subnet> → <bootstrap-ip>, <cp-node-ips>:6180
# If TLS virtual media:
ALLOW TCP <bmc-subnet> → <bootstrap-ip>, <cp-node-ips>:6183
```

Also verify **TCP 80** on machine network if image caching disabled (RHCOS stream from bootstrap).

**D. Install-config check** (if accessible on hub):

Confirm `provisioningNetwork: Disabled` for Gen17 virtual-media path. If `Managed` provisioning network is set without a working provisioning VLAN, Ironic may target wrong interface.

### Result

Pending — need flow direction (src/dst) and agent install state.

### Next

1. Network team: src/dst IPs for 9999 and 6385 drops.
2. Platform: `oc get agents` state — are hosts `installing`?
3. If installing: open east-west 9999/6385 on machine network; do not chase proxy for these ports.
4. Revisit proxy/cert only if 443-to-hub drops appear separately or agents never leave `discovering`.
