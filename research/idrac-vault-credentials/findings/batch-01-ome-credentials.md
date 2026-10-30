# Batch 01 Findings: OME iDRAC credential management
**Sources analyzed:** ref-01, ref-02, ref-03, ref-04
**Date:** 2026-09-26
**Assertions under test:** A1–A4

- **A1:** OME supports internal iDRAC service-account creation and password rotation without an external vault.
- **A2:** OME's documented external vault/PAM integration for iDRAC password management is CyberArk only — not HashiCorp Vault.
- **A3:** OME CyberArk/internal features have license, account-slot, and generation caveats (including iDRAC 10 / 17G limits where stated).
- **A4:** OME-native rotation does not satisfy a requirement that HashiCorp Vault be the system of record for OpenShift BMC credentials.

---

## ref-01 — InfoHub announcement: iDRAC Credential Management in OME 4.0

**URL:** https://infohub.delltechnologies.com/en-us/p/announcing-idrac-credential-management-in-openmanage-enterprise-4-0/
**Capture quality:** Partial — InfoHub reCAPTCHA blocked full fetch; content reconstructed from public search snippets. Cross-check against live page before citing.

### Assertion map

| Assertion | Relation |
|-----------|----------|
| A1 | Supports (snippet-level) — internal OME iDRAC password rotation creates/updates credentials on a schedule; removes need for static admin credentials |
| A2 | Supports (snippet-level, by enumeration) — external option named is CyberArk Central Credential Provider; “HashiCorp Vault is NOT mentioned” |
| A3 | Supports partially — CyberArk requires OME Advanced+ on each iDRAC; internal path “Supported on iDRAC 7, 8, and 9” (generation bound). Account-slot and iDRAC 10/17G CyberArk limits not in this capture |
| A4 | Supports by implication only — OME-native or CyberArk paths; no Vault-as-SoR or OpenShift BMC discussion |

### Source actually says (paraphrase / quotes)

OME 4.0 adds optional iDRAC credential management. Customers can use (1) **Internal OME iDRAC password rotation** — creates/updates credentials on a schedule (daily to annual); removes need for static admin credentials; supported on iDRAC 7, 8, and 9; or (2) **CyberArk Central Credential Provider** — external third-party credential provider; requires OME Advanced+ on each iDRAC; configured on the iDRAC Password Management page. Capture note explicitly: “HashiCorp Vault is NOT mentioned as an OME external vault option in this announcement.”

### Verdict: **UNVERIFIABLE** (partial / search-snippet reconstruction)

Snippet content is directionally consistent with ref-02–04, but this file is not a full authoritative page capture. Treat as lead only until the live InfoHub article is re-fetched.

### Impact on OpenShift+Vault lifecycle argument

If verified later, reinforces that Dell’s OME story is **OME-internal rotation vs CyberArk**, not HashiCorp Vault — useful contrast for why OME does not close a Vault-SoR OpenShift BMC requirement. Do not hang citations on this ref alone.

---

## ref-02 — Dell KB 000219279: OME 4.0 iDRAC Password Management and Rotation

**URL:** https://www.dell.com/support/kbdoc/en-us/000219279/openmanage-enterprise-4-0-idrac-password-management-and-rotation
**Capture quality:** Full KB fetch (How To; Last Modified 17 Jul 2025; Version 7).

### Assertion map

| Assertion | Relation |
|-----------|----------|
| A1 | Supports — internal rotation “does not require an external password handler”; Internal Credential Management + Internal OME password rotation schedule |
| A2 | Supports (documented external path) — “Supports CyberArk to manage passwords”; configuration is CyberArk CCP only in this article. HashiCorp Vault not mentioned. Does not exhaustively prove “never any other PAM” across all Dell docs, but this KB names CyberArk as the external integration |
| A3 | Supports (license + account slot) — Advanced or Advanced+ for rotation; CyberArk Integration Advanced+ only; unused local account slot (iDRAC supports 16 local accounts); network reach to CyberArk. **Does not** state iDRAC 10 / 17G CyberArk unsupported |
| A4 | Supports by operational implication — internal path keeps rotation inside OME; CyberArk path makes CyberArk the credential provider. Neither path makes HashiCorp Vault SoR. Article does not discuss OpenShift/BMH |

