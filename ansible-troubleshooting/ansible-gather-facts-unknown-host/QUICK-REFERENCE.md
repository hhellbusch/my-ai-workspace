# Quick Reference: Ansible gather_facts "Connection to UNKNOWN port 65535"

> **See [README.md](README.md) for full investigation guide.**

## The Error

```
Failed to connect to the host via ssh:
Connection timed out during banner exchange
Connection to UNKNOWN port 65535 timed out
```

## Instant Interpretation

| Symptom | Meaning |
|---|---|
| Host = `UNKNOWN` | `ansible_host` is unset or empty |
| Port = `65535` | `ansible_port` is unset or invalid |
| Both wrong simultaneously | Variable resolution failure — not a network problem |

---

## Step 1: Isolation Test (Run First)

```bash
# Does a minimal playbook work with the same inventory?
cat > /tmp/test-facts.yml << 'EOF'
---
- name: Test
  hosts: all
  gather_facts: true
  tasks:
    - debug:
        msg: "{{ ansible_hostname }} / {{ ansible_default_ipv4.address | default('N/A') }}"
EOF

ansible-playbook -i <inventory> /tmp/test-facts.yml
```

- ✅ Works → Problem is **inside the playbook** — continue below
- ❌ Fails → Problem is **inventory/network** — check `ansible_host` in inventory

---

## Step 2: Find the Root Cause

```bash
# A — Does the playbook use add_host?
grep -rn "add_host" your-playbook.yml roles/

# B — What hosts does each play target?
ansible-playbook -i <inventory> your-playbook.yml --list-hosts

# C — Is ansible_host overridden in vars files?
grep -rn "ansible_host\|ansible_port" vars/ group_vars/ host_vars/ roles/

# D — Is delegate_to used with a variable?
grep -rn "delegate_to" your-playbook.yml roles/

# E — Environment variable interference?
env | grep -i ansible
```

---

## Root Causes at a Glance

| # | Cause | Find It | Fix It |
|---|---|---|---|
| 1 | `add_host` missing `ansible_host` | `grep -rn add_host` | Add `ansible_host: "{{ ip }}"` to `add_host` call |
| 2 | Later play targets wrong/empty group | `--list-hosts` | Verify group is populated before connecting |
| 3 | vars file overrides `ansible_host` | `grep -rn ansible_host vars/` | Add `\| default()` guard |
| 4 | `delegate_to: "{{ undefined_var }}"` | `grep -rn delegate_to` | Add `\| default('localhost')` |
| 5 | Role `vars/` overrides connection vars | `grep -rn ansible_host roles/` | Remove or guard the override |

---

## Verbose Debug Commands

```bash
# Show resolved ansible_host for all hosts
ansible -i <inventory> all -m debug -a "var=ansible_host"

# Show SSH connection being established (look for real IP)
ansible-playbook -i <inventory> your-playbook.yml -vvv 2>&1 | grep "ESTABLISH SSH"

# Step through interactively
ansible-playbook -i <inventory> your-playbook.yml -vvv --step
```

---

## Correct `add_host` Pattern

```yaml
- ansible.builtin.add_host:
    name: "{{ host_name }}"
    groups: my_dynamic_group
    ansible_host: "{{ host_ip }}"              # required
    ansible_port: "{{ port | default(22) }}"   # required
    ansible_user: "{{ ssh_user }}"             # required
    ansible_ssh_private_key_file: "{{ key }}"  # required
```
