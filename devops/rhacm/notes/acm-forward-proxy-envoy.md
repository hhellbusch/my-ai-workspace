---
review:
  status: unreviewed
  notes: "AI-drafted 2026-10-29 from architecture discussion (dual ACM hubs + Envoy). Recommends local Envoy front door → boundary Envoy / WWW / direct. Illustrative CONNECT DFP sample. Not yet validated against a live Envoy + ACM environment."
---

# ACM and OCP with a corporate Envoy forward proxy

**Audience:** Platform engineers designing or implementing RHACM + OpenShift when non-prod clusters cannot reach management APIs (hub, vCenter, storage) without a forward proxy.

**Purpose:** Recommend a **local Envoy front door** for non-prod clusters (fan-out to boundary Envoy, WWW proxy, or direct), map dual ACM hubs (prod / non-prod), and show the OpenShift / ACM knobs that point at that front door.

**Not this note:** ACM's **Cluster Proxy** add-on (hub → spoke kubectl tunnel). That is a different product feature. This note is about **HTTP(S) forward proxies** (Envoy) for egress from restricted networks.

---

## Problem shape

A single **prod ACM hub** managing both prod and non-prod fleets forces non-prod clusters to open API paths into the prod management plane.

Typical constraints:

- Non-prod clusters may not talk "up" across the prod / non-prod boundary without a proxy.
- Only some destinations need that path (ACM hub, vCenter / infra APIs) — not necessarily every internet host.
- General WWW egress may already go through a separate corporate proxy (or stay direct).
- Prod and non-prod fleet management should be segregated (common consulting recommendation; also gives a non-prod ACM to test upgrades and policies).

**Target posture (ACM Opt A):**

| Role | Manages |
|------|---------|
| Prod ACM hub | Prod managed clusters |
| Non-prod ACM hub | Non-prod managed clusters |

Splitting hubs removes "non-prod talking to **prod** ACM."
It does **not** remove the proxy path if non-prod still cannot reach the **non-prod** hub or infrastructure APIs directly.

---

## Recommended shape — local Envoy front door

OpenShift exposes **one** cluster-wide proxy URL (`Proxy` named `cluster`).
It cannot express “ACM and vCenter via boundary proxy, internet via WWW proxy, internals direct” by itself.

**Recommendation:** run a **local Envoy** that non-prod clusters can reach, and put **only that URL** in OCP / ACM config.
Local Envoy decides the next hop by destination class:

```text
non-prod OCP cluster
  Proxy/cluster ──► local Envoy :8080
                         │
                         ├─ CONNECT / tunnel ──► boundary Envoy ──► ACM hub, vCenter, …
                         │                      (allowed assets across prod/non-prod boundary)
                         │
                         ├─ chain (HTTP proxy) ──► corporate WWW proxy ──► internet
                         │                      (registries, RH content, Git, …)
                         │
                         └─ direct / reject     ──► already-reachable hosts, or deny
                                                    (prefer cluster noProxy for true direct)
```

| Destination class | Local Envoy action |
|-------------------|--------------------|
| ACM hub API / apps, vCenter, storage APIs on the management side | Tunnel toward **boundary Envoy** (or straight to the asset if local Envoy can reach it) |
| General internet | Forward to the **WWW** proxy |
| In-cluster / already-allowed nets | Keep off the proxy via OpenShift `noProxy` (never hits local Envoy) |

**Why this shape**

- Clusters only learn one proxy URL — destination policy lives in Envoy, where allowlists belong.
- Boundary Envoy stays focused on **allowed cross-boundary assets**; WWW stays on the existing internet path.
- Avoids stuffing an unmaintainable `noProxy` list just to fake selective proxying.

**When to skip the local hop:** non-prod nodes can already use the boundary Envoy as `Proxy`/`cluster`, and that Envoy (or an upstream) also covers WWW.
Then point clusters at the boundary Envoy directly — same CONNECT rules, one less hop.

**Still not this:** ACM Cluster Proxy add-on.

---

## Envoy requirements (must-haves)

For Kubernetes / ACM API traffic (especially klusterlet ↔ hub **6443**), the proxy must:

