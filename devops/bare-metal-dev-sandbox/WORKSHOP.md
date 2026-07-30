# Workshop — Bare Metal Dev Sandbox & Preflight Harness

Hands-on guide for running, learning, and teaching the framework. Read this before
[README.md](README.md) (reference) or [HARNESS.md](HARNESS.md) (implementation notes).

**Time:** ~45–60 minutes solo; ~90 minutes with a peer group including discussion.

**Audience:** Platform engineers who work on ACM bare-metal installs, BMC/Redfish
automation, or pre-install validation — and who may not have spare hardware on their laptop.

---

## What you are learning

Three ideas bundled together:

1. **Sandbox (G1)** — A fake BMC on your machine (`sushy-static`) so Redfish Ansible
   playbooks can run without physical servers.
2. **Validation gate** — Preflight checks that **accumulate findings** and **fail once at
   the end** (same pattern as a production bare-metal preflight spec).
3. **Scenario harness** — YAML files that describe inputs + expected failures, so checks
   become **regression tests** you can run in CI or teach with reproducibly.

```text
                    ┌─────────────────────────────────────┐
  scenarios/*.yaml  │  run-scenario.sh                    │
  (inputs + expect) │    → start Redfish mock (optional)  │
                    │    → ansible validation-gate.yml    │
                    │    → assert-scenario.py             │
                    └──────────────┬──────────────────────┘
                                   ▼
                    ┌─────────────────────────────────────┐
                    │  roles/preflight_validate           │
                    │    hub / bmc / network checks       │
                    │    → preflight-report.json          │
                    └─────────────────────────────────────┘
```

**Production path (later):** The same Ansible role runs in `live` mode from a bastion or
as a ClusterCurator prehook — scenarios stay the contract tests for `harness` mode.

---

## Prerequisites

Install on a Linux workstation (Fedora/RHEL recommended). macOS works with podman desktop
with minor path differences.

| Tool | Verify | Install hint |
|------|--------|--------------|
| `podman` | `podman --version` | `dnf install podman` |
| `ansible` | `ansible --version` (2.15+ core) | `dnf install ansible-core` or `pip install ansible-core` |
| `python3` + PyYAML | `python3 -c "import yaml"` | `dnf install python3-pyyaml` |
| `curl` | `curl --version` | usually present |
| `openssl` | `openssl version` | for auto-generated sandbox TLS cert |

Optional for `live` mode labs (not required for this workshop):

- `oc` with kubeconfig pointed at an ACM hub
- Network path to real BMC IPs from your probe host

Clone or open the repo and go to the sandbox directory:

```bash
cd devops/bare-metal-dev-sandbox
```

One-time setup:

```bash
ansible-galaxy collection install -r requirements.yml
chmod +x scripts/*.sh scripts/*.py
```

---

## Lab 0 — Verify the Redfish mock (5 min)

**Goal:** Confirm podman can serve a local BMC endpoint.

```bash
./scripts/start-static.sh
```

Expected output includes:

```text
static Redfish BMC: https://127.0.0.1:8000/redfish/v1/
```

Probe it:

```bash
curl -sk https://127.0.0.1:8000/redfish/v1/ | python3 -m json.tool | head -20
```

You should see JSON with `"Managers"` and `"Systems"` links.

**What happened:** `start-static.sh` runs `quay.io/metal3-io/sushy-tools` with
`sushy-static`, mounting `fixtures/static-redfish/redfish/v1/` as the Redfish tree.
A self-signed TLS cert is generated under `fixtures/certs/` (gitignored) because
`community.general.redfish_*` expects HTTPS.

Teardown (optional for now):

```bash
./scripts/stop-static.sh
```

---

## Lab 1 — Smoke test Ansible against the mock (10 min)

**Goal:** Prove `redfish_info` talks to the sandbox the same way it would to a real BMC.

```bash
./scripts/start-static.sh
ansible-playbook playbooks/smoke-redfish.yml
./scripts/stop-static.sh
```

**PASS** ends with:

```text
G1 sandbox OK — redfish_info returned VirtualMedia CD (Virtual CD)
```

**Inspect:** Open `playbooks/smoke-redfish.yml`. Note:

- `baseuri` is `127.0.0.1:8000`
- `validate_certs: false` (self-signed cert)
- Credentials default to `root` / `calvin` — **lab placeholders only**, override with env:

```bash
BMC_USER=root BMC_PASSWORD=calvin ansible-playbook playbooks/smoke-redfish.yml
```

**Discussion point for peers:** This is **G1** in the fidelity table — it validates your
*client code*, not Dell firmware behavior.

