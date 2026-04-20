# Inventory Guide for ISO Boot Monitoring

This guide explains how to use inventory files with the ISO boot monitoring playbooks.

## Quick Start

### 1. Create Your Inventory

```bash
# Copy the example
cp inventory.example.yml inventory.yml

# Edit with your BMC details
vi inventory.yml

# Update these values:
# - idrac_ip: Your BMC IP address
# - idrac_user: Your BMC username
# - idrac_password: Your BMC password
```

### 2. Run with Inventory

```bash
# Simple monitoring
ansible-playbook -i inventory.yml simple_monitor_module.yml

# Advanced monitoring
ansible-playbook -i inventory.yml monitor_with_module.yml

# Wait for condition
ansible-playbook -i inventory.yml wait_for_condition_module.yml
```

## Inventory Files Provided

| File | Purpose | Use Case |
|------|---------|----------|
| `inventory.example.yml` | Full example with multiple servers | Copy and customize |
| `inventory.simple.yml` | Single server | Quick testing |
| `inventory.multi-server.yml` | Multiple servers/groups | Cluster deployments |
| `inventory.vault.yml` | Using Ansible Vault | Production/secure credentials |

## Common Patterns

### Pattern 1: Single Server Monitoring

**File: `inventory.simple.yml`**

```yaml
all:
  hosts:
    localhost:
      idrac_ip: "192.168.1.100"
      idrac_user: "root"
      idrac_password: "calvin"
      iterations: 30
      interval: 10
```

**Usage:**
```bash
ansible-playbook -i inventory.simple.yml simple_monitor_module.yml
```

### Pattern 2: Multiple Servers with Shared Credentials

```yaml
all:
  children:
    my_cluster:
      hosts:
        master-0:
          idrac_ip: "192.168.100.10"
        master-1:
          idrac_ip: "192.168.100.11"
        master-2:
          idrac_ip: "192.168.100.12"
      
      vars:
        idrac_user: "root"
        idrac_password: "SharedPassword"
        max_iterations: 120
        poll_interval: 15
```

### Pattern 3: Different Credentials Per Server

```yaml
all:
  hosts:
    server1:
      idrac_ip: "192.168.1.100"
      idrac_user: "root"
      idrac_password: "Pass1"
      
    server2:
      idrac_ip: "192.168.1.101"
      idrac_user: "admin"
      idrac_password: "Pass2"
```

### Pattern 4: With Ansible Vault (Secure)

**Step 1: Create vault file**
```bash
mkdir -p group_vars/all
ansible-vault create group_vars/all/vault.yml
```

**Step 2: Add encrypted variables**
```yaml
# In vault.yml (encrypted)
vault_idrac_user: root
vault_idrac_password: YourSecurePassword123
```

**Step 3: Reference in inventory**
```yaml
all:
  hosts:
    server1:
      idrac_ip: "192.168.1.100"
      idrac_user: "{{ vault_idrac_user }}"
      idrac_password: "{{ vault_idrac_password }}"
```

**Step 4: Run with vault**
```bash
ansible-playbook -i inventory.yml simple_monitor_module.yml --ask-vault-pass
```

## Variable Precedence

Variables can be defined at different levels (highest to lowest precedence):

1. **Command line** (`-e` extra vars)
2. **Host vars** (in inventory under host)
3. **Group vars** (in inventory under group vars)
4. **Playbook defaults** (in playbook `vars:` section)

### Example

```yaml
all:
  children:
    servers:
      hosts:
        server1:
          idrac_ip: "192.168.1.100"
          iterations: 10  # Host-specific: 10 iterations
        
        server2:
          idrac_ip: "192.168.1.101"
          # Will use group default: 60 iterations
      
      vars:
        idrac_user: "root"
        idrac_password: "calvin"
        iterations: 60  # Group default
        interval: 10
```

Override at runtime:
```bash
# Override for all hosts
ansible-playbook -i inventory.yml simple_monitor_module.yml -e "iterations=100"
```

## Available Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `idrac_ip` | BMC IP address | `"192.168.1.100"` |
| `idrac_user` | BMC username | `"root"` |
| `idrac_password` | BMC password | `"calvin"` |

### Optional Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `iterations` | Number of polls | `60` | `120` |
| `interval` | Seconds between polls | `10` | `15` |
| `max_iterations` | Same as iterations | `120` | `180` |
| `poll_interval` | Same as interval | `15` | `20` |
| `validate_certs` | Verify SSL certs | `false` | `true` |
| `media_device_id` | Virtual media device | `"CD"` | `"RemovableDisk"` |
| `expected_server_ip` | IP after installation | - | `"192.168.1.50"` |
| `iso_url` | ISO image URL | - | `"http://mirror/rhcos.iso"` |
| `wait_condition` | Condition to wait for | `"power_on"` | `"installation_complete"` |
| `max_wait_time` | Max wait seconds | `1800` | `3600` |

## Limiting Execution

### Run on Specific Hosts

```bash
# Only monitor server1
ansible-playbook -i inventory.yml simple_monitor_module.yml --limit server1

# Only monitor master nodes
ansible-playbook -i inventory.yml monitor_with_module.yml --limit ocp_masters

# Multiple specific hosts
ansible-playbook -i inventory.yml simple_monitor_module.yml --limit "master-0,master-1"
```

### Run on Specific Groups