1. Support **HTTP CONNECT** tunneling (or equivalent TCP tunnel).
2. **Not terminate TLS** on hub API or spoke API sessions — hub ↔ managed cluster uses **mTLS**; MITM breaks registration.
3. Allow CONNECT (or tunnel) to the real destinations: hub API (`:6443`), hub ingress (`:443`), and any infrastructure APIs that spokes or hubs must call (for example vCenter `:443`).

Optional but common:

- Client auth (basic auth in the proxy URL, mTLS to Envoy, or source allowlists).
- TLS inspection only for destinations that are **not** mTLS ACM control plane — and then a proxy CA in the cluster trust bundle.

If Envoy is only an HTTP reverse proxy or terminates TLS to backends, it is the wrong shape for klusterlet registration.

### Sample local Envoy listener (HTTP CONNECT)

Illustrative **dynamic forward proxy** on the **local** front door: accept CONNECT on `:8080`, resolve the requested host, tunnel TCP without terminating client TLS.

Production local Envoy adds destination-class routing (boundary vs WWW vs deny) on top of this skeleton — the snippet below is the CONNECT core only.
Align typed configs with your Envoy minor version; see [Dynamic forward proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/dynamic_forward_proxy_filter).

```yaml
# local-envoy-connect.yaml — cluster-facing front door (CONNECT core)
# Next-hop fan-out (boundary Envoy vs WWW proxy) is additional routing — not shown here.
admin:
  address:
    socket_address:
      address: 127.0.0.1
      port_value: 9901

static_resources:
  listeners:
  - name: http_connect_proxy
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 8080
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: connect_proxy
          codec_type: AUTO
          http2_protocol_options:
            allow_connect: true
          upgrade_configs:
          - upgrade_type: CONNECT
          route_config:
            name: connect_route
            virtual_hosts:
            - name: connect
              domains: ["*"]
              routes:
              # CONNECT api.nonprod-acm.example.com:6443  →  tunnel
              # In the recommended shape: allowlisted hosts tunnel via boundary Envoy;
              # WWW hosts chain to the corporate WWW proxy (separate route/cluster).
              - match:
                  connect_matcher: {}
                route:
                  cluster: dynamic_forward_proxy_cluster
                  upgrade_configs:
                  - upgrade_type: CONNECT
                    connect_config: {}
          http_filters:
          - name: envoy.filters.http.dynamic_forward_proxy
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.dynamic_forward_proxy.v3.FilterConfig
              dns_cache_config:
                name: dynamic_forward_proxy_cache
                dns_lookup_family: V4_ONLY
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router

  clusters:
  - name: dynamic_forward_proxy_cluster
    connect_timeout: 10s
    lb_policy: CLUSTER_PROVIDED
    # Do NOT attach UpstreamTlsContext here for CONNECT tunnels —
    # that would make Envoy speak TLS to the destination instead of tunneling.
    # Filter + cluster dns_cache_config name/family must match.
    cluster_type:
      name: envoy.clusters.dynamic_forward_proxy
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.clusters.dynamic_forward_proxy.v3.ClusterConfig
        dns_cache_config:
          name: dynamic_forward_proxy_cache
          dns_lookup_family: V4_ONLY
```

**Smoke test from a non-prod host (through local Envoy):**

```bash
curl -v -x http://local-envoy.example.com:8080 https://api.nonprod-acm.example.com:6443/version
# Expect CONNECT + tunnel; TLS handshake is end-to-end to the API, not to Envoy.
```

**Harden the local front door:**

| Control | Why |
|---------|-----|
| Destination allowlist (RBAC / `:authority` match, or ACLs past Envoy) | Open CONNECT proxies become arbitrary egress |
| Explicit classes: boundary assets vs WWW vs deny | Implements the recommended fan-out |
| Client auth or source CIDR allow | Only non-prod node / machine CIDRs |
| No MITM / no upstream TLS context on CONNECT tunnels to ACM | Preserves hub↔spoke mTLS |
| Default-deny unknown hosts ([confused deputy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/dynamic_forward_proxy_filter) risk) | Open DFP can reach anything the proxy host can |

Point OCP `Proxy` / `KlusterletAddonConfig` / bootstrap `proxy-url` at **`http://local-envoy.example.com:8080`** — not at the boundary Envoy, not at the API hostname — unless you intentionally skipped the local hop.

