# iDRAC Credential Management and HashiCorp Vault

**Purpose:** Map credential lifecycle options for OpenShift bare-metal (Metal³/BMH) + iDRAC, aiming at short-lived or frequently rotated service accounts with HashiCorp Vault as system of record (or as the source consumers pull from). Dell OME/SCG/DTIAS are context and contrast, not the primary control plane.
**Status:** Gather complete — organising question reframed 2026-09-26; ready for analysis
**Output:** Pending analysis → likely `devops/` notes or a short guide; library stub at [`library/idrac-vault-credentials.md`](../../library/idrac-vault-credentials.md).

## Research question

How do you run OpenShift / BMC lifecycle management with **short-lived or Vault-rotated iDRAC service accounts**, when OME does not natively consume HashiCorp Vault — and what architectures still let Vault be the source of truth?

## Author intent (session)

- Primary: OpenShift + lifecycle (Ironic/BMO), not SCG/DTIAS.
- Goal: advance security model — prefer Vault-rotated short-lived service accounts; if iDRAC cannot do true dynamic secrets, an architecture where short-lived *operational* creds (or frequently rotated passwords) are **sourced from Vault**.
- OME available for learning/contrast; CyberArk is Dell’s OME PAM path, not the desired vault.
