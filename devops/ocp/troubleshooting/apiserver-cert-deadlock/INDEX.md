# API Server Certificate Deadlock — Index

Navigate by symptom, access constraint, or remediation step.

## Start Here

| I need to… | Go to |
|------------|-------|
| Triage fast (2 min) | [QUICK-REFERENCE.md](QUICK-REFERENCE.md) — Decision tree + §0 |
| Understand the full flow | [README.md](README.md) |
| Break in when API TLS fails but `curl -k` works | [README — Triage](README.md#triage-unreachable-vs-untrusted) |
| Reach a master when bastion SSH fails | [README — Access Constraints](README.md#access-constraints) |
| Fix after custom CA / API cert rollout | [README — Common Trigger](README.md#common-trigger-custom-ca-or-api-cert-rollout) + [Step 5](README.md#step-5-user-provided-api-server-certificates-openshift-config) |

## By Symptom

| Symptom | Section |
|---------|---------|
| `oc`: `x509: certificate signed by unknown authority` | [Triage](README.md#triage-unreachable-vs-untrusted) → this guide |
| `curl -k .../healthz` ok, `oc get` fails TLS | [Triage](README.md#triage-unreachable-vs-untrusted) |
| Web console down, CLI TLS errors | Fix API trust first — [Symptoms](README.md#symptoms) |
| `connection refused` / `timeout` to API | [CoreOS Networking](../coreos-networking-issues/README.md) — may not be cert-only |
| MAC flapping / issuer changes between `openssl` runs | [Stale node IP conflict](../bare-metal-stale-node-ip-conflict/README.md) — fix before cert work |
| `unknown authority` on worker MCS :22623 | [Worker Node TLS](../worker-node-tls-cert-failure/README.md) — different scope |
| `tls: private key does not match public key` | [Step 2](README.md#step-2-identify-the-failing-certificate) — cert/key pair mismatch |

## By Access Path

| What you have | Path |
|---------------|------|
| Bastion + admin kubeconfig, TLS error only | [QUICK-REFERENCE §1](QUICK-REFERENCE.md#1-emergency-oc-triage-only--not-a-permanent-fix) (`--insecure-skip-tls-verify`) |
| SSH to worker only | [Access Constraints](README.md#worker-only-ssh) → worker hop → localhost kubeconfig |
| SSH to control plane node | [Step 1](README.md#step-1-get-access-break-the-deadlock) |
| No SSH to any master; worker hop fails | BMC for boot/power observation; filesystem fix needs master access eventually |
| localhost kubeconfig works on master | [Steps 2–3](README.md#step-2-identify-the-failing-certificate) |
| localhost kubeconfig also fails TLS | [Step 4](README.md#step-4-when-the-api-is-not-reachable-at-all-manual-fix-on-node) |

## By Remediation

| Goal | Section |
|------|---------|
| Re-issue from internal signer | [Step 3 Option A](README.md#option-a-you-want-the-cluster-to-re-issue-internal-signer) |
| Apply corporate / custom cert | [Step 3 Option B](README.md#option-b-you-have-your-own-cert-and-key-eg-from-vault) + [Step 5](README.md#step-5-user-provided-api-server-certificates-openshift-config) |
| Operator not reconciling | [Step 3 Option C](QUICK-REFERENCE.md#7-operator-not-syncing--restart-operator-then-api) |
| Manual fix on node filesystem | [Step 4](README.md#step-4-when-the-api-is-not-reachable-at-all-manual-fix-on-node) |

## Related Guides

- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) — localhost kubeconfig details
- [Failed OCP Install](../failed-ocp-install/README.md) — routes here for API TLS errors during install
- [API Slowness and Web Console](../api-slowness-web-console/README.md) — performance issues when API is trusted but slow
- [CSR Management](../csr-management/README.md) — node client cert approval (different from serving cert deadlock)