---

## Understanding `run-all-scenarios` output

Ansible’s default output is noisy. **Skipped and failed tasks are often correct.** Use the
**`── ansible recap`** block printed after each scenario (before `PASS` / `FAIL`) as the
readable summary.

### Two different “success” signals

| Signal | Meaning |
|--------|---------|
| **`PLAY RECAP` … `failed=1`** | Ansible’s aggregate gate task failed because blocking findings exist — **expected** on scenarios 02–04 |
| **`PASS <scenario-name>`** (last line from harness) | Scenario **expectations matched** — exit code and finding IDs were what we wanted |

So scenario 02 **should** show `fatal: [localhost]: FAILED!` on the assert task **and** `PASS hub-ocp-version-below-minimum`.

### PLAY RECAP by scenario

| Scenario | ok | failed | skipped | Expected? |
|----------|-----|--------|---------|-----------|
| `01-baseline-pass` | ~16 | **0** | ~16 | Yes — golden path |
| `02-hub-ocp-version-below-minimum` | ~17 | **1** | ~14 | Yes — one gate failure |
| `03-firewall-ironic-blocked` | ~17 | **1** | ~14 | Yes |
| `04-idrac-readonly-virtualmedia` | ~17 | **1** | ~14 | Yes |

The **single failed task** is always:

```text
Aggregated gate — assert no blocking findings
```

That is the validation gate doing its job — not a bug.

### Why so many **skipped** tasks?

Tasks skip when a **condition does not apply**. In `validation_mode: harness` (all packaged scenarios):

| Skip you will see | Reason |
|-------------------|--------|
| `Hub version check — skip when iDRAC generation not 10` | Only runs when `inputs.hub.idrac_generation` is `"10"` |
| `record finding when below minimum` | Skipped on baseline — version is OK |
| `warn when version string empty in live mode` | Harness mode — no `oc` lookup |
| `fail when inventory empty` / `password empty` | Inputs are valid in packaged scenarios |
| `accumulate auth failures` | Auth probe returned HTTP 200 |
| `record finding for non-administrator` | Skipped on baseline — role is `administrator` |
| `probe VirtualMedia via redfish_info` | **Live-mode only** — harness uses scenario role instead |
| `attempt boot option read` | **Live-mode only** |
| `record closed paths from scenario` | Skipped when firewall `state: open` (harness only) |
| `probe each target` (wait_for) | **Hybrid/live only** — harness uses `state` instead |
| `print warnings` / `print blocking findings` | Skipped when that list is empty |

Rough rule: **~half the task list is the live-mode path** you are not exercising in the workshop.

### Warnings you can ignore

```text
[WARNING]: Host 'localhost' is using the discovered Python interpreter...
```

Ansible 2.20+ interpreter discovery notice — not a harness failure.

### When to worry

| Symptom | Likely problem |
|---------|----------------|
| `FAIL <scenario>` at end (not `PASS`) | Scenario `expect` does not match report — logic or scenario bug |
| `failed` on **BMC credentials — probe each endpoint** | Redfish mock not running or wrong port |
| `cannot remove container ... stopping` | Podman race between scenarios — run `podman rm -f bare-metal-sandbox-redfish`, retry |
| `all scenarios passed` missing | One or more `FAIL` lines above |

### Quieter Ansible output (optional)

```bash
ANSIBLE_DISPLAY_SKIPPED_HOSTS=false ansible-playbook playbooks/validation-gate.yml -e "@${EXTRA_VARS}"
```

Skips are hidden but the recap still shows `skipped=N`.

---

## Lab 2 — Run the full scenario regression suite (10 min)

**Goal:** See the harness run four packaged scenarios and assert pass/fail automatically.

```bash
./scripts/run-all-scenarios.sh
```

Expected final line:

```text
all scenarios passed
```

Each scenario prints `PASS <name>` and writes a report under `artifacts/scenarios/`
(gitignored — safe to delete anytime).

**Run one scenario with visibility:**

```bash
./scripts/run-scenario.sh 02-hub-ocp-version-below-minimum.yaml
```

Ansible output shows `BLOCKING [hub_ocp_version_idrac10]: ...` then exits non-zero —
that is **expected** for a negative test. The harness wrapper still prints `PASS` because
the *scenario expectation* matched (exit code 2 + that finding ID).

**Read the report:**

```bash
cat artifacts/scenarios/02-hub-ocp-version-below-minimum/preflight-report.json
```

Example structure:

