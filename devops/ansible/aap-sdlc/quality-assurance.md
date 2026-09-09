---
review:
  status: unreviewed
  notes: "AI-generated 2026-09-09. QA companion to AAP SDLC draft. Unslop pass 2026-09-09."
---

# Quality assurance in the Ansible / AAP SDLC

> **Audience:** Automation engineers newer to QA practice, plus peers wiring humans, coding agents, and CI onto the same gates.
> **Purpose:** Map quality onto the [three artifacts](README.md) (content, CaC, payload). Name the Ansible tools that exist. Show how a workspace and an agent use them without a second toolchain.

This is not a certification syllabus.
It is evidence before promotion, the same idea as Ambler's sandboxes: cheaper checks first, blast radius contained, fixes go back to development.

Copy-paste stubs: [example/qa/](example/qa/).

---

## What QA means here

Quality is not a person who tests at the end.
It is asking these questions before the change moves to the next sandbox:

1. **Say it clearly.** YAML parses. Names match. Lint agrees with the team's profile.
2. **Does the automation behave?** A role converges twice without unexpected changes. A module's Python tests pass.
3. **Does AAP run this revision?** A job template on develop AAP executes the pinned git ref against a lab target.
4. **Did the payload do the right thing, and can we undo it?** Workers appeared. The destroy twin removes them.

If you only have (1), you have a syntax checker, not QA.
If you skip (1) and jump to a production cluster, you are using production as a linter.

**A quality gate** is a check that must pass before the change may enter the next sandbox.
The inner loop is you or an agent running that check in seconds.
The outer loop is CI running the same commands on every merge request, so skipped hooks still fail.

The usual false confidence is treating `ansible-playbook --syntax-check` as proof that "add worker" works on OpenShift.
Match the check to the artifact (table below).

---

## Evidence vs cost (the pyramid)

```
ansible-lint / yamllint / syntax-check     cheap, every save / every MR
ansible-test units                         only if you wrote Python plugins
Molecule / ansible-test integration        real Ansible vs a container or mock
develop AAP + lab target                   job template, EE, credentials
integration AAP + standing lab             closer to prod topology
production                                 operations, not discovery
```

Molecule is integration testing of roles and playbooks, not unit testing.
`ansible-test units` is unit testing of plugin Python.
Most AAP playbook shops live in the top and middle of this list.
They still need a lab gate before a content tag is safe to pin in CaC.

Cluster builds sit at the expensive end.
Treat them like the [bare-metal sandbox](../../bare-metal-dev-sandbox/README.md) fidelity tiers: G0 syntax, G1 mock/API contract, G2 lab cluster, G3/G4 real iron.
Do not require a full cluster on every lint fix.

---

## Tools you actually have