### Source actually says (paraphrase / quotes)

Purpose: access OME via “an iDRAC service account that is rotated per the security policy”; “Rotates once a month by default”; “It does not require an external password handler”; “Supports CyberArk to manage passwords.” Requirements: Advanced or Advanced+; “CyberArk Integration is with OpenManage Enterprise Advanced+ iDRAC license only”; “An unused local account slot in the iDRAC (iDRAC supports 16 local accounts).” Internal ICM enableable only at initial OME 4.0 deployment wizard; “Once enabled Internal Credential Management cannot be disabled.” CyberArk setup: Enable CyberArk Integration, export eligible iDRACs, upload CCP certificate, CCP host, Application ID, Safe name, retrieve-by IP/FQDN/Service Tag, Test Connection.

### Verdict: **VERIFIED WITH CAVEATS**

Strong primary KB evidence for A1 and for A3 license/slot caveats. A2 is verified *for this document’s documented external integration* (CyberArk), not a global negative proof against every possible undocumented backend. A4 is a logical consequence of the described control planes, not an explicit OpenShift/Vault statement. iDRAC 10 / 17G CyberArk limit is **absent** here (see ref-04).

### Impact on OpenShift+Vault lifecycle argument

Establishes OME as a **self-contained or CyberArk-backed** iDRAC credential manager. Adopting OME-native rotation satisfies OME’s security policy for *OME’s* service account — it does **not** place HashiCorp Vault in the OpenShift BMC credential path.

---

## ref-03 — OME 4.3.x User’s Guide: Internal iDRAC credential management

**URL:** https://www.dell.com/support/manuals/en-us/dell-openmanage-enterprise/ome_4_3_online_help_and_user_guide/internal-idrac-credential-management?guid=guid-fdc1198c-f73e-4318-a77e-914d7436b96a&lang=en-us
**Capture quality:** WebFetch capture (manual fetcher HTTP 403).

### Assertion map

| Assertion | Relation |
|-----------|----------|
| A1 | Supports — enabling internal management creates a local service account on supported iDRACs after first successful discovery; next step is optional internal OME password rotation |
| A2 | Not addressed — no external vault/PAM section in this page |
| A3 | Supports (license, slot, operational caveats) — Advanced/Advanced+ (also Essential Server Configuration Management on iDRAC); free local account slot (max 16); Password Strength Policy must NOT be configured; no opt-out once enabled; no user roles on service account. **No** iDRAC 10 / 17G CyberArk statement (internal topic only) |
| A4 | Supports by implication — OME creates/owns `OME_[application-GUID]` local account; Vault is not in the lifecycle described |

### Source actually says (paraphrase / quotes)

Enabling during initial onboarding lets OME “create a local service account on supported iDRACs after first successful discovery.” Username format: `OME_[application-GUID]` (GUID via `GET /api/ApplicationService/Info`). Prerequisites: Advanced or Advanced+ (also Essential SCM on iDRAC); “Requires a free local account slot (iDRAC max 16 local accounts). If exceeded, service account cannot be created; communication falls back to discovery credentials.” Password Strength Policy must not be configured — if OME-generated password fails policy, “iDRAC disables the service account.” Results: “No opt-out once enabled”; disabled-by-policy accounts cannot be managed from OME; “No user roles assigned to this service account”; optionally enable internal OME password rotation next.

### Verdict: **VERIFIED WITH CAVEATS**

Solid for A1 (service-account creation + path to rotation) and for internal-path A3 caveats. Silent on A2 and on CyberArk/iDRAC 10 generation limits. A4 remains implication, not an OpenShift-scoped claim.

### Impact on OpenShift+Vault lifecycle argument

Documents that the OME-managed local account is **OME-scoped** (`OME_[GUID]`), slot-constrained, and irreversible once enabled — a parallel credential identity to anything Vault would issue for Ironic/BMO. Reinforces that “use OME internal rotation” is a different SoR than Vault-for-OpenShift-BMC.

---

## ref-04 — OME 4.5 User’s Guide: Enable CyberArk integration for password management

