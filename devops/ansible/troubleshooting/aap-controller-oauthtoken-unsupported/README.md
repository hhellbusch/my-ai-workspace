---
review:
  status: unreviewed
  notes: "Initial draft from AAP 2.6 controller_oauthtoken troubleshooting session."
---

# AAP: `controller_oauthtoken` unsupported parameter — Summary for Teams

**Audience:** Teams running Configuration-as-Code playbooks or job templates against AAP 2.5+ (especially 2.6) that call `ansible.controller.*` modules (directly or via `infra.aap_configuration` roles).

**Purpose:** Explain why `controller_oauthtoken` fails parameter validation, how to diagnose collection/EE mismatches, and how to fix auth for current AAP releases.

---

## Symptom

A playbook or role that worked in a template repo fails in your environment with:

```text
Unsupported parameters for (ansible.controller.credential) module: controller_oauthtoken.
Supported parameters include: aap_token, controller_config_file, controller_host, ...
```

The failure can appear on any `ansible.controller.*` module — not only `credential`.
Roles such as `infra.aap_configuration.controller_credentials` may surface the same error even when you pass `aap_token` at the role level, because older role versions still map auth to `controller_oauthtoken` internally.

Example failing task (module-level auth):

```yaml
- name: Create or update a credential
  ansible.controller.credential:
    name: my-credential
    organization: Default
    credential_type: Machine
    controller_host: "{{ aap_hostname }}"
    controller_oauthtoken: "{{ my_token }}"
    inputs:
      username: admin
      password: "{{ vault_password }}"
    state: present
```

---

## Overview

This error means the **`ansible.controller` collection version in the execution environment (EE)** does not accept `controller_oauthtoken` as a module argument.
It is usually **not** an `ansible-playbook` or ansible-core version problem.
The playbook logic may be fine; the collection bundled in the EE changed underneath it.

Two separate concepts often get conflated:

| Concept | What it is | Example |
| --- | --- | --- |
| **Module auth params** | How the module authenticates *to* the Controller/Gateway API | `aap_token`, `controller_oauthtoken`, `aap_username` |
| **Credential `inputs`** | Fields on the credential *being created* in Controller | Vault URL, SSH key, machine password |

The unsupported-parameter error applies to **module auth**, not to credential type input schemas.

---

## Isolation test

Run inside the **same EE** (or container) that executes the failing job:

```bash
ansible-galaxy collection list ansible.controller ansible.platform
ansible --version
```

Then run a minimal ping task:

```yaml
- name: Verify controller API auth
  ansible.controller.ping:
    aap_hostname: "{{ aap_hostname }}"
    aap_token: "{{ aap_token }}"
```

| Result | Likely meaning |
| --- | --- |
| Ping succeeds with `aap_token` | Auth works; update playbook/role to use `aap_*` params |
| Ping fails with same unsupported-param error on `controller_oauthtoken` | EE collection rejects the old param name |
| Ping returns 401/403 | Token or hostname wrong — different problem |
| Ping returns 404 | Gateway URL/path issue — see [AAP token 404 guide](../aap-controller-token-404/README.md) |

---

## Root causes (by likelihood)

### 1. AAP 2.6 EE/playbook naming mismatch (most common on 2.6)

AAP 2.6 standardizes auth parameter names across platform collections.
Templates written for 2.4/2.5 often still use `controller_host` and `controller_oauthtoken`.

Red Hat's [lifecycle matrix](https://access.redhat.com/support/policy/updates/ansible-automation-platform) documents these collection ranges for CaC on AAP 2.6:

| Collection | AAP 2.6 requirement |
| --- | --- |
| `ansible.controller` | >= 4.7, < 4.8 |
| `ansible.platform` | >= 2.6, < 2.6.20260306 |
| ansible-core | 2.16 |

**Fix:** Update module auth to the 2.6 names and point at the **platform gateway** hostname:

| Old (2.4/2.5) | AAP 2.6 |
| --- | --- |
| `controller_host` | `aap_hostname` |
| `controller_oauthtoken` | `aap_token` |
| `controller_username` | `aap_username` |
| `controller_password` | `aap_password` |
| `controller_validate_certs` | `aap_validate_certs` |
| `ansible.controller.token` | `ansible.platform.token` (removed from `ansible.controller` in 4.7) |

Example (2.6):

```yaml
- name: Create or update a credential
  ansible.controller.credential:
    name: my-credential
    organization: Default
    credential_type: Machine
    aap_hostname: "{{ gateway_url }}"
    aap_token: "{{ platform_pat }}"
    inputs:
      username: admin
      password: "{{ vault_password }}"
    state: present
```

Environment variable fallbacks still work: `AAP_TOKEN`, `CONTROLLER_OAUTH_TOKEN`, `TOWER_OAUTH_TOKEN`.

### 2. Custom EE out of sync with the platform (any AAP version)

The platform may be AAP 2.6 while the job's EE still ships an older `ansible.controller` build (for example 4.6.18 from a pre-upgrade EE image).

**Identification:** `ansible-galaxy collection list` inside the EE shows `ansible.controller` 4.6.x while the platform is 2.6.

**Fix:**

