# Batch 02 Findings: Dell products with native HashiCorp Vault (SCG / DTIAS)
**Sources analyzed:** ref-05..ref-09
**Date:** 2026-09-26
**Assertions under test:** B1–B5

---

## ref-05 — SCG 5.x App Edition: Credential Vault
**URL:** https://www.dell.com/support/manuals/en-us/secure-connect-gateway-app-edition/scg_5.x_app_ug/credential-vault
**Capture quality:** Full (WebFetch; scraper 403)

### What the source says
- A credential vault stores certificates and credentials centrally **without storing them locally on SCG**.
- Supported vault types explicitly listed: CyberArk with Conjur API, CyberArk Credential Provider, Azure Key Vault, **HashiCorp Vault**.
- UI supports add/edit/delete; shows vault name, server name, connectivity status, type, update time.
- After adding a vault, create account credentials by **mapping the credential vault account ID**.

### Assertion verdicts
| ID | Verdict | Notes |
| --- | --- | --- |
| B1 | **Supports** | HashiCorp Vault is named in the supported credential vaults list. |
| B2 | **Partial** | Confirms vault-backed account credentials exist; does not document secret path / username-password identifiers or iDRAC device type. |
| B3 | **Silent** | UI/product page only; no REST API, `VAULTTYPE`, path, or namespace. |
| B4 | **Silent** | SCG, not DTIAS. |
| B5 | **Supports (by scope)** | Scope is SCG credential vault for devices managed in SCG. No mention of OpenShift, BareMetalHost, Ironic, or Vault-driven rotation for cluster BMC control planes. |

### Relevance to organizing question
Establishes that Dell ships a first-party product (SCG) with Hashicorp Vault as a first-class credential vault — BMC secrets can live in Vault **outside** the OpenShift control plane, in Dell’s support/telemetry gateway.

---

## ref-06 — SCG 5.x VE: Add account credentials
**URL:** https://www.dell.com/support/manuals/en-us/secure-connect-gateway/scg_5.x_ve_ug/add-account-credentials
**Capture quality:** Full (WebFetch; VE URL; HashiCorp path guidance present)

### What the source says
- Device credentials are required to add devices and collect telemetry.
- Credential creation: **Manually** (store locally on SCG) **or Use a credential vault**.
- For **HashiCorp vault**: enter **Secret path**, **Username identifier**, and **Password identifier**.
- Secret path formed as `SecretPath/Secret` — example: `SecretPath=SCGSecrets`, `Secret=iDRAC` → `SCGSecrets/iDRAC`.
- Device type **iDRAC** is explicitly supported (also SC/Compellent, Dell ML3, PowerVault).
- Manual mode still takes username/password; vault mode maps identifiers into the vault secret.
- No language about generating dynamic BMC users or rotating passwords on the iDRAC — this is **retrieve existing secret fields** for device access.

### Assertion verdicts
| ID | Verdict | Notes |
| --- | --- | --- |
| B1 | **Supports** | HashiCorp is a selectable credential vault when adding device credentials. |
| B2 | **Supports** | Path + username/password identifiers; iDRAC called out; static secret lookup pattern, not dynamic user generation. |
| B3 | **Silent** | UI workflow only; no REST create payload. |
| B4 | **Silent** | SCG, not DTIAS. |
| B5 | **Supports (by scope)** | Purpose is SCG device add / telemetry collection. No BMH, Ironic, or OpenShift credential sync. |

### Relevance to organizing question
Strongest SCG evidence for **how** Vault is used: pull username/password from a named path for iDRAC device credentials — contrast to Vault-as-rotator or Ironic BMH secret sync.

---

## ref-07 — SCG REST API: Create a credential vault (HashiCorp)
**URL:** https://www.dell.com/support/manuals/en-us/secure-connect-gateway-ve/scg_rest_api_guide/create-a-credential-vault
**Capture quality:** Full (WebFetch)

### What the source says
- `POST /v2/inventory/remoteCredentialVaults` registers a remote credential vault.
- HashiCorp create body includes `"VAULTTYPE": "HASHICORPVAULT"` plus `VAULTNAME`, `VAULTHOSTNAME`, `VAULTPORT` (example `8200`), `AUTHMETHOD`, `ORGACCOUNTNAME`, `CLIENTLOGINNAME`, `VAULTAPIKEY`, `USERNAME`, `PASSWORD`.
- `AUTHMETHOD` options: LDAP, Username, Token, or JWT (mapped to Username/Password fields per method).
- Same page also documents Conjur, CyberArk CCP, Azure Key Vault create payloads — HashiCorp is one vault type among peers.

### Assertion verdicts
| ID | Verdict | Notes |
| --- | --- | --- |
| B1 | **Supports** | API enum value `HASHICORPVAULT` confirms HashiCorp as a supported vault type. |
| B2 | **Silent** | Create-vault endpoint only; no device credential / secret-path / identifier mapping here. |
| B3 | **Supports** | Registers HashiCorp with `VAULTTYPE=HASHICORPVAULT`; body includes `CLIENTLOGINNAME` and `ORGACCOUNTNAME` (semantics for Path/Namespace clarified in ref-08). |
| B4 | **Silent** | SCG API, not DTIAS. |
| B5 | **Supports (by scope)** | Inventory remote credential vaults for SCG. No OpenShift/BMH/Ironic surface. |

### Relevance to organizing question
Proves programmatic registration of Hashicorp into SCG — Dell’s vault integration is real and API-backed, still on the SCG side of the fence.

---

