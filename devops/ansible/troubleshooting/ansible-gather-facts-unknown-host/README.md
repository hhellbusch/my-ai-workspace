# Troubleshooting: Ansible gather_facts Fails with "Connection to UNKNOWN port 65535"

## Overview

When an Ansible playbook fails during `gather_facts` with the following error, both the hostname and port values are clearly wrong — this pattern points to a **variable resolution failure**, not a network or firewall problem:

```
FAILED! => {"msg": "Failed to connect to the host via ssh:
Connection timed out during banner exchange\r\n
Connection to UNKNOWN port 65535 timed out"}
```

### Why These Values Are Significant

| Value | What It Means |
|---|---|
| `UNKNOWN` | `ansible_host` was never set or resolved to an empty string |
| `65535` | `ansible_port` resolved to max TCP port (65535), indicating a bad/missing integer value |
| Banner exchange timeout | SSH reached a port, but it was the wrong one |

Both values appearing simultaneously is a strong indicator that Ansible's connection variables are either unset or being overridden somewhere **within the playbook itself**, not in the base inventory.

## Severity

**HIGH** — Playbook cannot execute. All tasks that depend on gathered facts will fail.

## Key Diagnostic Step: Isolation Test

Before investigating the playbook internals, confirm whether the issue is environmental (network/firewall) or playbook-specific by running a minimal gather_facts playbook against the same inventory:

```yaml
---
- name: Gather facts - isolation test
  hosts: all
  gather_facts: true
  tasks:
    - name: Show connection details
      ansible.builtin.debug:
        msg:
          - "hostname: {{ ansible_hostname }}"
          - "ip: {{ ansible_default_ipv4.address | default('N/A') }}"
          - "os: {{ ansible_distribution }} {{ ansible_distribution_version }}"
```

```bash
ansible-playbook -i <your-inventory> gather-facts-test.yml
```

**Interpretation:**

- ✅ **Simple playbook succeeds** → Problem is inside the original playbook (inventory and network are fine). Continue with the investigation below.
- ❌ **Simple playbook also fails** → Network or inventory problem. See [aap-ssh-mtu-issues](../aap-ssh-mtu-issues/README.md) and the Inventory section below.

---

## Investigation Workflow

### Phase 1: Identify What Ansible Is Resolving

Before reading any code, confirm exactly what Ansible sees at runtime:

```bash
# List all hosts Ansible will target per play
ansible-playbook -i <inventory> your-playbook.yml --list-hosts

# Check resolved variables for a specific host
ansible -i <inventory> <hostname> -m debug -a "var=ansible_host"
ansible -i <inventory> <hostname> -m debug -a "var=ansible_port"
ansible -i <inventory> <hostname> -m debug -a "var=ansible_user"
```

```bash
# Run with maximum verbosity — look for the resolved host/port before each connection attempt
ansible-playbook -i <inventory> your-playbook.yml -vvv 2>&1 | grep -E "ESTABLISH|ansible_host|ansible_port|port="
```

```bash
# Step through interactively to pinpoint the exact failing play/task
ansible-playbook -i <inventory> your-playbook.yml -vvv --step
```

---

### Phase 2: Check for Common Root Causes

#### Root Cause 1: `add_host` Without Connection Variables (Most Common)

If the playbook dynamically adds hosts but does not pass `ansible_host` or `ansible_port`, Ansible creates the host entry with no connection details. A subsequent play targeting that dynamic group will connect to `UNKNOWN:65535`.

**How to identify:**

```bash
grep -n "add_host" your-playbook.yml roles/*/tasks/*.yml
```

**What bad `add_host` usage looks like:**

```yaml
# Missing ansible_host — host added without connection details
- name: Register new host
  ansible.builtin.add_host:
    name: "{{ server_name }}"
    groups: provisioned_servers
    # ansible_host is not set here
    # ansible_port is not set here
```

**Fix:**

```yaml
- name: Register new host
  ansible.builtin.add_host:
    name: "{{ server_name }}"
    groups: provisioned_servers
    ansible_host: "{{ server_ip }}"
    ansible_port: 22
    ansible_user: "{{ ssh_user }}"
    ansible_ssh_private_key_file: "{{ ssh_key_path }}"
```

---

#### Root Cause 2: Multi-Play Playbook Targeting the Wrong Host Group

A playbook with multiple plays may have a later play that targets a group which is either empty or populated with hosts lacking connection vars — while the first play (which your simple test replicates) succeeds fine.

**How to identify:**

```bash
# List all plays and their host targets
grep -n "^\- name\|^  hosts:" your-playbook.yml
```

Look for:
- Plays targeting groups that come from `add_host` (see Root Cause 1)
- Plays targeting groups defined elsewhere that may have incomplete host vars
- Plays with `hosts: "{{ some_variable }}"` where the variable may not resolve

**Example pattern to look for:**

```yaml
# Play 1 — works fine
- name: Run preflight checks
  hosts: target_servers   # defined in static inventory — works
  gather_facts: true

# Play 2 — fails
- name: Configure provisioned hosts
  hosts: newly_provisioned   # populated by add_host in Play 1 — may lack ansible_host
  gather_facts: true
```

---

#### Root Cause 3: `vars_files` or `group_vars` Overriding Connection Variables

A vars file loaded by the full playbook (but not your simple test) may be setting `ansible_host` or `ansible_port` to empty or incorrect values.

**How to identify:**

```bash
# Search for any file that sets these connection variables
grep -rn "ansible_host\|ansible_port\|ansible_user" \
  vars/ group_vars/ host_vars/ roles/ \
  --include="*.yml" --include="*.yaml"
```

Look for patterns like:

