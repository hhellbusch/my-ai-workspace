# Quick Start Guide

Get up and running with global defaults in 5 minutes!

## TL;DR - The Essential Pattern

```yaml
# playbook.yml
---
- name: My application deployment
  hosts: all
  vars:
    # Global defaults here - available to ALL roles and tasks
    app_name: "myapp"
    environment: "production"
    base_dir: "/opt/{{ app_name }}"
    
  roles:
    - webserver    # Can use app_name, environment, base_dir
    - database     # Can use app_name, environment, base_dir
    - monitoring   # Can use app_name, environment, base_dir
```

**That's it!** Any variable in the playbook `vars:` section is available to all roles and tasks.

## 5-Minute Tutorial

### Step 1: Create a Simple Playbook (1 min)

```yaml
# simple_example.yml
---
- name: Deploy with global defaults
  hosts: localhost
  vars:
    company: "ACME Corp"
    app_version: "2.0"
    
  tasks:
    - name: Show global variable
      debug:
        msg: "Deploying {{ company }} app version {{ app_version }}"
```

Run it:
```bash
ansible-playbook simple_example.yml
```

### Step 2: Add a Role That Uses Globals (2 min)

Create a simple role:
```bash
mkdir -p roles/my_role/tasks
```

```yaml
# roles/my_role/tasks/main.yml
---
- name: Use global variables from playbook
  debug:
    msg: "Role sees: {{ company }} v{{ app_version }}"
```

Update playbook:
```yaml
# simple_example.yml
---
- name: Deploy with global defaults
  hosts: localhost
  vars:
    company: "ACME Corp"
    app_version: "2.0"
  
  roles:
    - my_role  # ← Role automatically sees global vars
```

### Step 3: Override for Specific Roles (1 min)

```yaml
roles:
  - role: my_role
    vars:
      app_version: "3.0"  # Override just for this role
```

### Step 4: Use Environment-Specific Configs (1 min)

```yaml
vars:
  environment: "production"
vars_files:
  - "vars/{{ environment }}.yml"  # Load environment-specific vars
```

## Common Use Cases

### Use Case 1: Shared Paths

```yaml
vars:
  app_name: "myapp"
  install_dir: "/opt/{{ app_name }}"
  log_dir: "/var/log/{{ app_name }}"
  config_dir: "/etc/{{ app_name }}"
```

All roles can now use these consistent paths.

### Use Case 2: Feature Flags

```yaml
vars:
  enable_ssl: true
  enable_monitoring: true
  enable_backups: false

roles:
  - role: monitoring
    when: enable_monitoring | bool  # Conditional execution
```

### Use Case 3: Environment Switching

```yaml
# vars/production.yml
memory_limit: "2048M"
debug_mode: false

# vars/development.yml
memory_limit: "512M"
debug_mode: true

# playbook.yml
vars:
  environment: "production"
vars_files:
  - "vars/{{ environment }}.yml"
```

### Use Case 4: Consistent Configuration

```yaml
vars:
  # Network settings all roles need
  app_domain: "example.com"
  app_port: 8080
  
  # Database connection all roles use
  db_host: "db.example.com"
  db_port: 5432
  
  # Logging all roles follow
  log_level: "info"
```

## The 4 Methods Comparison

| Method | File | When to Use | Example |
|--------|------|-------------|---------|
| **1. Playbook vars** | `playbook.yml` | Core app settings | `app_name: "myapp"` |
| **2. vars_files** | `vars/*.yml` | Environment-specific | `vars/production.yml` |
| **3. group_vars** | `group_vars/*.yml` | Infrastructure patterns | `group_vars/webservers.yml` |
| **4. host_vars** | `host_vars/*.yml` | Per-host customization | `host_vars/server1.yml` |

## One-Liners for Each Method

### Method 1: Playbook vars
```yaml
vars: { app: "myapp", version: "1.0" }
```

### Method 2: vars_files
```yaml
vars_files: ["vars/common.yml"]
```

### Method 3: group_vars
```bash
echo "timezone: UTC" > group_vars/all.yml
```

