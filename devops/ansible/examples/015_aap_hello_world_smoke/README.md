---
review:
  status: unreviewed
  notes: "Hello-world AAP playbook — localhost, no extra collections."
---

# 015 — AAP Hello World Smoke Test

**Audience:** Someone who just stood up Ansible Automation Platform on OpenShift and wants one green job.
**Purpose:** A localhost playbook with no SSH and no extra collections, plus the AAP objects needed to run it.

```bash
cd devops/ansible/examples/015_aap_hello_world_smoke
ansible-playbook playbook.yml                         # 120s pause (OpenShift pod visibility)
ansible-playbook playbook.yml -e smoke_pause_seconds=5
```

Expected: a `debug` task printing hostname / Ansible version / OS facts, then a pause so the AAP job pod stays Running long enough to find in the OpenShift console (`oc get pods -n <aap-ns> -w`, look for `automation-job-*`).

## AAP job template

| Field | Value |
|---|---|
| Name | Hello World Smoke Test |
| Inventory | `hello-world-smoke` (host `localhost`, `ansible_connection: local`) |
| Project | this repo, `https://github.com/hhellbusch/my-ai-workspace.git` |
| Playbook | `devops/ansible/examples/015_aap_hello_world_smoke/playbook.yml` |
| Execution environment | platform default |
| Credentials | none |

AAP 2.7 still needs a subscription before a job will launch, even if the template saves.

The job runs as a Pod in a container group, not on a VM execution node.
Default landing zone is the AAP namespace.
To put the same job in a tenant namespace, see [016](../016_aap_container_group_namespace/README.md).
Context: [AAP operator on OpenShift](../../aap-operator-on-openshift.md).

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
