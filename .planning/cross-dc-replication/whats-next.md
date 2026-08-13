# Checkpoint — 2026-08-12

**In progress:** Opening PR for review — all local validation passes; no live cluster run yet.

**Just completed (this session):**

- Cross-DC network test framework (`run-network-test.sh`, `preflight.sh`, manifests, `repl-net-probe` UBI9 image docs)
- NNCP Helm chart (per-node static host IPs)
- Rollout inventory + `render-config.py` (projects to NNCP values, `dc-*.env`, Kafka net values)
- Kafka net Helm chart (whereabouts + static broker IP modes, `broker-ip-map` ConfigMap)
- Pre-flight documentation in architecture overview + rollout README
- `validate-local.sh` local gate; review frontmatter + link checks pass
- Project brief backfilled from session transcript

**Next step (live trial order):**

1. Copy `inventory-dc-*.example.yaml` → gitignored `inventory-dc-*.yaml`; fill real values
2. `python3 render-config.py --both --firewall-request firewall-change-request.md`
3. Network team: approve firewall ticket (pod IP pools or static broker /32s)
4. Both clusters: `useMultiNetworkPolicy` patch → NNCP Helm → `./preflight.sh` → `./run-network-test.sh`
5. Choose broker IPAM mode (`BROKER-IPAM.md`); apply Kafka net Helm; wire CFK listeners + Cluster Links

**Git:** `88b2e59` — `Add cross-DC replication rollout tooling and pre-Kafka network verification.` (branch `feature/cross-dc-replication-rollout`)

**Not committed locally:** Generated `values-dc-*.yaml`, `dc-*.env` (gitignored test renders — safe to delete).