```bash
# Only Dell servers
ansible-playbook -i inventory.multi-server.yml monitor_with_module.yml --limit dell_servers

# Only production
ansible-playbook -i inventory.yml simple_monitor_module.yml --limit production_servers
```

## Security Best Practices

### 1. Never Commit Credentials

```bash
# Add to .gitignore
echo "inventory.yml" >> .gitignore
echo "inventory.local.yml" >> .gitignore
echo ".vault_pass" >> .gitignore
```

### 2. Use Ansible Vault

```bash
# Encrypt existing file
ansible-vault encrypt inventory.yml

# Edit encrypted file
ansible-vault edit inventory.yml

# Run with vault
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass
```

### 3. Use Vault Password File

```bash
# Create password file (never commit this!)
echo "MyVaultPassword" > .vault_pass
chmod 600 .vault_pass

# Run with password file
ansible-playbook -i inventory.yml playbook.yml --vault-password-file .vault_pass
```

### 4. Use Environment Variables

```bash
# Set credentials via environment
export IDRAC_USER="root"
export IDRAC_PASSWORD="SecurePass"

# Reference in inventory
idrac_user: "{{ lookup('env', 'IDRAC_USER') }}"
idrac_password: "{{ lookup('env', 'IDRAC_PASSWORD') }}"
```

## Testing Your Inventory

### Verify Inventory Parsing

```bash
# List all hosts
ansible-inventory -i inventory.yml --list

# Show specific host variables
ansible-inventory -i inventory.yml --host server1

# Graph the inventory
ansible-inventory -i inventory.yml --graph
```

### Test Connectivity

```bash
# Ping all hosts (local connection test)
ansible -i inventory.yml all -m ping

# Show gathered facts
ansible -i inventory.yml all -m setup
```

### Dry Run

```bash
# Check syntax without running
ansible-playbook -i inventory.yml simple_monitor_module.yml --syntax-check

# Check what would run
ansible-playbook -i inventory.yml simple_monitor_module.yml --check
```

## Real-World Examples

### Example 1: OpenShift Cluster Installation

```yaml
all:
  children:
    ocp_cluster:
      children:
        masters:
          hosts:
            master-0:
              idrac_ip: "10.0.1.10"
              expected_server_ip: "10.0.2.10"
            master-1:
              idrac_ip: "10.0.1.11"
              expected_server_ip: "10.0.2.11"
            master-2:
              idrac_ip: "10.0.1.12"
              expected_server_ip: "10.0.2.12"
        
        workers:
          hosts:
            worker-0:
              idrac_ip: "10.0.1.20"
              expected_server_ip: "10.0.2.20"
            worker-1:
              idrac_ip: "10.0.1.21"
              expected_server_ip: "10.0.2.21"
      
      vars:
        idrac_user: "{{ vault_bmc_user }}"
        idrac_password: "{{ vault_bmc_password }}"
        iso_url: "http://mirror.local/rhcos-4.14.iso"
        max_iterations: 120
        poll_interval: 15
```

**Usage:**
```bash
# Monitor all nodes
ansible-playbook -i inventory.yml monitor_with_module.yml --ask-vault-pass

# Monitor only masters
ansible-playbook -i inventory.yml monitor_with_module.yml --limit masters --ask-vault-pass
```

### Example 2: Parallel Monitoring

Monitor multiple servers simultaneously:

```bash
# Set high fork count for parallel execution
ansible-playbook -i inventory.multi-server.yml \
  simple_monitor_module.yml \
  --forks 10

# Or set in ansible.cfg:
# [defaults]
# forks = 10
```

### Example 3: Dynamic Inventory

For cloud or dynamically provisioned BMCs:

```python
#!/usr/bin/env python3
# inventory.py - dynamic inventory script

import json

inventory = {
    "all": {
        "hosts": ["bmc1", "bmc2"],
        "vars": {
            "idrac_user": "root",
            "ansible_connection": "local"
        }
    },
    "_meta": {
        "hostvars": {
            "bmc1": {
                "idrac_ip": "192.168.1.100",
                "idrac_password": "pass1"
            },
            "bmc2": {
                "idrac_ip": "192.168.1.101",
                "idrac_password": "pass2"
            }
        }
    }
}

print(json.dumps(inventory, indent=2))
```

**Usage:**
```bash
chmod +x inventory.py
ansible-playbook -i inventory.py simple_monitor_module.yml
```

## Troubleshooting

### Issue: Variables Not Found

**Problem:** Playbook says `idrac_ip is not defined`

**Solution:** Check variable precedence and spelling
```bash
# Verify variables are set
ansible-inventory -i inventory.yml --host server1

# Should show:
# {
#   "idrac_ip": "192.168.1.100",
#   ...
# }
```

### Issue: Wrong Credentials

**Problem:** Authentication failures

**Solution:** Test credentials directly
```bash
# Test with curl
curl -k -u root:calvin https://192.168.1.100/redfish/v1/

# Verify in inventory
ansible-inventory -i inventory.yml --host server1 | grep -E "user|password"
```

### Issue: Vault Errors

**Problem:** `Vault password required`

**Solution:** Provide vault password
```bash
# Interactive
ansible-playbook -i inventory.yml playbook.yml --ask-vault-pass

# Or via file
ansible-playbook -i inventory.yml playbook.yml --vault-password-file .vault_pass
```

## See Also

- [Ansible Inventory Documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Main README](README.md)

