---
review:
  status: unreviewed
  notes: "AI-generated 2026-09-09. Copy-paste agent instructions for Ansible QA. Strip YAML frontmatter when pasting into another repo."
---

# Ansible content — agent / clanker instructions

Paste the sections below into `AGENTS.md` (or a Cursor rule) in the *playbook* or *CaC* repository.
Strip this YAML frontmatter when you paste.
Humans and CI must run the same commands. Do not invent a second linter.

## Quality gates (definition of done)

Before you say a playbook, role, or CaC apply change is done:

1. Run `ansible-lint` on the paths you changed (repo profile in `.ansible-lint`).
2. Run `ansible-playbook --syntax-check` on affected playbooks (with the inventory the humans use for that env, or `localhost` for local-only plays).
3. If the role has a `molecule/` directory, run `molecule test` for that scenario. If you cannot (missing Podman/Docker), say so instead of skipping silently.
4. Paste the **commands and exit codes** in the session. "LGTM" without that output is not done.

## Do not

- `git commit --no-verify` unless the human explicitly asked.
- Add `# noqa` or ansible-lint skips without explaining the rule and the reason.
- Treat `ansible-playbook --check` as proof against OpenShift, cloud, or custom modules that do not support check mode.
- Launch AAP jobs or apply CaC against **integration** or **production** unless the human asked.
- Develop AAP + lab is already a promotion. Ask before that too if the repo says so.
- Upgrade or unpin `ansible-lint` in CI to make a failure go away.

## Tooling

- Install from `requirements-qa.txt` (or the team's ansible-dev-tools / EE image).
- Profile and version must match CI. If they drift, stop and say so.

## CaC-specific

- Do not copy durable job templates into `experiments/` to "make lint happy."
- Preview transforms (rewritten org / git rev) before claiming an experiment is ready.
- Teardown is payload destroy twin, then org absent. Deleting the YAML file is not teardown.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
