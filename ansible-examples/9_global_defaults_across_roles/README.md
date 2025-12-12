# Global Defaults Across Playbooks and Roles

This example demonstrates how to set default values globally for an Ansible playbook and make them available to all subsequent tasks and roles.

## Overview

When working with multiple roles, you often need to share configuration across all of them. This example shows **four methods** for setting global defaults and explains their precedence.

## Methods for Setting Global Defaults

### Method 1: Playbook `vars`
**Location**: `main_playbook.yml` - `vars:` section  
**Precedence**: High (overrides role defaults)  
**Best for**: Core application settings that shouldn't change

```yaml
vars:
  app_name: "myapp"
  environment: "production"
  base_install_dir: "/opt/{{ app_name }}"
```

### Method 2: `vars_files`
**Location**: External YAML files loaded in playbook  
**Precedence**: Same as playbook vars  
**Best for**: Environment-specific configurations

```yaml
vars_files:
  - "vars/common.yml"
  - "vars/{{ environment }}.yml"
```

### Method 3: `group_vars`
**Location**: `group_vars/all.yml` or `group_vars/<group_name>.yml`  
**Precedence**: Medium (overridden by playbook vars)  
**Best for**: Inventory-based defaults, company-wide standards

```yaml
# group_vars/all.yml
company_name: "Example Corp"
timezone: "UTC"
```

### Method 4: `host_vars`
**Location**: `host_vars/<hostname>.yml`  
**Precedence**: High (host-specific overrides)  
**Best for**: Per-host customization

```yaml
# host_vars/prod-server1.yml
memory_limit: "2048M"
```

## Variable Precedence (Lowest to Highest)

1. **Role defaults** (`roles/*/defaults/main.yml`) - Lowest
2. **group_vars/all.yml**
3. **group_vars/<group_name>.yml**
4. **Playbook vars_files**
5. **Playbook vars**
6. **host_vars/<hostname>.yml**
7. **Role vars** (passed to role)
8. **Extra vars** (`-e` on command line) - Highest

## Project Structure

```
9_global_defaults_across_roles/
├── README.md                      # This file - complete guide
├── QUICK-START.md                 # 5-minute tutorial
├── PRECEDENCE-GUIDE.md            # Variable precedence explained
├── MULTI-PLAY-GUIDE.md            # Multiple plays in one playbook
├── simple_example.yml             # Simplest pattern - start here
├── main_playbook.yml              # Main playbook with global vars + roles
├── multi_play_example.yml         # Multiple plays with set_fact
├── multi_play_vars_files.yml      # Multiple plays (recommended pattern)
├── inventory.yml                  # Inventory with groups
│
├── vars/                          # External variable files
│   ├── common.yml                 # Common settings for all environments
│   ├── production.yml             # Production-specific settings
│   └── development.yml            # Development-specific settings
│
├── group_vars/                    # Group-level variables
│   ├── all.yml                    # Variables for ALL hosts
│   ├── production.yml             # Variables for production group
│   └── development.yml            # Variables for development group
│
├── host_vars/                     # Host-specific variables
│   └── prod-server1.yml           # Variables for specific host
│
└── roles/                         # Role definitions
    ├── webserver/
    │   ├── defaults/main.yml      # Role-specific defaults (lowest precedence)
    │   ├── tasks/main.yml         # Tasks that use global + role vars
    │   └── templates/webserver.conf.j2
    │
    ├── database/
    │   ├── defaults/main.yml
    │   ├── tasks/main.yml
    │   └── templates/database.conf.j2
    │
    └── monitoring/
        ├── defaults/main.yml
        ├── tasks/main.yml
        └── templates/monitoring.conf.j2
```

## Running the Examples

### Basic run with default settings:
```bash
ansible-playbook -i inventory.yml main_playbook.yml
```

### Run with specific environment:
```bash
ansible-playbook -i inventory.yml main_playbook.yml -e "environment=development"
```

### Run with custom overrides (highest precedence):
```bash
ansible-playbook -i inventory.yml main_playbook.yml \
  -e "app_name=custom_app" \
  -e "memory_limit=4096M" \
  -e "debug_mode=true"
```

### Run for specific group:
```bash
ansible-playbook -i inventory.yml main_playbook.yml --limit production
```

### Check mode (dry-run):
```bash
ansible-playbook -i inventory.yml main_playbook.yml --check
```

### Run multi-play examples:
```bash
# Multiple plays with vars_files (recommended)
ansible-playbook multi_play_vars_files.yml

# Multiple plays with set_fact approach
ansible-playbook multi_play_example.yml

# Different environment
ansible-playbook multi_play_vars_files.yml -e "environment=development"
```

## Key Concepts Demonstrated

### 1. Global Variables in Playbook
The main playbook defines variables that all roles can access:
- `app_name`, `app_version`, `environment`
- Common paths: `base_install_dir`, `log_dir`, `config_dir`
- Network settings: `app_domain`, `enable_ssl`
- Feature flags: `enable_monitoring`, `enable_backups`

