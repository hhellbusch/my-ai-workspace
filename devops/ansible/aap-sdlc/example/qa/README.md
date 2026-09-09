---
review:
  status: unreviewed
  notes: "AI-generated 2026-09-09. Copy-paste QA stubs for Ansible content/CaC repos — not wired as this workspace's CI."
---

# QA stubs (copy into a playbook or CaC repo)

> **Audience:** Same as [quality-assurance.md](../../quality-assurance.md).
> **Purpose:** Files you can drop into an automation repo so humans, agents, and CI share one lint profile.

These do **not** run as CI for Field Notes.
They are examples.

| File | Put it… |
|---|---|
| [requirements-qa.txt](requirements-qa.txt) | Playbook or CaC repo root |
| [.ansible-lint](.ansible-lint) | Repo root; adjust `profile` after a first run |
| [.pre-commit-config.yaml](.pre-commit-config.yaml) | Repo root; `pre-commit install` |
| [AGENTS.ansible.md](AGENTS.ansible.md) | Merge into that repo's `AGENTS.md` or Cursor rule |
| [github-actions/ansible-qa.yml](github-actions/ansible-qa.yml) | `.github/workflows/ansible-qa.yml` |
| [gitlab-ci/.gitlab-ci.yml](gitlab-ci/.gitlab-ci.yml) | `.gitlab-ci.yml` or an include |

Pin versions so laptop, agent venv, and CI match.
The GitHub/GitLab files install from `requirements-qa.txt` on purpose.

From this Field Notes example tree you can already lint the preview playbooks:

```bash
cd devops/ansible/aap-sdlc/example
pip install -r qa/requirements-qa.txt
ansible-lint -c qa/.ansible-lint playbooks
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