| Tool | What it answers | What it does not |
|---|---|---|
| **yamllint** | Is this YAML well-formed and styled? | Anything about Ansible meaning |
| **ansible-lint** | Does this follow the chosen [profile](https://ansible.readthedocs.io/projects/lint/profiles/) (min → production)? Deprecated modules, risky `command`, FQCN, etc. | Runtime against a host |
| **`--syntax-check`** | Will Ansible parse the play? | Tasks succeeding |
| **`--check` (check mode)** | What would change, for modules that support it | Modules that always report changed; many cloud/K8s modules lie or no-op |
| **ansible-navigator** | Run with the same EE you will use on AAP | A substitute for AAP RBAC/credentials |
| **Molecule** | Create → converge → idempotence → verify → destroy | A full OCP cluster (unless you point it at one on purpose) |
| **ansible-test sanity** | Collection static analysis (`pep8`, `validate-modules`, docs) | Playbook-only repos with no collection layout |
| **ansible-test units** | Python plugins/modules in isolation | Roles and playbooks |
| **ansible-test integration** | Collection modules vs Docker/remote | Convenience Molecule scenarios for roles |
| **ansible-sign** | Content integrity for Hub | Correctness |
| **ansible-builder** | EE image matches `execution-environment.yml` | That the playbook inside is right |
| **pre-commit** | Humans and agents hit lint before git | People passing `--no-verify` (CI must still run) |

Install locally as one toolchain, not five random `pip` tools.
[ansible-dev-tools](https://www.redhat.com/en/blog/new-red-hat-ansible-development-tools) (or the community image) is the bundle: creator, lint, Molecule, navigator, builder.
The [workspaces article](https://developers.redhat.com/articles/2026/08/21/red-hat-ansible-development-workspaces) ships the same tools in a browser. That setup is optional.

**Content repo vs CaC repo.** Lint playbooks and roles in the playbook repo.
In the CaC repo, lint the apply playbooks and yamllint the object lists.
Do not pretend Molecule on `controller_templates:` YAML tests a cluster.

---

## Local workspace (human)

Goal: the command you run at the desk is the command CI runs.

1. Pin tools (`requirements-qa.txt` or an EE). Use the same `ansible-lint` profile as CI.
2. `pre-commit install` so a commit without lint does not feel successful.
3. A short script or Makefile target: `make qa` runs yamllint, ansible-lint, syntax-check, and Molecule if the role has a scenario.
4. Optional: `ansible-navigator run` so you are not testing laptop Ansible while AAP uses `ee-supported`.

Crawl: lint and syntax-check on every change.
Walk: Molecule on roles that target a VM or container-shaped OS.
Run: a job on **develop AAP** against lab before you cut a git tag.

Do not start at Run.
That is how production becomes the test suite.

---

## Local workspace (agent / clanker)

A coding agent will skip QA the same way a hurried human does: write YAML, open the MR, never run lint.
CI is the backstop.
The workspace exists so CI is not the first time lint runs.

Put the same commands in the repo's agent instructions (`AGENTS.md`, Cursor rule, or a skill).
A stub you can paste: [example/qa/AGENTS.ansible.md](example/qa/AGENTS.ansible.md).

What belongs in that file:

- **Definition of done** for playbook changes: `ansible-lint` and `--syntax-check` have been run on the changed paths. Paste the command and the exit code. Do not claim "tested" without that output.
- **Molecule** when the role has a `molecule/` directory. Do not invent a full cluster scenario as filler.
- **Never** `git commit --no-verify` unless the human asked.
- **Never** apply CaC or launch an AAP job against integration or production unless the human asked. Develop AAP plus lab is already a promotion.
- **Check mode** is not a cluster test. Do not report `--check` as payload QA.
- If lint fails, fix or ask. Do not add `# noqa` without saying why.

The agent and the human share one `make qa`.
If the agent uses a different linter version than CI, you get "works on my agent," which is the same bug as "works on my machine."

Optional hardening: a stop or pre-commit hook that fails if `ansible-lint` was not run in the session.
This Field Notes repo does that for markdown.
A playbook repo can do it for `*.yml` under `playbooks/` and `roles/`.
Hooks are not a substitute for CI.

---

## CI/CD on GitHub and GitLab

Run the inner-loop commands on every merge request to `main`.
Do not wait for a tag.

| When | Content repo | CaC repo |
|---|---|---|
| **MR / PR** | ansible-lint, syntax-check, Molecule (if present) | yamllint, lint apply playbooks, optional `ansible-playbook --syntax-check` of dispatch |
| **Merge to main** | Same, plus build/sign EE if you publish one | Apply to **develop AAP** only (or preview apply from the MR) |
| **Git tag** | Release artifact; may open the CaC pin MR | Not the first time lint ran |
| **Promote** | — | Apply the same git SHA to integration, then production, with evidence from the previous AAP |

Do not apply production CaC from an unreviewed branch.
Do not lint only the diff and skip the rest of the playbook tree if your roles include each other.
That pattern hides breakages ([AOP review](../../ocp/ibm-z/ansible-openshift-provisioning-review.md) hit this).

Stubs: [example/qa/github-actions/ansible-qa.yml](example/qa/github-actions/ansible-qa.yml), [example/qa/gitlab-ci/.gitlab-ci.yml](example/qa/gitlab-ci/.gitlab-ci.yml).

Use one container image in CI that matches local ansible-dev-tools where you can.
GitHub `ansible-lint-action` and GitLab `pipeline-components/ansible-lint` are fine if the version and profile match `requirements-qa.txt`.

---

## Mapping onto the three artifacts

| Artifact | Inner loop | Outer loop (CI) | Next sandbox |
|---|---|---|---|
| **Content** (playbooks) | lint, syntax, Molecule | same on MR | develop AAP job vs lab; then tag |
| **CaC** (controller objects) | yamllint, preview transform ([example](example/README.md)), lint apply play | same on MR | apply to develop AAP; `object_diff` on durable orgs only |
| **Payload** (VMs, clusters) | mocks / check mode where honest | rarely in PR CI (too expensive, too real) | lab job + destroy twin; then integration |

Promotion to the next AAP is a quality decision, not a git-branch rename.

---

## A week of crawl

1. Add `.ansible-lint` with an explicit `profile` (start `moderate`, not `production`, unless the repo already complies).
2. Add `pre-commit` plus a GitHub or GitLab job that runs `ansible-lint` on the playbook tree.
3. Paste [AGENTS.ansible.md](example/qa/AGENTS.ansible.md) into the playbook repo's agent instructions.
4. Pick one role for a Molecule scenario if it targets an OS. Skip Molecule for "talk to the cluster API" until you have a mock or a disposable lab.
5. Write down: a content tag is not cut until a develop-AAP job against lab succeeded, even if that job is still manual.

---

## What we want feedback on

1. Which **ansible-lint profile** is realistic for existing product playbooks: `basic`, `moderate`, or `production`?
2. Is Molecule required for merge, or only for roles with a container-shaped target?
3. May an agent launch jobs on develop AAP, or is that always a human click?
4. One dev-tools image in CI vs GitHub/GitLab native lint actions?

---

## Related reading

- [Parent SDLC draft](README.md)
- [QA stubs](example/qa/)
- [ansible-lint profiles](https://ansible.readthedocs.io/projects/lint/profiles/)
- [Molecule](https://docs.ansible.com/projects/molecule/)
- [Testing collections (`ansible-test`)](https://docs.ansible.com/projects/ansible/latest/dev_guide/developing_collections_testing.html)
- [Ansible development tools](https://www.redhat.com/en/blog/new-red-hat-ansible-development-tools)
- [Development workspaces](https://developers.redhat.com/articles/2026/08/21/red-hat-ansible-development-workspaces). Inner vs outer loop. Same toolchain in CI.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
