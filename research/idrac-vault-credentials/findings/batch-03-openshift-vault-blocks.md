# Batch 03 Findings: OpenShift / automation building blocks for Vault-sourced BMC creds
**Sources analyzed:** ref-10..ref-14
**Date:** 2026-09-26
**Assertions under test:** C1–C6

---

## ref-10 — Ansible `community.hashi_vault.hashi_vault` lookup

**URL:** https://docs.ansible.com/projects/ansible/latest/collections/community/hashi_vault/hashi_vault_lookup.html

**What it covers:** Lookup plugin to retrieve secrets from HashiCorp Vault (`secret=path[:field]`). Auth methods include token, userpass, ldap, approle, aws_iam, azure, jwt, cert, gcp, none. KV v1/v2 paths documented; return formats dict/values/raw. Controller needs `hvac`. Migration notes point to newer collection plugins (`vault_read`, `vault_kv2_get`, etc.).

**Relevant assertions:**

| Assertion | Verdict | Evidence |
| --- | --- | --- |
| C3 (Ansible←Vault half) | **SUPPORTED** | Synopsis: “Retrieve secrets from HashiCorp’s Vault.” Examples show reading KV paths into playbook facts. |
| C3 (iDRAC auth half) | **NOT ADDRESSED** | No Redfish, iDRAC, username/password-to-BMC, or `auth_token`. |
| C1, C2, C4, C5 | **NOT ADDRESSED** | No Metal³/BMH, ESO, Redfish session semantics, or metal-credential-sync. |
| C6 (complete iDRAC dynamic engine) | **NOT DOCUMENTED** | Vault read consumer only; no iDRAC engine, rotation, or BMH sync. |

**Finding:** Confirms Ansible can pull Vault secrets for automation. Completing C3 requires pairing with an iDRAC/Redfish client (ref-11). Does not imply Vault-native BMC lifecycle.

---

## ref-11 — Ansible `community.general.idrac_redfish_command`

**URL:** https://docs.ansible.com/projects/ansible/latest/collections/community/general/idrac_redfish_command_module.html

**What it covers:** OEM Redfish actions against Dell iDRAC (`baseuri`, `category`, `command`). Auth parameters: `username`, `password`, and `auth_token` (added in community.general 2.3.0 — “Security token for authenticating to iDRAC”). Example uses username/password only.

**Relevant assertions:**

| Assertion | Verdict | Evidence |
| --- | --- | --- |
| C3 (iDRAC auth half) | **SUPPORTED** | Module accepts `username`/`password` **or** `auth_token` for Redfish to iDRAC. |
| C3 (Vault half) | **NOT ADDRESSED** | No Vault / hashi_vault integration. |
| C4 (auth_token = short-lived session) | **PARTIAL / INFERRED** | `auth_token` is documented as a security token alternative to user/pass. Source does **not** state TTL, session lifetime, or that bootstrap password/user must still come from Vault (or anywhere). |
| C1, C2, C5 | **NOT ADDRESSED** | No BMH, ESO, or metal-credential-sync. |
| C6 | **NOT DOCUMENTED** | Operational Redfish client only; no Vault SoR, rotator, or ESO→BMH path. |

**Finding:** Supports the Redfish consumer side of C3. C4’s “short-lived operational sessions” and “bootstrap must come from Vault” are architectural inferences beyond this page — auth_token existence is real; lifetime and bootstrap sourcing are not.

---

## ref-12 — Metal³ Bare Metal Operator / BareMetalHost

**URL:** https://book.metal3.io/bmo/introduction

**What it covers:** BMO manages `BareMetalHost` CRs via Ironic. Enrollment requires BMC address, credentials, protocol (IPMI/Redfish), boot MAC, boot mode. Minimal BMH example:

```yaml
spec:
  bmc:
    address: ipmi://192.168.111.1:6230
    credentialsName: node-0-bmc-secret
```

Credentials are named via `credentialsName` (Kubernetes Secret reference). No Vault, ESO, or dynamic-secret language.

**Relevant assertions:**

| Assertion | Verdict | Evidence |
| --- | --- | --- |
| C1 | **SUPPORTED** | BMH stores BMC endpoint + **`credentialsName`** pointing at a K8s Secret; enrollment text: “IP address and credentials of the BMC.” Not Vault-native. |
| C2–C5 | **NOT ADDRESSED** | No ESO, Ansible Vault, Redfish token lifecycle, or metal-credential-sync. |
| C6 (BMH Secret slot in architecture) | **PARTIAL** | Shows the Secret that ESO could populate; does not describe Vault SoR, rotator, or ESO. |

**Finding:** Primary evidence for C1. Metal³’s contract is “Secret exists and is named” — how that Secret is filled (manual, ESO, etc.) is out of scope for this page.

---

## ref-13 — External Secrets Operator — HashiCorp Vault provider

**URL:** https://external-secrets.io/latest/provider/hashicorp-vault/

