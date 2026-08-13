---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# Ansible Troubleshooting Guides

Troubleshooting documentation for common Ansible issues applicable across AAP, AWX, and plain `ansible-playbook` environments.

## Available Guides

### Connection and Inventory Issues

- **[gather_facts "Connection to UNKNOWN port 65535"](ansible-gather-facts-unknown-host/README.md)** - Diagnose and fix gather_facts failures where the host resolves to UNKNOWN and the port to 65535, indicating Ansible connection variable resolution failure
  - **[Quick Reference](ansible-gather-facts-unknown-host/QUICK-REFERENCE.md)** - Isolation test, root cause table, and fix patterns ⚡

### AAP / Controller API

- **[AAP: `controller_oauthtoken` unsupported parameter](aap-controller-oauthtoken-unsupported/README.md)** - Module auth fails parameter validation on AAP 2.5+ (especially 2.6); collection/EE mismatch and `aap_token` migration
- **[AAP 2.5 `ansible.controller.token` 404](aap-controller-token-404/README.md)** - Token creation fails with HTTP 404 after AAP 2.5 Gateway API path changes

## Using These Guides

Each guide follows this structure:

1. **Overview** - What the error looks like and what it indicates
2. **Isolation Test** - Minimal reproducible test to narrow scope
3. **Investigation Workflow** - Phased diagnostic approach
4. **Root Causes** - Ranked by likelihood with identification and fix steps
5. **Prevention** - Patterns to avoid the issue in future playbooks

## Quick Start

1. Copy the error message and find the matching guide
2. Run the isolation test to confirm scope
3. Work through the root cause checklist
4. Apply the fix and verify with `-vvv`

## Related Resources

- **[OCP Troubleshooting](../../ocp/troubleshooting/README.md)** - OpenShift-specific issues, including [AAP SSH MTU Issues](../../ocp/troubleshooting/aap-ssh-mtu-issues/README.md)
- **[Ansible Examples](../examples/README.md)** - Patterns and best practices for playbook authoring

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