The sample routes **CONNECT only** (HTTPS destinations). WWW chaining and plain `http://` origin proxying need additional routes/clusters.

---

## Three paths — three config surfaces

Do not configure one knob and assume the others inherit it.
In the recommended shape, every “use the proxy” URL below is the **local Envoy**.

| Path | Who initiates | Configure |
|------|---------------|-----------|
| Managed cluster → ACM hub (registration, work, many add-ons) | Klusterlet / agents on the spoke | Bootstrap kubeconfig `proxy-url` and/or add-on proxy CRs → local Envoy |
| Managed cluster → infra APIs (vCenter, CSI, PV provision) | Operators / CSI on the spoke | OpenShift `Proxy` named `cluster` → local Envoy (+ trust bundle) |
| ACM hub → infra APIs (Hive / CIM provision, scale) | Hive / Assisted on the hub | Hub `Proxy` `cluster` only if the hub itself is firewalled the same way |

Prod clusters that already have direct routes to the prod hub and management network often need **no** Envoy path.

OpenShift `Proxy`/`cluster` is the right place for **vSphere / CSI** to pick up `HTTP_PROXY`.
It is **not** ACM's Cluster Proxy add-on, and alone it is incomplete for klusterlet registration (see §3).

---

## 1. OpenShift cluster-wide proxy (spokes and hubs)

On each **non-prod** cluster that should use the local front door:

```yaml
apiVersion: config.openshift.io/v1
kind: Proxy
metadata:
  name: cluster
spec:
  httpProxy: http://local-envoy.example.com:8080
  httpsProxy: http://local-envoy.example.com:8080
  noProxy: .cluster.local,.svc,10.0.0.0/8
  # trustedCA:
  #   name: user-ca-bundle   # only if a proxy on the path inspects TLS
```

Notes:

- Point at **local Envoy**, not at ACM or vCenter hostnames.
- The `httpsProxy` URL scheme is often `http://` — that is the proxy listener scheme, not the upstream scheme.
- Put in-cluster CIDRs and true-direct destinations in `noProxy`.
- Leave ACM hub and vCenter hostnames **out** of `noProxy` so those calls hit local Envoy (which then fans out to boundary / WWW).
- For **new** clusters from ACM/Hive, set the same values under `proxy:` in `install-config.yaml`.