### Method 4: host_vars
```bash
echo "memory: 2048M" > host_vars/bigserver.yml
```

## Testing Your Setup

### Test 1: Print a Variable
```yaml
- debug:
    var: my_variable
```

### Test 2: Print All Variables
```yaml
- debug:
    var: vars
```

### Test 3: Check From Command Line
```bash
ansible-playbook playbook.yml -e "my_var=test_value" -vvv
```

## Most Common Mistake (and Fix)

### ❌ MISTAKE: Using role vars/main.yml
```yaml
# roles/myapp/vars/main.yml - DON'T DO THIS!
app_port: 8080  # Too hard to override!
```

### ✅ FIX: Use role defaults/main.yml
```yaml
# roles/myapp/defaults/main.yml - DO THIS!
app_port: 8080  # Easy to override from playbook
```

**Why?** Role `vars/` has very high precedence and can't be easily overridden by playbook vars.

## Real-World Example

```yaml
---
# production_deploy.yml - Complete working example
- name: Deploy multi-tier application
  hosts: app_servers
  become: true
  
  vars:
    # Global application settings
    app_name: "webstore"
    app_version: "2.1.0"
    environment: "production"
    
    # Paths derived from globals
    app_home: "/opt/{{ app_name }}"
    app_logs: "/var/log/{{ app_name }}"
    app_config: "/etc/{{ app_name }}"
    
    # Feature toggles
    use_ssl: true
    use_cdn: true
    use_cache: true
    
    # Resource limits
    max_memory: "1024M"
    max_connections: 200
    
  vars_files:
    - "secrets/{{ environment }}.yml"  # Load secrets
    - "config/{{ environment }}.yml"   # Load environment config
  
  pre_tasks:
    - name: Create application directories
      file:
        path: "{{ item }}"
        state: directory
      loop:
        - "{{ app_home }}"
        - "{{ app_logs }}"
        - "{{ app_config }}"
  
  roles:
    - common           # Setup common requirements
    - webserver        # Deploy web tier
    - application      # Deploy application code
    - database         # Configure database
    - monitoring       # Setup monitoring (if enabled)
    
  post_tasks:
    - name: Deployment complete
      debug:
        msg: "{{ app_name }} v{{ app_version }} deployed successfully"
```

Run it:
```bash
ansible-playbook -i inventory.yml production_deploy.yml
```

Override for testing:
```bash
ansible-playbook -i inventory.yml production_deploy.yml \
  -e "environment=staging" \
  -e "app_version=2.2.0-beta"
```

## Cheat Sheet

```yaml
# Set global defaults (pick one or combine):

# Option 1: In playbook
vars:
  my_var: "value"

# Option 2: In external file
vars_files:
  - "vars/common.yml"

# Option 3: In inventory group
# group_vars/all.yml
my_var: "value"

# Option 4: Per host
# host_vars/hostname.yml
my_var: "value"

# Override from command line:
ansible-playbook playbook.yml -e "my_var=override"
```

## Next Steps

1. ✅ Read the full [README.md](README.md) for detailed explanations
2. ✅ Check [PRECEDENCE-GUIDE.md](PRECEDENCE-GUIDE.md) to understand which vars win
3. ✅ Try the complete example: `ansible-playbook -i inventory.yml main_playbook.yml --check`
4. ✅ Adapt the pattern to your own playbooks!

## Help! It's Not Working

### Problem: Variable is undefined
**Solution**: Check spelling, and verify the variable is set before the role runs:
```yaml
- debug:
    var: my_variable
```

### Problem: Wrong value is being used
**Solution**: Check variable precedence - extra vars (`-e`) always win. See PRECEDENCE-GUIDE.md

### Problem: Role can't see playbook variables
**Solution**: Verify the variable is set in the `vars:` section of the play (same level as `roles:`)

### Problem: Variables not persisting across roles
**Solution**: Variables DO persist. Use `debug` to verify:
```yaml
post_tasks:
  - debug:
      var: my_variable
```

---

**Still stuck?** Check the full example in this directory or open an issue!

