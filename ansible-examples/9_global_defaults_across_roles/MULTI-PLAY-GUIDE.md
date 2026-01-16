# Multi-Play Playbooks Guide

This guide explains how to handle global defaults when you have multiple plays (named sections) in a single playbook.

## Understanding Plays

A **play** is each top-level section in a playbook that starts with `- name:`. Each play:
- Targets a specific host or group
- Has its own variable scope
- Can include roles and tasks
- Variables defined in one play **do NOT** automatically flow to the next play

## Example: Multiple Plays

```yaml
---
# PLAY 1
- name: First play
  hosts: webservers
  vars:
    my_var: "value1"
  tasks:
    - debug: msg="{{ my_var }}"  # Works

# PLAY 2
- name: Second play
  hosts: databases
  tasks:
    - debug: msg="{{ my_var }}"  # ❌ FAILS - my_var not defined here!
```

## Four Approaches to Share Variables Across Plays

### Approach 1: vars_files (RECOMMENDED) ⭐

Load the same variable files in each play.

**Advantages:**
- ✅ Simple and clean
- ✅ DRY (Don't Repeat Yourself)
- ✅ Easy to maintain
- ✅ Environment switching built-in

**Example:**

```yaml
# vars/common.yml
app_name: "myapp"
app_version: "1.0.0"

---
# Playbook
- name: Play 1
  hosts: webservers
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  tasks:
    - debug: msg="{{ app_name }}"  # ✅ Works

- name: Play 2
  hosts: databases
  vars_files:
    - vars/common.yml              # Load same files
    - "vars/{{ environment }}.yml"
  tasks:
    - debug: msg="{{ app_name }}"  # ✅ Works
```

**See:** `multi_play_vars_files.yml`

### Approach 2: set_fact with cacheable

Use `set_fact` with `cacheable: yes` in the first play.

**Advantages:**
- ✅ Variables computed at runtime
- ✅ Can derive values from facts or previous tasks

**Disadvantages:**
- ⚠️ More complex
- ⚠️ Need to set fact caching in ansible.cfg
- ⚠️ Variables must be prefixed to avoid conflicts

**Example:**

```yaml
- name: Play 1
  hosts: localhost
  tasks:
    - set_fact:
        shared_app_name: "myapp"
        shared_version: "1.0"
        cacheable: yes  # Makes available to next plays

- name: Play 2
  hosts: localhost
  vars:
    app_name: "{{ shared_app_name }}"  # Use cached fact
  tasks:
    - debug: msg="{{ app_name }}"  # ✅ Works
```

**See:** `multi_play_example.yml`

### Approach 3: group_vars/all.yml

Define variables in inventory that apply to all hosts.

**Advantages:**
- ✅ Truly global across all plays and hosts
- ✅ No need to load in each play
- ✅ Follows standard Ansible patterns

**Disadvantages:**
- ⚠️ Tied to inventory
- ⚠️ Lower precedence than play vars

**Example:**

```yaml
# group_vars/all.yml
app_name: "myapp"
environment: "production"

---
# Playbook
- name: Play 1
  hosts: webservers
  tasks:
    - debug: msg="{{ app_name }}"  # ✅ Works

- name: Play 2
  hosts: databases
  tasks:
    - debug: msg="{{ app_name }}"  # ✅ Works (no vars_files needed!)
```

**See:** `group_vars/all.yml` in this directory

### Approach 4: Extra Vars (-e flag)

Pass variables on the command line.

**Advantages:**
- ✅ Highest precedence (overrides everything)
- ✅ Great for CI/CD pipelines
- ✅ Available to all plays automatically

**Disadvantages:**
- ⚠️ Must pass every time you run
- ⚠️ Can get verbose with many variables

**Example:**

```bash
ansible-playbook playbook.yml \
  -e "app_name=myapp" \
  -e "environment=production" \
  -e "version=1.0.0"
```

All plays will see these variables automatically.

## Comparison Table

| Approach | Complexity | Maintainability | Best For |
|----------|------------|-----------------|----------|
| **vars_files** | Low | ✅ Excellent | Most use cases |
| **set_fact** | Medium | ⚠️ Fair | Computed/runtime values |
| **group_vars** | Low | ✅ Excellent | Inventory-based config |
| **extra vars** | Low | ⚠️ Fair | CI/CD, overrides |

## Real-World Example: Multi-Stage Deployment

```yaml
---
# Complete deployment with multiple stages

# ============================================================================
# STAGE 1: Pre-flight checks
# ============================================================================
- name: Pre-flight validation
  hosts: all
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "preflight"
  
  tasks:
    - name: Validate configuration
      assert:
        that:
          - app_name is defined
          - environment in ['development', 'staging', 'production']
        fail_msg: "Configuration validation failed"

# ============================================================================
# STAGE 2: Infrastructure setup
# ============================================================================
- name: Setup infrastructure
  hosts: infrastructure_nodes
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "infrastructure"
  
  pre_tasks:
    - name: Display stage
      debug:
        msg: "{{ stage | upper }}: {{ app_name }} in {{ environment }}"
  
  roles:
    - networking
    - storage
    - load_balancer

# ============================================================================
# STAGE 3: Application deployment
# ============================================================================
- name: Deploy application
  hosts: application_nodes
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "application"
    deployment_strategy: "rolling"
  
  serial: 2  # Deploy to 2 hosts at a time
  
  pre_tasks:
    - name: Display stage
      debug:
        msg: "{{ stage | upper }}: {{ app_name }} v{{ app_version }}"
  
  roles:
    - webserver
    - application
    - cache

# ============================================================================
# STAGE 4: Database migration
# ============================================================================
- name: Run database migrations
  hosts: database_primary
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "database"
  
  tasks:
    - name: Run migrations for {{ app_name }}
      debug:
        msg: "Running database migrations"

# ============================================================================
# STAGE 5: Monitoring and verification
# ============================================================================
- name: Configure monitoring
  hosts: monitoring_nodes
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "monitoring"
  
  roles:
    - monitoring
    - alerting

# ============================================================================
# STAGE 6: Health checks
# ============================================================================
- name: Verify deployment
  hosts: all
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  vars:
    stage: "verification"
  
  tasks:
    - name: Run health checks
      debug:
        msg: "Verifying {{ app_name }} v{{ app_version }} in {{ environment }}"
    
    - name: Deployment complete
      debug:
        msg: |
          ╔════════════════════════════════════════╗
          ║   DEPLOYMENT SUCCESSFUL                ║
          ╠════════════════════════════════════════╣
          ║ Application: {{ app_name }}
          ║ Version: {{ app_version }}
          ║ Environment: {{ environment }}
          ╚════════════════════════════════════════╝
```

## Best Practices

### ✅ DO: Use vars_files for shared configuration

```yaml
# All plays load the same files
vars_files:
  - vars/common.yml
  - "vars/{{ environment }}.yml"
```

### ✅ DO: Use play-specific vars for play-unique settings

```yaml
- name: Deploy application
  vars_files:
    - vars/common.yml  # Shared
  vars:
    stage: "application"  # Play-specific
    deployment_strategy: "blue-green"  # Play-specific
```

### ✅ DO: Use group_vars for infrastructure patterns

```yaml
# group_vars/webservers.yml
max_connections: 1000
worker_processes: 4
```

### ✅ DO: Validate critical variables in first play

```yaml
- name: Validate configuration
  tasks:
    - assert:
        that:
          - app_name is defined
          - environment is defined
```

### ❌ DON'T: Repeat variable definitions across plays

```yaml
# ❌ BAD: Duplicated in each play
- name: Play 1
  vars:
    app_name: "myapp"  # Duplicated
    version: "1.0"     # Duplicated

- name: Play 2
  vars:
    app_name: "myapp"  # Duplicated
    version: "1.0"     # Duplicated
```

```yaml
# ✅ GOOD: Define once in vars file
- name: Play 1
  vars_files: [vars/common.yml]
  
- name: Play 2
  vars_files: [vars/common.yml]
```

### ❌ DON'T: Assume variables from previous play are available

```yaml
# ❌ BAD: my_var not defined in Play 2
- name: Play 1
  vars:
    my_var: "value"

- name: Play 2
  tasks:
    - debug: msg="{{ my_var }}"  # FAILS
```

### ❌ DON'T: Use set_fact without cacheable for cross-play sharing

```yaml
# ❌ BAD: Not available in next play
- name: Play 1
  tasks:
    - set_fact:
        my_var: "value"  # Missing cacheable: yes

- name: Play 2
  tasks:
    - debug: msg="{{ my_var }}"  # FAILS
```

## Summary

**For Multiple Plays, Use This Pattern:**

```yaml
---
# Define shared config in vars/common.yml
- name: Play 1
  hosts: group1
  vars_files:
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  vars:
    play_specific_var: "value"
  roles:
    - role1

- name: Play 2
  hosts: group2
  vars_files:
    - vars/common.yml              # Same files
    - "vars/{{ environment }}.yml"  # Same files
  vars:
    play_specific_var: "different"  # Different values per play
  roles:
    - role2
```

**Key Points:**
1. Each play has its own variable scope
2. Use `vars_files` to load shared configuration
3. Define play-specific variables in `vars:` section
4. Load same `vars_files` in all plays for consistency
5. Use `group_vars/all.yml` for truly global settings

See the example files for working demonstrations!






