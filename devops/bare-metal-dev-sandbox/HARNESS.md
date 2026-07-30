# Preflight harness — scenario-driven validation gate PoC

## Purpose

Encode bare-metal **validation gate** checks as stable IDs and regression-test them with
scenario YAML plus a local Redfish mock (sushy-static). Matches the common preflight pattern:
accumulate findings, fail once at the end.

## Tooling choice

| Tool | Role in PoC | ACM / ABI ecosystem fit |
|------|-------------|-------------------------|
| **Ansible** (implemented) | Validation gate playbooks → ClusterCurator prehooks, AAP | Primary — same path as production |
| **Scenario YAML** | Declarative inputs + expected findings | CI matrix, documentation |
| **sushy-static** | BMC Redfish mock | G1 sandbox |
| **Python helpers** | Load/assert scenarios only | Thin harness glue |
| **Go** (not implemented) | assisted-service is Go | Optional future CLI; heavier for ops teams running AAP |

Keep **check logic in Ansible** for production integration; use this harness for
contract/regression tests. A Go binary could later consume `catalog/checks.yaml` if a
standalone install-workstation CLI is needed.

## Two fidelity axes

| Axis | Question it answers | Values |
|------|---------------------|--------|
| **G-tier** (README) | What infrastructure is required? | G0 syntax → G1 mock BMC → G2 hub → G4 iron |
| **Validation mode** (scenarios) | How does each check get its inputs? | `harness` simulated · `hybrid` real TCP + scenario inputs · `live` real probes |

A passing **G1** smoke test means Redfish client ops work against sushy. A passing **harness**
scenario suite means the validation gate logic and check IDs regress correctly — mostly
independent claims.

## Packaged scenarios

| Check ID | Scenario file | What it exercises |
|----------|---------------|-------------------|
| `hub_ocp_version_idrac10` | `02-hub-ocp-version-below-minimum.yaml` | Hub version below configured minimum |
| `network_firewall_install_ports` | `03-firewall-ironic-blocked.yaml` | Harness: TCP 9999 `state: closed` |
| `network_firewall_install_ports` | `05-network-hybrid-open.yaml` | Hybrid: real probes, all `mock_listener: true` |
| `network_firewall_install_ports` | `06-network-hybrid-closed.yaml` | Hybrid: 9999 closed (`mock_listener: false`) |
| `network_firewall_install_ports` | `08-firewall-ironic-api-blocked.yaml` | Harness: TCP 6385 `state: closed` |
| `network_firewall_install_ports` | `09-network-hybrid-ironic-api-closed.yaml` | Hybrid: 6385 closed, 9999 open |
| `bmc_virtual_media_privilege` | `04-idrac-readonly-virtualmedia.yaml` | Non-administrator BMC role |
| `bmc_redfish_authentication` | `07-bmc-auth-failure.yaml` | Wrong password; privilege check gated off |
| *(multi)* | `10-kitchen-sink-fail.yaml` | Hub + privilege + firewall (max co-occurring) |
| *(multi)* | `11-kitchen-sink-auth-gated.yaml` | Hub + auth + firewall; privilege gated off |
| *(none)* | `01-baseline-pass.yaml` | Golden path — no blocking findings |

Default install ports in catalog: **6180, 6183, 9999, 6385**.

## Modes

- **`harness`** — inputs from scenario YAML; firewall and BMC privilege checks use simulated
  state (no real network/BMC required except optional sushy for auth probe).
  Firewall: set `state: open|closed` per check — no TCP probe.
- **`hybrid`** — same scenario-driven inputs as harness, but firewall checks use real
  `wait_for` TCP probes. Open paths: set `mock_listener: true` (harness starts a local
  listener before Ansible runs). Closed paths: `mock_listener: false` or omit — probe fails
  like a blocked firewall.
- **`live`** — `oc` for hub version, `wait_for` for TCP, `redfish_info` for BMC (run on bastion/hub).
  No mock listeners — targets must be real endpoints. Template: `examples/live-preflight-vars.example.json`.

## Quick start

```bash
cd devops/bare-metal-dev-sandbox
ansible-galaxy collection install -r requirements.yml
chmod +x scripts/*.sh scripts/*.py

# One scenario
./scripts/run-scenario.sh 01-baseline-pass.yaml

# Full regression suite
./scripts/run-all-scenarios.sh

# G0 syntax + full regression
./scripts/check.sh
```

### Live mode (real hub / BMC / network)

```bash
cp examples/live-preflight-vars.example.json ~/live-preflight.json
# edit BMC IPs and firewall targets in ~/live-preflight.json

export BMC_USERNAME=root BMC_PASSWORD=...
./scripts/run-live.sh ~/live-preflight.json

# TCP probes from bastion (not laptop):
cp examples/live-inventory.example.ini ~/live-inventory.ini
# set ansible_host on [probe_hosts] bastion
INVENTORY=~/live-inventory.ini ./scripts/run-live.sh ~/live-preflight.json
```

- **Secrets:** `BMC_USERNAME` / `BMC_PASSWORD` env vars (merged by `merge-live-vars.py`)
- **Hub version:** `oc` on the machine running the playbook; kubeconfig must point at hub
- **Firewall:** one aggregated `network_firewall_install_ports` finding lists all bad paths
- **probe_from:** `local` = controller; inventory hostname = delegated `wait_for`

Reports land in `artifacts/scenarios/<name>/preflight-report.json` (gitignored).
Live reports: `artifacts/live/preflight-report.json` (or `PREFLIGHT_REPORT_PATH`).

## Add a scenario

1. Copy `scenarios/01-baseline-pass.yaml`
2. Set `inputs` to reproduce the failure
3. Set `expect.exit_code`, `expect.blocking[].id`, and optionally `expect.not_blocking[]`
4. Run `./scripts/run-scenario.sh your-scenario.yaml`

## Layout

```
catalog/checks.yaml          # stable check IDs + documentation
scenarios/*.yaml             # inputs + expected outcomes
roles/preflight_validate/    # validation gate implementation
scripts/run-scenario.sh      # orchestrator (mock + ansible + assert)
scripts/run-live.sh            # live mode wrapper
artifacts/                   # generated reports (gitignored)
```

## Limits

- Static sushy does not enforce Dell iDRAC RBAC — privilege checks use **harness simulation** in
  `validation_mode: harness`; use `live` against a real BMC for fidelity.
- sushy-static does not enforce HTTP basic auth — harness scenarios use `credentials.auth_ok: false`
  to simulate auth failure; `live` mode probes real BMC credentials.
- Firewall checks in harness mode read scenario `state: open|closed`, not real firewall rules.
- Hybrid mode exercises real TCP connect behavior without external infrastructure — see
  `05-network-hybrid-open.yaml` and `06-network-hybrid-closed.yaml`.
- Hub version in harness mode reads scenario inputs, not `oc`.

## Example credentials

Scenarios use placeholder BMC credentials (`root` / `calvin`) against the local mock only.
Do not reuse production passwords in scenario files committed to git.
