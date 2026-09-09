---
review:
  status: unreviewed
  notes: "AI-generated 2026-09-09. Example tree for AAP SDLC discussion draft — preview playbook is localhost-only."
---

# Example shape — product CaC + experiment retarget

> **Audience:** Same as the [parent note](../README.md).
> **Purpose:** Show the files a peer would look at, and a localhost preview of “durable YAML + experiment manifest → object lists.”

This is **not** wired to `infra.aap_configuration.dispatch`.
Do not point it at a real AAP.

## Layout

```
example/
  inventories/                 # which AAP — not a copy of product YAML
    develop.yml
    integration.yml
    production.yml
  config/
    platform/                  # shared EE / credential types (stub)
    ocp-day2/
      versions.yml             # default content pin (release tag)
      durable/                 # one tree; org and git rev are variables
      experiments/
        EXP-123-add-workers.yml
  playbooks/
    preview_experiment.yml     # run this
    aap_config.yml             # durable apply — stub comments only
    experiment_teardown.yml    # destroy twin then org absent — stub
```

## Preview (no AAP)

From this directory:

```bash
cd devops/ansible/aap-sdlc/example
ansible-playbook playbooks/preview_experiment.yml
```

You should see `aap_organizations[].name: exp-EXP-123-add-workers` and the project `scm_revision: feat/add-workers`.

Compare with a durable apply against develop (still no controller — debug only):

```bash
ansible-playbook playbooks/preview_durable.yml -i inventories/develop.yml
```

That run should show `Team-OCP` and `scm_revision: v1.2.3` from `versions.yml` via the inventory.

## What to look at

| File | Point |
|---|---|
| `config/ocp-day2/durable/*.yml` | Same lists for every AAP; `{{ product_org }}` / `{{ content_revision }}` |
| `config/ocp-day2/experiments/EXP-123-add-workers.yml` | Manifest only — no copied job templates |
| `inventories/*.yml` | Env is hostname + pin overlay + org name |
| `durable/workflows.yml` | Create and destroy twins in one graph |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