**URL:** https://www.dell.com/support/manuals/en-us/dell-openmanage-enterprise/ome_4_5_online_help_user_guide/enable-cyberark-integration-for-password-management?guid=guid-ca8bf0fb-a4b2-4785-84a4-7c7761176fdf&lang=en-us
**Capture quality:** WebFetch capture (manual fetcher HTTP 403).

### Assertion map

| Assertion | Relation |
|-----------|----------|
| A1 | Neutral / out of scope — page is CyberArk integration, not internal account creation (does not contradict A1) |
| A2 | Supports strongly — documents CyberArk PAM (self-hosted) as the external path; capture note: “HashiCorp Vault is NOT a documented OME password-management backend” |
| A3 | Supports strongly — Advanced+ only; “NOT supported for 17G / iDRAC 10 based PowerEdge servers”; one CyberArk safe; local iDRAC passwords only (not AD/LDAP); CCP reachability |
| A4 | Supports by implication for the *external* OME path — credential SoR is CyberArk, not Vault; still no OpenShift BMC wording |

### Source actually says (paraphrase / quotes)

“OME integrates with CyberArk PAM (self-hosted) for privileged iDRAC credentials.” Prerequisites: “OME Advanced+ license only”; “NOT supported for 17G / iDRAC 10 based PowerEdge servers”; devices in a single CyberArk safe; “Only local iDRAC passwords (not AD/LDAP-managed accounts)”; appliance must reach CCP Host. Steps: enable integration, export eligible list, upload CCP cert (certificate-based only), CCP host/port, Application ID, Safe name, retrieve-by IP/FQDN/Service Tag, Test Connection / Apply. Operational notes: vault retrieval failures fail device tasks; event CDEV6131; discovery credential-type quirks; disable per-device by removing CyberArk account and rediscovering. Explicit note in capture: HashiCorp Vault is not a documented OME password-management backend.

### Verdict: **VERIFIED WITH CAVEATS**

Best batch evidence for A2 (CyberArk as documented external PAM) and for A3’s **iDRAC 10 / 17G** CyberArk limit plus Advanced+. A1 not covered here. A4 implied for CyberArk-as-SoR vs Vault; OpenShift still unmentioned. “Vault is not documented” is absence-of-documentation in this guide path, not a signed Dell “Vault will never be supported” statement.

### Impact on OpenShift+Vault lifecycle argument

Shows Dell’s **documented** OME external PAM path is CyberArk — and that path excludes current-gen (17G / iDRAC 10) servers. Neither CyberArk-via-OME nor OME-internal rotation is HashiCorp Vault as SoR for OpenShift BMC credentials.

---

## Batch Summary

| Verdict | Count | Refs |
|---------|-------|------|
| VERIFIED | 0 | — |
| VERIFIED WITH CAVEATS | 3 | ref-02, ref-03, ref-04 |
| MISLEADING | 0 | — |
| UNSUPPORTED | 0 | (no source contradicted the assertions; ref-03 simply silent on A2) |
| UNVERIFIABLE | 1 | ref-01 (partial search-snippet reconstruction) |

**Assertion coverage across the batch (findings only):**

| Assertion | Batch support posture |
|-----------|------------------------|
| A1 | Supported by ref-02 + ref-03; echoed in ref-01 snippets; ref-04 N/A |
| A2 | Supported by ref-02 (CyberArk named) + ref-04 (CyberArk guide + Vault not documented); ref-01 snippet; not addressed by ref-03 |
| A3 | License + account-slot: ref-02, ref-03; CyberArk Advanced+ + **17G/iDRAC 10 unsupported**: ref-04; generation on internal (7/8/9): ref-01 only (unverified capture) |
| A4 | No source states OpenShift/Vault SoR explicitly; all authoritative captures describe OME-internal or CyberArk control planes — implication supports A4 without a direct quote |

**Key pattern:** Authoritative OME material (KB + user guides) consistently frames iDRAC credential lifecycle as **OME-internal service account + rotation** or **CyberArk CCP**, with license/slot (and for CyberArk, 17G/iDRAC 10) constraints — HashiCorp Vault never appears as an OME password-management backend in these sources.
