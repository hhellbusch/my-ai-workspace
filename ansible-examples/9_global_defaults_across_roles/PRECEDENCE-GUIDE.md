# Variable Precedence Guide

Understanding Ansible's variable precedence is crucial for setting global defaults effectively.

## Complete Precedence Order (Lowest to Highest)

1. **command line values** (e.g., `-u my_user`, these are not variables)
2. **role defaults** (`roles/x/defaults/main.yml`)
3. **inventory file or script group vars**
4. **inventory group_vars/all**
5. **playbook group_vars/all**
6. **inventory group_vars/***
7. **playbook group_vars/***
8. **inventory file or script host vars**
9. **inventory host_vars/***
10. **playbook host_vars/***
11. **host facts / cached set_facts**
12. **play vars**
13. **play vars_prompt**
14. **play vars_files**
15. **role vars** (defined in `roles/x/vars/main.yml`)
16. **block vars** (only for tasks in block)
17. **task vars** (only for the task)
18. **include_vars**
19. **set_facts / registered vars**
20. **role (and include_role) params**
21. **include params**
22. **extra vars** (`-e` on command line) - **ALWAYS WIN**

## Practical Examples

### Example 1: Basic Override Chain

```yaml
# roles/webserver/defaults/main.yml
webserver_port: 80  # Precedence: 2 (role defaults)

# group_vars/all.yml
webserver_port: 8080  # Precedence: 4 (group_vars/all) - WINS over role defaults

# playbook.yml
vars:
  webserver_port: 9090  # Precedence: 12 (play vars) - WINS over group_vars

# Command line
ansible-playbook playbook.yml -e "webserver_port=7070"  # Precedence: 22 - ALWAYS WINS
```

**Result**: Port 7070 is used (extra vars win)

### Example 2: Group vs Host Variables

```yaml
# group_vars/production.yml
memory_limit: "1024M"  # Precedence: 7

# host_vars/prod-server1.yml
memory_limit: "2048M"  # Precedence: 10 - WINS over group_vars

# playbook.yml
vars:
  memory_limit: "512M"  # Precedence: 12 - WINS over host_vars
```

**Result**: 512M is used (playbook vars win)

### Example 3: Role Vars vs Play Vars

```yaml
# roles/database/vars/main.yml (not defaults!)
db_port: 5432  # Precedence: 15 (role vars) - HIGH!

# playbook.yml
vars:
  db_port: 3306  # Precedence: 12 (play vars)
```

**Result**: Port 5432 is used! (role vars win over play vars)

**Important**: This is why we usually use `defaults/main.yml` in roles, not `vars/main.yml`!

### Example 4: Correct Use of Role Defaults

```yaml
# roles/database/defaults/main.yml
db_port: 5432  # Precedence: 2 (role defaults) - LOW

# playbook.yml
vars:
  db_port: 3306  # Precedence: 12 (play vars) - WINS
```

**Result**: Port 3306 is used (as expected)

## Best Practices for Global Defaults

### ✅ DO: Use role defaults for sensible fallbacks

```yaml
# roles/webserver/defaults/main.yml
webserver_port: 80
webserver_user: "www-data"
```

### ✅ DO: Use playbook vars for global application settings

```yaml
# playbook.yml
vars:
  app_name: "myapp"
  environment: "production"
```

### ✅ DO: Use group_vars for infrastructure patterns

```yaml
# group_vars/database_servers.yml
max_connections: 1000
backup_enabled: true
```

### ✅ DO: Use host_vars for specific host customization

```yaml
# host_vars/big-server.yml
memory_limit: "8192M"
```

### ❌ DON'T: Use role vars/main.yml for defaults

```yaml
# roles/webserver/vars/main.yml - AVOID THIS!
webserver_port: 80  # Too high precedence, hard to override
```

**Why?** `vars/main.yml` has higher precedence than play vars, making it hard to override.

### ❌ DON'T: Mix methods without understanding precedence

```yaml
# This can be confusing:
# group_vars/all.yml
app_name: "app1"

# playbook.yml
vars:
  app_name: "app2"  # This wins, but might be unclear to others
```

## Visual Precedence Chart

```
┌─────────────────────────────────┐
│   Extra Vars (-e)               │ ← HIGHEST (22) - ALWAYS WINS
├─────────────────────────────────┤
│   include params                │ (21)
│   role params                   │ (20)
│   set_facts / registered vars   │ (19)
│   include_vars                  │ (18)
│   task vars                     │ (17)
│   block vars                    │ (16)
│   role vars (vars/main.yml)     │ (15) ⚠️ HIGH - usually avoid
├─────────────────────────────────┤
│   play vars_files               │ (14) ✅ Good for environments
│   play vars_prompt              │ (13)
│   play vars                     │ (12) ✅ Good for globals
├─────────────────────────────────┤
│   host facts / cached facts     │ (11)
│   playbook host_vars/*          │ (10) ✅ Good for host overrides
│   inventory host_vars/*         │ (9)
│   inventory host vars           │ (8)
│   playbook group_vars/*         │ (7) ✅ Good for groups
│   inventory group_vars/*        │ (6)
│   playbook group_vars/all       │ (5) ✅ Good for company-wide
│   inventory group_vars/all      │ (4)
│   inventory group vars          │ (3)
│   role defaults (defaults/)     │ (2) ✅ BEST for role defaults
└─────────────────────────────────┘
     LOWEST (role defaults)
```

## Common Gotchas

### Gotcha 1: Role vars/main.yml vs defaults/main.yml

```yaml
# ❌ WRONG: roles/app/vars/main.yml
port: 8080  # Too hard to override!

# ✅ RIGHT: roles/app/defaults/main.yml
port: 8080  # Easy to override from playbook
```

### Gotcha 2: Inventory vars vs Playbook vars

```yaml
# inventory.yml
all:
  vars:
    env: "prod"  # Precedence: 3

# playbook.yml
vars:
  env: "dev"  # Precedence: 12 - WINS
```

Many people expect inventory vars to win, but playbook vars have higher precedence!

### Gotcha 3: Multiple group_vars

```yaml
# group_vars/all.yml
memory: "512M"

# group_vars/webservers.yml
memory: "1024M"  # WINS if host is in webservers group
```

More specific group vars win over `all.yml`.

### Gotcha 4: Facts can override vars

```yaml
# playbook.yml
vars:
  ansible_distribution: "MyOS"  # Won't work!

# Facts have precedence 11, play vars have 12
# But ansible_distribution is a fact variable protected by Ansible
```

## Testing Precedence

### Method 1: Debug Task

```yaml
- name: Test variable precedence
  debug:
    msg: "Value is {{ my_var }}"
```

### Method 2: Variable Dump

```yaml
- name: Dump all variables
  debug:
    var: hostvars[inventory_hostname]
```

### Method 3: Verbose Mode

```bash
ansible-playbook playbook.yml -vvv | grep "my_var"
```

### Method 4: Variable Audit

```yaml
- name: Show where variable came from
  debug:
    msg: "{{ lookup('vars', 'my_var') }}"
```

## Quick Reference Card

| Precedence Level | Location | Use For | Override Priority |
|-----------------|----------|---------|-------------------|
| 22 | `-e` flag | Emergency overrides | HIGHEST |
| 15 | `roles/x/vars/main.yml` | ⚠️ Avoid for defaults | Very High |
| 14 | `vars_files` | Environment configs | High |
| 12 | `play vars` | Global settings | High |
| 10 | `host_vars/*` | Host-specific | Medium |
| 7 | `group_vars/group` | Group-specific | Medium |
| 5 | `group_vars/all` | Company-wide | Low |
| 2 | `roles/x/defaults/main.yml` | Role defaults | LOWEST |

## Summary

**For Global Defaults That Work Well:**

1. **Put sensible defaults in** `roles/*/defaults/main.yml` (precedence 2)
2. **Set global values in playbook** `vars:` (precedence 12)
3. **Use** `vars_files:` **for environment-specific** (precedence 14)
4. **Use** `group_vars/` **for infrastructure patterns** (precedence 5-7)
5. **Use** `host_vars/` **for host-specific overrides** (precedence 9-10)
6. **Use** `-e` **flag for testing/emergencies** (precedence 22)

**Avoid:**
- Using `roles/*/vars/main.yml` for defaults (too high precedence)
- Complex precedence chains that are hard to debug
- Mixing too many precedence levels for the same variable

This approach gives you maximum flexibility while keeping behavior predictable!