```yaml
# Incorrect — sets ansible_host to an undefined or empty variable
ansible_host: "{{ provisioned_ip }}"   # what if provisioned_ip is never set?
ansible_port: "{{ custom_port | int }}"  # what if custom_port is undefined?
```

**Fix:** Add defaults for any variable that drives connection parameters:

```yaml
ansible_host: "{{ provisioned_ip | default(inventory_hostname) }}"
ansible_port: "{{ custom_port | default(22) | int }}"
```

---

#### Root Cause 4: `delegate_to` with an Unresolved Variable

If a task delegates to a host whose variable is undefined or empty, Ansible will try to connect to the empty/default value rather than a real host.

**How to identify:**

```bash
grep -n "delegate_to" your-playbook.yml roles/*/tasks/*.yml
```

**What to look for:**

```yaml
- name: Run command on provisioning server
  ansible.builtin.command: ...
  delegate_to: "{{ provisioning_host }}"  # what if this var is undefined?
```

**Fix:** Ensure the variable is defined before the task, or use `default()`:

```yaml
delegate_to: "{{ provisioning_host | default('localhost') }}"
```

---

#### Root Cause 5: Role `vars/` or `defaults/` Overriding Connection Settings

A role included by the full playbook may define `ansible_host`, `ansible_port`, or `ansible_connection` in its `defaults/main.yml` or `vars/main.yml`.

**How to identify:**

```bash
grep -rn "ansible_host\|ansible_port\|ansible_connection" roles/*/defaults/ roles/*/vars/
```

Role-level variables have higher precedence than inventory variables, so even a well-configured inventory can be overridden here.

---

#### Root Cause 6: Environment Variables

Some CI/CD systems or wrappers set `ANSIBLE_HOST` or `ANSIBLE_PORT` as environment variables.

```bash
env | grep -i ansible
```

---

### Phase 3: Confirm and Fix

Once you identify the root cause:

1. Apply the fix from the relevant section above
2. Re-run with `-vvv` to confirm the resolved `ansible_host` now shows a real IP/hostname
3. Re-run the full playbook

```bash
# Confirm fix — look for real IP in connection line
ansible-playbook -i <inventory> your-playbook.yml -vvv 2>&1 | grep "ESTABLISH SSH CONNECTION"
```

Expected output after fix:
```
<192.168.1.50> ESTABLISH SSH CONNECTION FOR USER ansible_user on PORT 22
```

---

## Quick Diagnostic Checklist

Run these in order — stop at the first positive result:

```bash
# 1. Does a simple gather_facts work against the same inventory?
ansible-playbook -i <inventory> gather-facts-test.yml

# 2. What hosts does each play in the full playbook target?
ansible-playbook -i <inventory> your-playbook.yml --list-hosts

# 3. Are connection vars defined for all targeted hosts?
ansible -i <inventory> all -m debug -a "var=ansible_host"

# 4. Does the playbook use add_host?
grep -rn "add_host" your-playbook.yml roles/

# 5. Is ansible_host or ansible_port set in any vars file?
grep -rn "ansible_host\|ansible_port" vars/ group_vars/ host_vars/ roles/

# 6. Does the playbook use delegate_to with a variable?
grep -rn "delegate_to" your-playbook.yml roles/

# 7. Are there environment variables interfering?
env | grep -i ansible
```

---

## Minimal Gather Facts Test Playbook

Keep this handy for quick isolation testing:

```yaml
---
# gather-facts-test.yml
# Use to confirm inventory and network connectivity independently of a larger playbook
- name: Gather facts isolation test
  hosts: all
  gather_facts: true
  tasks:
    - name: Confirm connection details
      ansible.builtin.debug:
        msg:
          - "ansible_host resolved to: {{ ansible_host | default(inventory_hostname) }}"
          - "ansible_port resolved to: {{ ansible_port | default(22) }}"
          - "hostname: {{ ansible_hostname }}"
          - "ip: {{ ansible_default_ipv4.address | default('N/A') }}"
          - "os: {{ ansible_distribution }} {{ ansible_distribution_version }}"
```

```bash
# Run with verbose to see SSH connection details
ansible-playbook -i <inventory> gather-facts-test.yml -v
```

---

## Prevention

### 1. Always Set Connection Variables in `add_host`

Treat every `add_host` call as a contract — always explicitly set the four core connection variables:

```yaml
- ansible.builtin.add_host:
    name: "{{ host_identifier }}"
    groups: dynamic_group
    ansible_host: "{{ resolved_ip }}"        # always set
    ansible_port: "{{ ssh_port | default(22) }}"  # always set with default
    ansible_user: "{{ ssh_user }}"           # always set
    ansible_ssh_private_key_file: "{{ key }}"  # always set
```

### 2. Use `default()` for Any Variable That Drives Connection Parameters

```yaml
ansible_host: "{{ server_ip | default(omit) }}"
ansible_port: "{{ custom_port | default(22) | int }}"
```

### 3. Validate Dynamic Groups Before Connecting

Add a debug task between the `add_host` play and any play that connects to the dynamic group:

```yaml
- name: Verify dynamic group before connecting
  hosts: localhost
  tasks:
    - name: Show hosts added to dynamic group
      ansible.builtin.debug:
        msg: "{{ groups['dynamic_group'] | default([]) }}"
```

### 4. Test Multi-Play Playbooks Play by Play

During development, use `--tags` or comment out later plays to verify each play independently before running the full playbook:

```bash
ansible-playbook -i <inventory> your-playbook.yml --list-hosts
```

---

## Related Issues

- [AAP SSH MTU Issues](../aap-ssh-mtu-issues/README.md) — If the simple gather_facts test also fails, MTU or firewall may be the root cause
- [CoreOS Networking Issues](../coreos-networking-issues/README.md) — For SSH failures specific to CoreOS/RHCOS nodes

---

**Last Updated:** 2026-03-25

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
