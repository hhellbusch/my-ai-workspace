# Bare Metal Stale Node IP Conflict — Index

Navigate by symptom, task, or recovery phase.

## Start Here

| I need to… | Go to |
|------------|-------|
| Triage in 2 minutes | [QUICK-REFERENCE.md](QUICK-REFERENCE.md) — Decision tree + §0 |
| Full procedure | [README.md](README.md) |
| Confirm duplicate IP / MAC flapping | [README — Triage](README.md#triage-ip-conflict-vs-certificate-vs-network-down) |
| Decommission retired control-plane hardware | [Step 4 — Wipe disks](README.md#step-4-wipe-rhcos--control-plane-state-from-stale-disks) |

## By Symptom

| Symptom | Section |
|---------|---------|
| API intermittently unreachable | [Triage](README.md#triage-ip-conflict-vs-certificate-vs-network-down) |
| `openssl` issuer changes between attempts | [Triage](README.md#triage-ip-conflict-vs-certificate-vs-network-down) → isolate stale nodes |
| `x509: unknown authority` but MAC flaps | [Overview](README.md#overview) — fix IP first, then [cert deadlock](../apiserver-cert-deadlock/README.md) |
| SSH to control-plane IP hits wrong serial | [Step 1 — Identify](README.md#step-1-identify-old-vs-new-hardware) |
| Console/oauth degraded | Downstream — stabilize API path first |
| Node "comes back" after shutdown | [Step 4 — Wipe](README.md#step-4-wipe-rhcos--control-plane-state-from-stale-disks) |

## By Task

| Task | Section |
|------|---------|
| ARP / MAC flapping test | [QUICK-REFERENCE §0](QUICK-REFERENCE.md#0-confirm-ip-conflict) |
| BMC power off + boot policy | [Step 2](README.md#step-2-isolate-stale-nodes-immediately) |
| Delete stale Node / BareMetalHost | [Step 3](README.md#step-3-remove-stale-objects-from-the-cluster) |
| Wipe disks via SSH | [Step 4 Option A](README.md#option-a-ssh-to-the-stale-host) |
| Wipe via BMC live ISO | [Step 4 Option B](README.md#option-b-bmc-virtual-media--live-iso) |
| iDRAC / PERC storage erase | [Step 4 Option C](README.md#option-c-raid-controller--idrac-storage-erase-dell-and-similar) |
| Verify before cert work | [Step 5](README.md#step-5-bring-up-current-hardware-only) |

## Related Guides

- [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) — After ARP and `openssl` output are stable
- [Control Plane Kubeconfigs](../control-plane-kubeconfigs/README.md) — localhost kubeconfig on current masters
- [Destroy Cluster Without Metadata — Bare Metal](../destroy-cluster-without-metadata/BAREMETAL-GUIDE.md) — Full cluster teardown and reuse
- [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) — Active host provisioning issues
- [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md) — MCS :22623 scope only
