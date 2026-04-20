# AAP 2.5: ansible.controller.token 404 — Summary for Teams

**Audience:** Teams using Ansible Automation Platform (AAP) 2.5.x and the `ansible.controller.token` module (e.g. in job templates or playbooks run via AAP).  
**Purpose:** Explain why token creation fails with 404 and how to fix it.

---

## Symptom

When creating a token with the `ansible.controller.token` module (using username/password), the job fails with:

```json
"response": "{\"detail\":\"The requested resource could not be found.\"}",
"msg": "Failed to get token: HTTP Error 404: Not Found"
```

Example task:

```yaml
- name: Create a new token using username and password
  ansible.controller.token:
    scope: "write"
    state: present
    controller_host: "{{ lookup('env', 'CONTROLLER_HOST') }}"
    controller_username: "{{ lookup('env', 'CONTROLLER_USERNAME') }}"
    controller_password: "{{ lookup('env', 'CONTROLLER_PASSWORD') }}"
    request_timeout: 30
  retries: 5
  delay: 3
  register: token_creation
  until: token_creation is succeeded
```

---

## Root Cause (AAP 2.5.x)

In **AAP 2.5**, the **Platform Gateway** was introduced. The controller API is exposed **through the gateway** at a different path:

| Component        | Path pattern              | Notes                          |
|-----------------|---------------------------|--------------------------------|
| **Gateway (2.5)** | `/api/controller/v2/...` | Correct path for controller API |
| **Legacy / 2.4**  | `/api/v2/...`            | Direct controller path          |

The `ansible.controller.token` module was built for the legacy layout and calls **`/api/v2/tokens/`** (or equivalent). When `CONTROLLER_HOST` points at the gateway (e.g. `https://aap-gateway.example.com`), the request goes to:

- `https://aap-gateway.example.com/api/v2/tokens/`

That path **does not exist** on the gateway; the gateway serves the controller at **`/api/controller/v2/...`**. Hence the gateway returns **404**.

---

## Recommended Solution: Use a Pre-created Token

In AAP 2.5, token creation is intended to go through the **Gateway** (OAuth / Personal Access Tokens), not the old controller token endpoint. The most reliable approach is to **avoid creating tokens in the playbook** and use a token created once in the UI.

### Steps

1. **Create a token in the AAP UI**
   - Use the Gateway/controller token or Personal Access Token (PAT) flow (e.g. **User → Tokens** or equivalent in your 2.5 setup).
   - Create a token with the scope you need (e.g. **write**).
   - Copy the token value (it is only shown once).

2. **Store the token securely**
   - In an AAP **Credential** (e.g. “Controller API” or custom credential that holds the token), or  
   - In a **survey / extra variable** (prefer vault-encrypted), or  
   - In an **environment variable** set by the job template (e.g. `CONTROLLER_OAUTH_TOKEN`).

3. **Change the playbook to use the token**
   - Remove (or skip) the `ansible.controller.token` task.
   - Pass the token into every controller task via `controller_oauthtoken`:

```yaml
- name: Example — use existing token
  ansible.controller.<some_module>:
    controller_host: "{{ lookup('env', 'CONTROLLER_HOST') }}"
    controller_oauthtoken: "{{ controller_token }}"   # from credential or extra var
    # ... other module params
```

4. **Set `CONTROLLER_HOST`**
   - Use the **Platform Gateway** base URL (e.g. `https://aap-gateway.example.com`), with no path suffix.

---

## Checklist for Jobs Using the Controller API

| Check | Action |
|-------|--------|
| **CONTROLLER_HOST** | Must be the **Gateway** base URL (e.g. `https://gateway.example.com`), not the old direct controller URL. |
| **Hub vs Gateway** | In hub + controller setups, use the **gateway** URL, not the hub. |
| **Token creation** | Prefer creating the token in the UI (Gateway/PAT) and passing it in; avoid `ansible.controller.token` for creation. |
| **Collection version** | Use an `ansible.controller` (or `awx.awx`) version that supports AAP 2.5 and the gateway. |

---

## Verification

After switching to a pre-created token:

- Run a simple controller task (e.g. `ansible.controller.ping` or list inventories) with `controller_oauthtoken` set.
- Confirm the job completes without 404; any auth failure will typically return 401/403, not 404.

---

## Optional: If You Must Create a Token in the Playbook

If you cannot use a pre-created token, you can try:

- Set **CONTROLLER_HOST** to include the gateway’s controller path, for example:  
  `https://aap-gateway.example.com/api/controller`  
  so that the module might request `.../api/controller/v2/tokens/`.  
  This is **version-dependent** and may not work with all collection versions.

- Confirm the **ansible.controller** collection in your execution environment is a version documented to support AAP 2.5.

This approach is less reliable than using a token created via the Gateway/UI.

---

## References

- **AAP 2.5 API:** Controller resources via Gateway — `/api/controller/v2/` (see Red Hat AAP 2.5 *Automation execution API overview*).
- **AAP 2.4 → 2.5:** Red Hat Solution [7131069](https://access.redhat.com/solutions/7131069) — AAP 2.5–2.4 API access point differences.
- **404 with ansible.controller on 2.4:** Red Hat Solution [7115139](https://access.redhat.com/solutions/7115139) — same error pattern; in 2.5 the cause is the gateway path change.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