```json
{
    "blocking": [
        {
            "id": "hub_ocp_version_idrac10",
            "message": "Hub OpenShift 4.19.6 is below minimum 4.20.0 ..."
        }
    ],
    "warnings": []
}
```

---

## Lab 3 — Map scenarios to check IDs (15 min)

Open [catalog/checks.yaml](catalog/checks.yaml) alongside the scenario files.

| Scenario | Simulated problem | Check ID |
|----------|-------------------|----------|
| `01-baseline-pass.yaml` | Everything OK | *(none)* |
| `02-hub-ocp-version-below-minimum.yaml` | Hub OCP below minimum for iDRAC10 | `hub_ocp_version_idrac10` |
| `03-firewall-ironic-blocked.yaml` | TCP 9999 closed on install path | `network_firewall_install_ports` |
| `04-idrac-readonly-virtualmedia.yaml` | BMC user lacks Virtual Media admin | `bmc_virtual_media_privilege` |

**Exercise:** For scenario 03, open the YAML and find:

```yaml
firewall_checks:
  - id: ironic-ipa
    port: 9999
    state: closed   # ← harness simulates a blocked port
```

Change `closed` → `open`, re-run:

```bash
./scripts/run-scenario.sh 03-firewall-ironic-blocked.yaml
```

The assert step should **FAIL** (scenario expected a blocking finding but got none).
Revert the change when done.

**Teaching moment:** Scenarios are **executable documentation** of what each check ID means.

---

## Lab 4 — Walk through the validation gate code (10 min)

Playbook entry point:

```bash
ansible-playbook playbooks/validation-gate.yml --list-tasks
```

Role tasks live in `roles/preflight_validate/tasks/`:

| File | Responsibility |
|------|----------------|
| `check_hub_version.yml` | Compare hub OCP version to configured minimum when `idrac_generation: "10"` |
| `check_bmc_credentials.yml` | GET `/redfish/v1/` per BMC; gates hardware checks on auth failure |
| `check_virtual_media_privilege.yml` | Harness: read `virtual_media_privilege`; Live: `redfish_info` probes |
| `check_firewall_ports.yml` | Harness: `state: open\|closed`; Hybrid/live: `wait_for` TCP |
| `aggregate_gate.yml` | Print findings, write JSON report, assert empty blocking list |

**Design rules (match production preflight spec):**

- Checks append to `preflight_findings` — they do not fail immediately (except variable integrity in full spec).
- BMC hardware checks skip when credentials fail; credential failures re-appear at aggregate gate.
- Warnings print but do not block.

---

## Lab 5 — Add your own scenario (15 min)

**Goal:** Encode a new failure mode as a regression test.

1. Copy the baseline:

```bash
cp scenarios/01-baseline-pass.yaml scenarios/07-my-check.yaml
```

2. Edit `name`, `description`, and `expect` — e.g. simulate two blocking findings:

```yaml
expect:
  exit_code: 2
  blocking:
    - id: hub_ocp_version_idrac10
    - id: network_firewall_install_ports
```

3. Break both inputs in `inputs:` (low hub version + one `state: closed` firewall check).

4. If the check ID is new, add it to `catalog/checks.yaml` **first** — stable IDs are the contract between harness, reports, and production.

5. Run:

```bash
./scripts/run-scenario.sh 07-my-check.yaml
```

6. Add to the suite: `run-all-scenarios.sh` already runs `scenarios/*.yaml` — no script change needed.

**Peer review checklist for a new scenario:**

- [ ] `expect.blocking[].id` exists in `catalog/checks.yaml`
- [ ] Scenario name/description explain the failure without environment-specific story
- [ ] No production passwords — placeholders only
- [ ] `validation_mode: harness` unless you intend to require live infrastructure

---

## Harness mode vs hybrid vs live

| | `harness` | `hybrid` | `live` |
|--|-----------|----------|--------|
| **Hub version** | From scenario `inputs` | From scenario `inputs` | `oc get clusterversion` |
| **Firewall** | `state: open\|closed` (simulated) | Real `wait_for`; `mock_listener` starts local open port | Real `wait_for` against install path |
| **BMC privilege** | From `virtual_media_privilege` | Same as harness | `redfish_info` against real BMC |
| **Needs hardware** | No (optional sushy for auth GET) | No — mock TCP listeners only | Yes |
| **Use case** | Laptop, CI, teaching | Regression with real connect semantics | Bastion / prehook before install |

**Hybrid open/closed** — in `validation_mode: hybrid`, set per firewall check:

```yaml
firewall_checks:
  - id: ironic-ipa
    port: 9999
    mock_listener: true   # harness starts 127.0.0.1:9999 before Ansible
    targets:
      - host: "127.0.0.1"
        port: 9999
  - id: blocked-path
    port: 6385
    mock_listener: false  # no listener — wait_for fails (closed connection)
    targets:
      - host: "127.0.0.1"
        port: 6385
```

Try the packaged hybrid scenarios:

```bash
./scripts/run-scenario.sh 05-network-hybrid-open.yaml
./scripts/run-scenario.sh 06-network-hybrid-closed.yaml
```

Run live mode (when you have a hub and BMC):

```bash
# Example — build extra-vars by hand or from inventory, not from scenario file
ansible-playbook playbooks/validation-gate.yml \
  -e preflight_validation_mode=live \
  -e preflight_report_path=/tmp/preflight-live.json \
  -e '{"preflight_inputs": { ... }}'
```

Start with harness until scenarios pass; promote the same role to live on shared lab infrastructure.

---

## Teaching outline for peers

### 30-minute brown bag

1. Problem: bare-metal preflight needs hardware; developers need faster feedback (5 min)
2. Demo: `start-static.sh` + `smoke-redfish.yml` (5 min)
3. Demo: one failing scenario + read `preflight-report.json` (10 min)
4. Show `catalog/checks.yaml` ↔ scenario mapping (5 min)
5. Q&A: harness vs live, how this plugs into AAP / ClusterCurator (5 min)

### 90-minute hands-on session

| Block | Activity |
|-------|----------|
| 0–15 min | Concepts: fidelity tiers, validation gate, scenarios |
| 15–30 min | Lab 0–1 on their machines (helpers circulate) |
| 30–45 min | Lab 2–3: regression suite + break scenario 03 |
| 45–60 min | Lab 4: walk role tasks on projector |
| 60–80 min | Lab 5: each pair adds one scenario |
| 80–90 min | Retro: which checks belong in harness vs live for your fleet |

**Materials to share:**

- This file (`WORKSHOP.md`)
- Link to [agent-install-preflight.md](../rhacm/notes/agent-install-preflight.md) for where validation gate fits in ACM lifecycle
- Link to [Ambler sandboxes](https://agiledata.org/essays/sandboxes.html) for tier vocabulary

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `podman: command not found` | Podman not installed | Install podman |
| `curl: connection refused` on :8000 | Mock not running | `./scripts/start-static.sh` |
| `SSL: WRONG_VERSION_NUMBER` in Ansible | Using `http://` against HTTPS mock | Use smoke playbook defaults (HTTPS) |
| `community.general.redfish_info` missing | Collection not installed | `ansible-galaxy collection install -r requirements.yml` |
| Scenario assert FAIL but playbook looked right | `expect.blocking` IDs don't match report | Compare `preflight-report.json` to scenario `expect` |
| `Sub-URI not found` from sushy | Wrong mockup mount path | Fixtures must mount at `.../redfish/v1/` (see `start-static.sh`) |
| Container already exists | Previous run left podman container | `./scripts/stop-static.sh` |

Clean generated output:

```bash
rm -rf artifacts/
./scripts/stop-static.sh
./scripts/stop-mock-tcp.sh
```

---

## What this framework does *not* replace

- **Node preparation** (CoreOS boot, MAC discovery, lock files) — needs real or dynamic BMC + VMs
- **Assisted Installer agent validations** — need discovery ISO boot and `Agent` CRs on hub
- **Full production preflight** — bastion MTU, Satellite, VIP/F5 probes, package repos — extend the role with more tasks and scenarios

Those layers sit at **G2–G4** in the fidelity model. This sandbox owns **G0–G1** and the harness pattern for a growing slice of the validation gate.

---

## Next steps after the workshop

1. Run `./scripts/run-all-scenarios.sh` before opening PRs that touch `roles/preflight_validate/`.
2. Port checks from your production preflight spec into `catalog/checks.yaml` + scenarios.
3. Run the same role in `live` mode on a bastion against lab BMCs.
4. Wire the role into ClusterCurator prehooks when checks are stable ([preflight orchestration map](../rhacm/notes/agent-install-preflight.md)).

---

## Quick reference

```bash
# Full local workshop run
cd devops/bare-metal-dev-sandbox
ansible-galaxy collection install -r requirements.yml
chmod +x scripts/*.sh scripts/*.py
./scripts/start-static.sh
ansible-playbook playbooks/smoke-redfish.yml
./scripts/run-all-scenarios.sh
./scripts/stop-static.sh
```