**What it covers:** ESO ↔ Vault KV (v1/v2; other engines via Vault Generator). `SecretStore`/`ExternalSecret` pull Vault data into cluster Secrets (`refreshInterval` example `15s`). Auth: token, AppRole, Kubernetes, LDAP, UserPass, JWT/OIDC, AWS IAM, TLS cert. **PushSecret** syncs Kubernetes secret keys **into** Vault (create/read/update on data+metadata; CAS for KV v2). Token cache, namespaces, consistency notes for Enterprise.

**Relevant assertions:**

| Assertion | Verdict | Evidence |
| --- | --- | --- |
| C2 | **SUPPORTED** | Pull: ExternalSecret → target K8s Secret from Vault KV. Push: PushSecret → Vault. Together enable Vault→cluster Secret sync (and optional reverse). |
| C2 → BMH specifically | **INFERRED** | Mechanism fits BMH `credentialsName` Secrets; page never names BareMetalHost or BMC. |
| C1 | **NOT ADDRESSED** | No Metal³. |
| C5 direction contrast | **CONTEXT** | PushSecret is K8s→Vault (same direction class as metal-credential-sync); primary ESO path for Vault-SoR is pull. |
| C6 (complete iDRAC dynamic engine) | **NOT DOCUMENTED** | Generic Vault↔K8s sync; no iDRAC rotation or dynamic BMC engine. |

**Finding:** Strong evidence for C2. Enables architecture “Vault SoR → ESO → BMH Secret” without documenting BMH or iDRAC rotation itself.

---

## ref-14 — metal-credential-sync (cobaltcore-dev)

**URL:** https://github.com/cobaltcore-dev/metal-credential-sync

**What it covers:** Operator watches metal-operator **BMCSecret** resources, discovers related BMC CRs, writes credentials to Vault (KV v1/v2) or OpenBao (OpenBao stub/future) at templated paths `bmc/{{.Region}}/{{.Hostname}}/{{.Username}}`. Direction in architecture diagram: BMCSecret → Vault. Features: label-selective sync, cleanup on delete, sync status CRD. Depends on ironcore-dev metal-operator (not Metal³ BMH). Auth: Kubernetes SA, token; AppRole listed as future. No Redfish PATCH, no password rotation on iDRAC, no Vault→BMCSecret pull.

**Relevant assertions:**

| Assertion | Verdict | Evidence |
| --- | --- | --- |
| C5 | **SUPPORTED** | Explicit cluster→Vault/OpenBao sync of BMC secrets; not a Vault→iDRAC rotation loop. |
| C1 | **NOT ADDRESSED / DIFFERENT STACK** | Targets metal-operator `BMCSecret`/`BMC`, not Metal³ `BareMetalHost`/`credentialsName`. |
| C2 | **NOT ADDRESSED** | Does not implement ESO; opposite primary flow from Vault-SoR pull. |
| C3, C4 | **NOT ADDRESSED** | No Ansible / Redfish auth_token. |
| C6 | **NOT DOCUMENTED** | Useful for vaulting existing cluster BMC secrets; not a dynamic iDRAC secrets engine or full Vault SoR + rotator + ESO→BMH design. |

**Finding:** Confirms C5 and the direction trap: syncing BMC creds *into* Vault is not the same as Vault-driven iDRAC password lifecycle. Ecosystem note: ironcore metal-operator, not Metal³ BMH.

---

## Batch Summary

### Assertion rollup (this batch)

| ID | Assertion (short) | Batch verdict | Primary source(s) |
| --- | --- | --- | --- |
| C1 | BMH BMC creds via `credentialsName` Secret (not Vault-native) | **SUPPORTED** | ref-12 |
| C2 | ESO pull (+ optional push) Vault ↔ cluster Secrets | **SUPPORTED** | ref-13 |
| C3 | Ansible Vault lookup + iDRAC Redfish user/pass or auth_token | **SUPPORTED (composed)** | ref-10 + ref-11 (neither alone) |
| C4 | auth_token = short-lived ops; bootstrap still from somewhere (e.g. Vault) | **PARTIAL** | ref-11 documents token param only; TTL/bootstrap/Vault not stated |
| C5 | metal-credential-sync = cluster→Vault; not Vault→iDRAC rotation | **SUPPORTED** | ref-14 |
| C6 | Blocks enable Vault SoR + rotator + ESO→BMH; no complete iDRAC dynamic engine in these five | **SUPPORTED (with gap)** | Synthesis: C1+C2+C3 present; **Redfish PATCH rotator absent** from ref-10..14; none documents Vault dynamic-secrets for iDRAC |

### Counts

| Verdict class | Count |
| --- | --- |
| Supported (assertion-level) | **5** (C1, C2, C3-composed, C5, C6-gap claim) |
| Partial | **1** (C4) |
| Not addressed / out of scope per source | Many (expected — specialized docs) |
| Complete Vault dynamic-secrets engine for iDRAC in any one source | **0** |

### Key pattern

OpenShift/BMC path is **compose-the-pipe**: Vault → (ESO or Ansible) → K8s Secret / Redfish client → BMH or iDRAC — with metal-credential-sync flowing the **other** way — and **no single source** here ships Vault-native iDRAC dynamic secrets or the Redfish password rotator.