## ref-08 — SCG REST API: Credential vault parameters
**URL:** https://www.dell.com/support/manuals/en-us/secure-connect-gateway-ve/scg_rest_api_guide/credential-vault
**Capture quality:** Full (WebFetch)

### What the source says
- Credential vault stores certificates/credentials for devices managed in SCG; multiple vaults allowed.
- Map vault account ID when creating device credentials.
- Parameter table maps fields per vendor:
  - **HashiCorp: `CLIENTLOGINNAME` = Path; `ORGACCOUNTNAME` = Namespace**
  - Conjur / CCP / Azure use the same field names for different meanings.
- `VAULTTYPE` row lists CONJUR / CyberArk CCP / AZUREKEYVAULT; note in capture says HashiCorp uses `HASHICORPVAULT` on the create endpoint (cross-ref ref-07).

### Assertion verdicts
| ID | Verdict | Notes |
| --- | --- | --- |
| B1 | **Supports** | HashiCorp called out in parameter semantics for Path/Namespace. |
| B2 | **Partial** | Confirms vault account mapping for device credentials; does not restate secret path + username/password identifiers (those are in ref-06). |
| B3 | **Supports** | Explicit Path (`CLIENTLOGINNAME`) and Namespace (`ORGACCOUNTNAME`) mapping for HashiCorp; pairs with ref-07 create API. |
| B4 | **Silent** | SCG, not DTIAS. |
| B5 | **Supports (by scope)** | Parameters are for SCG-managed device credentials only. |

### Relevance to organizing question
Completes the REST picture: Hashicorp registration is not just a type string — path and namespace are first-class mapped fields.

---

## ref-09 — DTIAS: Integrating HashiCorp Vault *(PARTIAL)*
**URL:** https://infohub.delltechnologies.com/en-us/l/dell-telecom-infrastructure-automation-suite-2-5-installation-and-administration-guide/integrating-hashicorp-vault-10/
**Capture quality:** **Partial** — InfoHub reCAPTCHA blocked full fetch; content reconstructed from public search snippets of DTIAS 2.4/2.5 guides. Cross-check against live page before citing in published work.

### What the source says (as captured)
- Configure a **KMS** to store passwords used by DTIAS.
- Suite 2.5 note: **only HashiCorp Vault Enterprise Version 1.15.5** is supported.
- After integration, **only BMC credential secrets** are stored in Vault (credentials of servers managed by the automation suite).
- Setup sketch: Enterprise Vault reachable from the suite cluster; namespace; policy for CRUD; 12-hour token at install.
- `dtias_config.yaml`: `enable_kms: true`, `kms_provider: "vault"`, `kms_address`, `kms_namespace`, `kms_token` (2.4 also `kms_ca_string`).
- BMC credentials created via onboarding APIs, or Vault admin creates a secret with specific name/format then onboards with that secret name.

### Assertion verdicts
| ID | Verdict | Notes |
| --- | --- | --- |
| B1 | **Silent** | DTIAS product, not SCG. |
| B2 | **Silent** | Not SCG retrieval model. |
| B3 | **Silent** | Not SCG REST API. |
| B4 | **Supports (partial source)** | Vault Enterprise as KMS; BMC credentials for suite-managed servers; adjacent Dell telecom product — not OME, not OpenShift BMH. Snippet-based; verify live InfoHub before hard citation. |
| B5 | **Supports (by scope / partial)** | Documented use is DTIAS BMC secret storage via KMS. No BareMetalHost sync, no Ironic password rotation, no OpenShift control-plane integration in the capture. |

### Relevance to organizing question
Second Dell product family that puts BMC secrets in Hashicorp Vault — strengthens the “Dell can do Vault elsewhere” contrast without implying OME or Metal³/BMH get the same feature.

---

## Batch Summary

### Per-assertion rollup

| ID | Assertion (short) | Batch verdict | Primary evidence |
| --- | --- | --- | --- |
| B1 | SCG lists HashiCorp as supported vault type | **Supported** | ref-05 (list); reinforced by ref-06–08 |
| B2 | SCG retrieves iDRAC creds via path + user/pass identifiers (not dynamic BMC users) | **Supported** | ref-06 (decisive); ref-05/08 partial |
| B3 | SCG REST registers HashiCorp (`VAULTTYPE=HASHICORPVAULT`) with path/namespace | **Supported** | ref-07 (create + type) + ref-08 (Path/Namespace field mapping) |
| B4 | DTIAS stores BMC creds in Vault Enterprise as KMS (adjacent product) | **Supported (partial source)** | ref-09 only; reCAPTCHA-limited capture |
| B5 | SCG/DTIAS Vault ≠ OpenShift BMH sync / Ironic Vault-driven rotation | **Supported (by documented scope)** | All five: product scopes are SCG telemetry/device mgmt or DTIAS suite BMC KMS; zero OCP/BMH/Ironic mention |

### Counts
- Sources analyzed: **5** (ref-05..ref-09)
- Full captures: **4** | Partial: **1** (ref-09)
- Assertions Supported: **5/5** (B4 and B5 carry partial-capture / scope-silence caveats)
- Assertions Contradicted: **0**
- Assertions Silent across all sources: **0** (each ID has at least one supporting or scoped source)

### Key pattern (one sentence)
Dell already wires Hashicorp Vault to BMC/iDRAC credentials in SCG (static path + identifier retrieval, REST-registerable) and DTIAS (Vault Enterprise KMS for suite BMC secrets) — proving Vault-native BMC storage in Dell products that are **not** the OpenShift BareMetalHost / Ironic control plane.
