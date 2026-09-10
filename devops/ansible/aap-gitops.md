---
review:
  status: unreviewed
  notes: "Seed note 2026-09-10. UI session via extra_settings is the same CR slot RH documents for CSRF/REDIRECT; SESSION_COOKIE_AGE itself is not applied on a cluster from this repo yet."
---

# AAP on OpenShift — GitOps layers (seed)

> **Audience:** Someone with AAP on the operator who wants settings in git, not only in the UI.
>
> **Purpose:** Name the two layers (CR vs gateway API), and record how a long lab UI session would live in GitOps. Not a runnable example yet.

The operator install is Kubernetes objects.
Organizations, job templates, and most **Settings** values are still rows in the gateway / controller database.

GitOps that only syncs the `AnsibleAutomationPlatform` CR does not own those rows unless you put them in `spec.extra_settings` (file in the pod) or apply them through the gateway API (CaC).

That split is the same one in [AAP operator on OpenShift](aap-operator-on-openshift.md) and the [AAP SDLC draft](aap-sdlc/README.md).
This note is the GitOps-shaped next step.
A full Argo Application + CaC tree is the later demo.

---

## Two layers

| Layer | Source of truth | Reconciler | What belongs here |
|---|---|---|---|
| **1. Operator CR** | YAML in git (`AnsibleAutomationPlatform`) | Argo CD / ACM Policy | Replicas, storage class, routes, `extra_settings` that land in gateway `settings.py` |
| **2. Gateway / controller API** | YAML in git (`infra.aap_configuration` / `ansible.platform`) | A playbook, `AnsibleJob`, or a Job after the Route exists | Orgs, credentials, projects, job templates, settings that live in the DB |

Do not GitOps the same key on both layers without knowing which wins.
RH’s feature-flag note is explicit: values on the CR are reapplied on reconcile and override UI/API edits.

Official CR customization: [Customize your Ansible Automation Platform Operator](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-assembly_operator_customize_aap) (AAP 2.7).
`extra_settings` examples that write gateway `settings.py`: [Configure your Ansible Automation Platform deployment](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-configure_your_ansible_automation_platform_deployment) — `REDIRECT_IS_HTTPS`, `CSRF_TRUSTED_ORIGINS` (AAP 2.7).

---

## Lab UI session (the setting that dumps the browser)

Default session cookie in the 2.7 docs sample is **30 minutes** (`Max-Age=1800`).

| UI (Settings → Platform gateway) | API / CR name | Role |
|---|---|---|
| **Session cookie age** | `SESSION_COOKIE_AGE` | Browser session length, **seconds**. This is the one that feels like “stay logged in.” |
| **Gateway access token expiration** | `gateway_access_token_expiration` | JWT gateway hands to controller / hub / EDA. Raise it with the cookie so an idle tab does not 401 on the next click. **Never `0`** — that has broken the UI ([KCS 7124312](https://access.redhat.com/solutions/7124312)). |

Session cookie procedure: [Configure platform sessions](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/configure-proc_settings_platform_gateway) — *Platform gateway*, AAP 2.7.

**Jwt expiration buffer** is a 2-second cache fudge, not session length.

Lab values (internal / demo — long on purpose):

| Setting | Lab | Meaning |
|---|---|---|
| `SESSION_COOKIE_AGE` | `604800` | 7 days |
| `gateway_access_token_expiration` | `604800` | match the cookie |

A workday lab can use `86400` (24 hours) instead.

---

## Layer 1 — GitOps the CR (`extra_settings`)

`oc explain ansibleautomationplatform.spec.extra_settings` on a 2.7 operator: list of `{setting, value}`.
RH’s documented extra settings are Django names that appear in `/etc/ansible-automation-platform/gateway/settings.py` after the gateway pod rolls.

Same slot, session cookie (intended GitOps path for this setting):

```yaml
apiVersion: aap.ansible.com/v1alpha1
kind: AnsibleAutomationPlatform
metadata:
  name: <instance>
  namespace: <aap-ns>
spec:
  extra_settings:
    - setting: SESSION_COOKIE_AGE
      value: 604800
```

Verify after reconcile (same pattern RH uses for `REDIRECT_IS_HTTPS`):

```bash
oc exec -n <aap-ns> deploy/<instance>-gateway -- \
  grep SESSION_COOKIE_AGE /etc/ansible-automation-platform/gateway/settings.py
```

**Unverified here:** this repo has not applied `SESSION_COOKIE_AGE` on a live CR.
The mechanism is the documented `extra_settings` path; the key is the documented session parameter.

`value` is typed as an object on the CRD.
RH examples use a quoted string (`'"True"'`) or a list.
If an integer is rejected, try `"604800"`.

Argo’s job on this layer is an Application whose `path` is the CR (or a Kustomize/Helm wrap of it).
No new operator, no Job, no AAP token in Argo.

---

## Layer 2 — CaC the gateway DB (JWT, and UI-equivalent PATCH)

`gateway_access_token_expiration` is a gateway **preference** (the KCS that forbids `0` reads it from `aap_gateway_api_preference`).
That is API/CaC, not a first-class CR field.

CoP role: [`infra.aap_configuration.gateway_settings`](https://github.com/redhat-cop/infra.aap_configuration/blob/devel/roles/gateway_settings/README.md).
Their example already has `gateway_access_token_expiration: 600` (ten minutes).

```yaml
gateway_settings:
  gateway_access_token_expiration: 604800
  SESSION_COOKIE_AGE: 604800   # if you are not putting it on the CR
```

Equivalent: `PATCH /api/gateway/v1/settings/` from something that already has a gateway token.

This layer is “git as source of truth” the way AAP CaC always is: a playbook (or an `AnsibleJob`) after the Route exists.
Argo does not watch those rows.

Pick **one** home for `SESSION_COOKIE_AGE`.
CR `extra_settings` is the one that survives “GitOps the install.”
CaC is the one that matches **Settings → Platform gateway** in the UI.

---

## What the later example should contain

Not in this repo yet:

1. A Kustomize (or Helm) directory with the parent CR, including lab `extra_settings`.
2. An Argo CD `Application` pointed at that path, destination the AAP namespace.
3. A small `gateway_settings.yml` + dispatch snippet for DB preferences the CR does not own.
4. A README that states layer 1 vs layer 2 and does not GitOps secrets (admin password stays a Secret the CR references).

Until then, this file is the reference.

---

## Related reading

- [AAP operator on OpenShift](aap-operator-on-openshift.md) — which objects the CR actually creates
- [AAP / Ansible SDLC](aap-sdlc/README.md) — CaC of orgs / templates (layer 2), not the operator CR
- [Use session authentication](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/secure-proc_controller_api_session_auth) — cookie / `SESSION_COOKIE_AGE`, AAP 2.7

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