### 2. Role Defaults
Each role has `defaults/main.yml` with sensible defaults that can reference global vars:
```yaml
# In role defaults
webserver_config_file: "{{ config_dir | default('/etc/nginx') }}/webserver.conf"
```

### 3. Environment-Specific Configs
Different settings loaded based on `environment` variable:
- `vars/production.yml` - High resources, SSL enabled
- `vars/development.yml` - Low resources, debug enabled

### 4. Conditional Role Execution
Roles can be conditionally executed based on global flags:
```yaml
roles:
  - role: monitoring
    when: enable_monitoring | bool
```

### 5. Templates Use All Variables
Templates can access global, group, and role variables:
```jinja2
# In template
ServerName {{ app_domain }}
MemoryLimit {{ memory_limit }}
LogLevel {{ log_level }}
```

### 6. Multiple Plays in One Playbook
When you have multiple plays (named sections), each play has its own variable scope:

```yaml
# Each play is a separate section
- name: Play 1 - Infrastructure
  hosts: all
  vars_files:
    - vars/common.yml  # Load shared vars
  vars:
    play_specific: "infra"
  roles:
    - networking

- name: Play 2 - Application
  hosts: all
  vars_files:
    - vars/common.yml  # Load same shared vars
  vars:
    play_specific: "app"  # Different value for this play
  roles:
    - webserver
```

**Important:** Variables from Play 1 don't automatically flow to Play 2. Use `vars_files` in each play for consistency.

**See:** `MULTI-PLAY-GUIDE.md` for complete details and examples.

## Best Practices

### 1. **Use Descriptive Variable Names**
```yaml
# Good
app_base_install_directory: "/opt/myapp"

# Bad
dir: "/opt/myapp"
```

### 2. **Set Sensible Defaults in Roles**
Always provide defaults in `roles/*/defaults/main.yml`:
```yaml
webserver_port: 80  # Will be used if not overridden
```

### 3. **Document Variable Requirements**
Add comments explaining what each variable does and what overrides it.

### 4. **Use vars_files for Environment Configs**
Keep environment-specific configs in separate files:
```yaml
vars_files:
  - "vars/{{ environment }}.yml"
```

### 5. **Leverage group_vars for Infrastructure Patterns**
Use `group_vars` for settings that apply to groups of hosts:
```yaml
# group_vars/database_servers.yml
max_connections: 1000
```

### 6. **Provide Fallbacks with default() Filter**
Protect against undefined variables:
```yaml
log_file: "{{ log_dir | default('/var/log') }}/app.log"
```

### 7. **Use Feature Flags**
Control functionality with boolean flags:
```yaml
enable_monitoring: true
enable_backups: true
enable_ssl: false
```

## Common Patterns

### Pattern 1: Derived Variables
Create variables based on other global vars:
```yaml
vars:
  app_name: "myapp"
  base_install_dir: "/opt/{{ app_name }}"
  log_dir: "/var/log/{{ app_name }}"
```

### Pattern 2: Environment Switching
Load different configs based on environment:
```yaml
vars:
  environment: "production"
vars_files:
  - "vars/{{ environment }}.yml"
```

### Pattern 3: Conditional Blocks
Execute tasks based on global flags:
```yaml
- name: Setup SSL
  block:
    - name: Copy certificate
      copy: ...
  when: enable_ssl | bool
```

### Pattern 4: Role Variable Overrides
Override defaults per role:
```yaml
roles:
  - role: webserver
    vars:
      webserver_port: 8080
```

## Troubleshooting

### View all variables for a host:
```bash
ansible -i inventory.yml prod-server1 -m debug -a "var=hostvars[inventory_hostname]"
```

### Check variable precedence:
```bash
ansible-playbook -i inventory.yml main_playbook.yml -vvv | grep "variable"
```

### Print specific variable:
Add debug task:
```yaml
- debug:
    var: variable_name
```

## Advanced Examples

### Using set_fact for Computed Globals
```yaml
- name: Compute derived values
  set_fact:
    full_app_path: "{{ base_install_dir }}/{{ app_version }}"
    cacheable: yes  # Cache across plays
```

### Registering Variables Globally
```yaml
- name: Get system info
  command: uname -r
  register: kernel_version
  run_once: true
  delegate_to: localhost
```

### Include Variables Dynamically
```yaml
- name: Include extra vars
  include_vars:
    file: "{{ item }}"
  with_first_found:
    - "vars/{{ ansible_distribution }}.yml"
    - "vars/default.yml"
```

## Summary

This example demonstrates that Ansible provides multiple flexible ways to set global defaults:

1. **Playbook vars** - For core application settings
2. **vars_files** - For environment-specific configs
3. **group_vars** - For inventory-based defaults
4. **host_vars** - For host-specific overrides

All methods work together with well-defined precedence, allowing you to:
- Share configuration across multiple roles
- Override defaults at different levels
- Maintain DRY (Don't Repeat Yourself) principles
- Support multiple environments easily

Choose the method that best fits your use case, or combine multiple methods for maximum flexibility!

