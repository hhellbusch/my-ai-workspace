# Checkpoint — 2026-08-13

**In progress:** Branch `docs/cross-dc-ingress-alternative` — ready for commit/PR after review fixes.

**Just completed (this session):**

- Overview reframed as **canonical hub** with corpus map and path-first structure
- `cross-dc-ingress-alternative.md` — Path B design, DNS/VIP handoff, verification
- `cross-dc-cluster-linking.md` slimmed to Kafka depth; points to hub
- `cross-dc-replication.md` path fork section
- Index updates: `kafka/README`, `messaging/README`, `networking/README`, `ocp/examples/README`
- Templates: DNS + ingress firewall change requests
- Examples: `ingress-replication/` (IngressController, MetalLB, keepalived), `cfk-kafka-route-replication.snippet.yaml`
- Inventory: `replicationPath`, `inventory-dc-a/b.ingress.example.yaml`, `render-config.py` branches
- **Ingress test framework:** `cross-dc-ingress-test/` — layered `preflight-ingress.sh` + `run-ingress-test.sh`
- Review fixes: relative links, Red Hat doc URLs, DC-B ingress inventory

**Not in scope (by design):**

- PoC/default-ingress path documentation
- Recording which path was chosen in production
- Cluster Link bootstrap runbook (still open)
- Live cluster trial (validate-local only)

**Next (when implementing a path):**

- Enrich the chosen path's guide from live cluster findings
- Multus: inventory → NNCP → `preflight.sh` / `run-network-test.sh` → Kafka net
- Ingress: NNCP → IngressController + frontend (VIP/MetalLB) → `preflight-ingress.sh` / `run-ingress-test.sh` → CFK route snippet → DNS/firewall tickets