Hub-side Assisted Installer nuance: see [cim-hub-setup.md — Corporate proxy](./cim-hub-setup.md#corporate-proxy).

---

## 2. ACM add-on proxy (`KlusterletAddonConfig`)

On the **hub**, in the managed cluster's namespace — same local Envoy URL:

```yaml
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: <cluster-name>
  namespace: <cluster-name>
spec:
  proxyConfig:
    httpProxy: http://local-envoy.example.com:8080
    httpsProxy: http://local-envoy.example.com:8080
    noProxy: .cluster.local,.svc,10.0.0.0/8
  # proxyConfig alone is not enough — set proxyPolicy per add-on (RHACM docs).
  # CustomProxy → use proxyConfig above; OCPGlobalProxy → inherit spoke Proxy/cluster.
  applicationManager:
    enabled: true
    proxyPolicy: CustomProxy
  policyController:
    enabled: true
    proxyPolicy: CustomProxy
  searchCollector:
    enabled: true
    proxyPolicy: CustomProxy
  certPolicyController:
    enabled: true
    proxyPolicy: CustomProxy
```

Edit path:

```bash
oc -n <cluster-name> edit klusterletaddonconfig <cluster-name>
```

Upstream: [ACM managed cluster advanced configuration](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/add-ons/acm-managed-adv-config) (2.16) — section *Enabling cluster-wide proxy on existing cluster add-ons*.

For add-ons that need explicit association, OCM also documents `AddOnDeploymentConfig` + `ManagedClusterAddOn.spec.configs` — see [Register a cluster through a proxy](https://open-cluster-management.io/docs/scenarios/register-cluster-through-proxy/).

---

## 3. Klusterlet → hub registration (sharp edge)

Registration uses mTLS to the hub API.
With the recommended front door, prefer registering **through** local Envoy (pattern B) so hub traffic follows the same path as vSphere.

### A — Bypass the proxy for hub API

Allow non-prod → hub **TCP 6443** and **443** directly.
Put hub API and apps hostnames (or CIDRs) in `noProxy`.
Local Envoy then mainly carries **infra** (vCenter) and WWW classes.

Workspace bare-metal notes treat "force klusterlet through a naive HTTP proxy" as a frequent Unknown-cluster failure mode — see [acm-bare-metal-network-requirements.md](./acm-bare-metal-network-requirements.md) (klusterlet and proxy).
Naive = TLS terminate / no CONNECT — not the same as a hardened CONNECT front door.

### B — Register *through* local Envoy (fits the recommended shape)

```yaml
apiVersion: v1
kind: Config
clusters:
  - name: default-cluster
    cluster:
      server: https://api.nonprod-acm.example.com:6443
      proxy-url: http://local-envoy.example.com:8080
      certificate-authority-data: LS0tLS...
# contexts / users omitted
```

Requirements: local (and boundary) Envoy **CONNECT**, **no TLS terminate** on the ACM path, and proxy CA in `certificate-authority-data` if a proxy presents TLS to the client.

After join, `hub-kubeconfig-secret` should carry equivalent proxy settings.

A cluster-wide `Proxy` without A or B often yields: hub connection check failed / `ManagedCluster` **Unknown**.

Hub ↔ spoke port matrix: [networking-requirements-2.16.md](./networking-requirements-2.16.md).

---

## Mapping to prod / non-prod hubs

```text
  Prod clusters ──(direct)──► Prod ACM hub ──► infra (vCenter, …)

  Non-prod clusters
       │
       │  Proxy/cluster + ACM proxy-url
       ▼
  local Envoy
       ├──────────────► boundary Envoy ──► Non-prod ACM hub
       ├──────────────► boundary Envoy ──► vCenter / infra APIs
       └──────────────► WWW proxy      ──► internet
```

Guidelines:

- Prefer **direct** paths for prod where policy already allows them.
- Non-prod: one front door (local Envoy); fan-out policy lives there.
- Hub-initiated calls to infra may be direct from the management network; configure hub `Proxy` only when the hub needs the same treatment.
- Keep prod and non-prod **ManagedClusterSets**, credentials, and GitOps roots separate.

---

## Suggested rollout order

1. Stand up **local Envoy**; prove CONNECT from a non-prod jump host to hub `:6443`, hub apps `:443`, and vCenter (`curl -x http://local-envoy…`).
2. Wire local Envoy fan-out: boundary Envoy for allowed assets, WWW proxy for internet, deny otherwise.
3. Prefer klusterlet pattern **B** (proxy-url → local Envoy) unless networking mandates direct hub (pattern A).
4. Set spoke `Proxy` `cluster` → local Envoy (CSI / PV / platform egress).
5. Set `KlusterletAddonConfig` → local Envoy (`proxyConfig` + `proxyPolicy`).
6. For provisioning: install-config / `InfraEnv` proxy → same local Envoy URL — [cim-hub-setup.md](./cim-hub-setup.md), [cloud-cluster-provisioning.md](./cloud-cluster-provisioning.md).

---

## Related reading

- [networking-requirements-2.16.md](./networking-requirements-2.16.md) — hub ↔ managed cluster ports
- [cim-hub-setup.md](./cim-hub-setup.md) — hub corporate proxy vs Assisted pods
- [acm-bare-metal-network-requirements.md](./acm-bare-metal-network-requirements.md) — klusterlet proxy bypass warning
- [cloud-cluster-provisioning.md](./cloud-cluster-provisioning.md) — hub proxy vs credential/install-config proxy
- [fleet-ad-hoc-data-gathering.md](./fleet-ad-hoc-data-gathering.md) — ACM **Cluster Proxy** add-on (different feature)
- OCM: [Register a cluster through a proxy](https://open-cluster-management.io/docs/scenarios/register-cluster-through-proxy/)
- RHACM 2.16 — *Add-ons*, §1.3 [Enabling cluster-wide proxy on existing cluster add-ons](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/add-ons/acm-managed-adv-config)
- Envoy — [Dynamic forward proxy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/dynamic_forward_proxy_filter) (`/latest/`; pin a minor when you freeze an Envoy version)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