- Rebuild the EE from **Private Automation Hub** (or console.redhat.com), not public Galaxy alone.
- Pin collections to versions that match your AAP release (see table above).
- Assign the updated EE to the job template and re-run.

Example `requirements.yml` for AAP 2.6:

```yaml
---
collections:
  - name: ansible.controller
    version: ">=4.7.0,<4.8"
  - name: ansible.platform
    version: ">=2.6.0"
  - name: infra.aap_configuration
```

Pull certified collections from hub — `ansible.controller` and `ansible.platform` are not fully represented on public Galaxy.

### 3. Known regression in `ansible.controller` 4.6.18 (AAP 2.5)

Version **4.6.18** dropped `controller_oauthtoken` as an accepted alias while introducing `aap_token`, but the alias wiring was broken.
Roles passing `controller_oauthtoken` (including `infra.aap_configuration` 3.4.x) fail on any controller module.

Reported in [infra.aap_configuration #1145](https://github.com/redhat-cop/infra.aap_configuration/issues/1145).
Fixed in **4.6.19** ([RHBA-2025:14709](https://access.redhat.com/errata/RHBA-2025:14709)).

**Fix options:**

| Option | When to use |
| --- | --- |
| Upgrade to `ansible.controller` >= 4.6.19 | Preferred on AAP 2.5 |
| Use `aap_token` instead of `controller_oauthtoken` | Works on 4.6.18 without downgrade |
| Downgrade to 4.6.16 | Temporary workaround only; prefer upgrade |

### 4. Stale `infra.aap_configuration` role version

If you pass `aap_token` to a role but the failure still mentions `controller_oauthtoken` in `module_args`, an older role may be translating your vars to the deprecated param against a collection that no longer accepts it.

**Fix:** Upgrade `infra.aap_configuration` to a release documented for your AAP version and align auth vars with the role's `auth.yml` pattern (`aap_hostname` + `aap_token`).

---

## Investigation workflow

1. **Confirm scope** — Is the error on module auth (`controller_oauthtoken`) or credential `inputs`? (See overview table.)
2. **Inspect the EE** — `ansible-galaxy collection list ansible.controller ansible.platform` in the job's runtime environment.
3. **Map AAP version to collection range** — Use the lifecycle matrix; 2.6 requires `ansible.controller` 4.7.x.
4. **Run the ping isolation test** — With `aap_hostname` + `aap_token` and a gateway-issued PAT.
5. **Update playbook or EE** — Param rename and/or EE rebuild; do not assume the platform version alone fixes collection drift.
6. **Re-run the original task** — Confirm idempotent success.

---

## Token and hostname checklist

| Check | Action |
| --- | --- |
| **Hostname** | Use the **platform gateway** base URL (e.g. `https://aap.example.com`), not a direct controller service URL. |
| **Token type** | Use a **platform gateway PAT** (User → Tokens in gateway UI on 2.6). Legacy controller-only tokens may not work through the gateway. |
| **Token creation in playbook** | On AAP 2.6 with `ansible.controller` 4.7+, use `ansible.platform.token` — not `ansible.controller.token` (removed in 4.7). Prefer UI-created PATs for job templates. |
| **Collection source** | Install from Private Automation Hub / console.redhat.com for certified AAP collections. |
| **EE assignment** | Job template must reference the EE you rebuilt — not a stale image tag in the registry. |

---

## Prevention

- **Version-lock EE collections** to the AAP release you run (`requirements.yml` in EE build).
- **Use `aap_*` auth params** in new playbooks even when aliases exist — matches 2.6 CaC conventions and survives deprecations.
- **Test EE builds** with `ansible.controller.ping` before promoting to production job templates.
- **Treat template repos as versioned** — a playbook tested against AAP 2.4/2.5 is not automatically valid on 2.6 without param and collection updates.

---

## Verification

After applying fixes:

```yaml
- name: Verify gateway auth
  ansible.controller.ping:
    aap_hostname: "{{ gateway_url }}"
    aap_token: "{{ platform_pat }}"
```

Then re-run the original `ansible.controller.credential` (or role) task.
Auth failures typically return **401/403**; unsupported-parameter errors mean the collection/params are still mismatched.

---

## Related guides

- [AAP 2.5 `ansible.controller.token` 404](../aap-controller-token-404/README.md) — Gateway API path changes and pre-created token workflow
- [Ansible troubleshooting index](../README.md)

---

## References

- [Red Hat AAP lifecycle — collection version matrix](https://access.redhat.com/support/policy/updates/ansible-automation-platform)
- [AAP 2.6 — Configure access with tokens](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/secure-assembly_gw_token_based_authentication)
- [AAP 2.6 — What's new (unified `AAP_` env/param naming)](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/release_notes/index)
- [infra.aap_configuration #1145 — 4.6.18 regression](https://github.com/redhat-cop/infra.aap_configuration/issues/1145)
- [RHBA-2025:14709 — Fix `controller_oauthtoken` / `aap_token` in 4.6.19](https://access.redhat.com/errata/RHBA-2025:14709)
- [infra.aap_configuration getting started](https://github.com/redhat-cop/infra.aap_configuration/blob/devel/docs/GETTING_STARTED.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
