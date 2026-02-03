# Setup Guide - Installing Required Modules

This guide shows how to install and update the Ansible collections needed for the ISO boot monitoring playbooks.

## Required Collections

These playbooks require:

| Collection | Purpose | Required For |
|------------|---------|--------------|
| `community.general` | Redfish API support | Module-based playbooks |
| `dellemc.openmanage` | Dell-specific features (optional) | Dell iDRAC advanced features |

## Quick Install

### Install Everything

```bash
# Install community.general (required)
ansible-galaxy collection install community.general

# Install Dell OpenManage (optional, for Dell-specific features)
ansible-galaxy collection install dellemc.openmanage
```

### Install Latest Versions

```bash
# Upgrade to latest versions
ansible-galaxy collection install community.general --upgrade
ansible-galaxy collection install dellemc.openmanage --upgrade
```

## Step-by-Step Installation

### 1. Check Current Ansible Version

```bash
ansible --version
```

**Expected output:**
```
ansible [core 2.15.0]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/user/.ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.11/site-packages/ansible
  python version = 3.11.2
```

**Minimum requirements:**
- Ansible 2.9+ (for basic features)
- Ansible 2.11+ (recommended)
- Python 3.6+

### 2. Check Installed Collections

```bash
# List all installed collections
ansible-galaxy collection list

# Check specific collection
ansible-galaxy collection list community.general
```

**Sample output if installed:**
```
# /home/user/.ansible/collections/ansible_collections
Collection        Version
----------------- -------
community.general 8.0.0
```

**If not installed, you'll see:**
```
# /home/user/.ansible/collections/ansible_collections
[WARNING]: - the configured path /home/user/.ansible/collections/ansible_collections does not exist.
```

### 3. Install Required Collections

#### Option A: Install Individually

```bash
# Install community.general (required)
ansible-galaxy collection install community.general

# Install specific version
ansible-galaxy collection install community.general:8.0.0
```

#### Option B: Install from Requirements File

Create a requirements file:

```bash
cat > requirements.yml <<EOF
---
collections:
  - name: community.general
    version: ">=8.0.0"
  
  - name: dellemc.openmanage
    version: ">=8.0.0"
EOF
```

Install from requirements:

```bash
ansible-galaxy collection install -r requirements.yml
```

#### Option C: Install to Custom Location

```bash
# Install to specific path
ansible-galaxy collection install community.general -p ./collections/

# Then specify path when running playbook
ansible-playbook -i inventory.yml simple_monitor_module.yml \
  -e ansible_collections_path=./collections
```

### 4. Verify Installation

#### Check Collection is Available

```bash
# List installed collections
ansible-galaxy collection list community.general
```

**Expected output:**
```
# /home/user/.ansible/collections/ansible_collections
Collection        Version
----------------- -------
community.general 8.0.0
```

#### Verify the Redfish Module

```bash
# Check module documentation
ansible-doc community.general.redfish_info
```

**If working, you'll see:**
```
> COMMUNITY.GENERAL.REDFISH_INFO    (/path/to/ansible_collections/community/general/plugins/modules/redfish_info.py)

        Builds Redfish URIs locally and sends them to remote OOB
        controllers to get information back.
```

**If not working:**
```
[WARNING]: module community.general.redfish_info not found
```

#### Test with a Simple Playbook

Create a test playbook:

```bash
cat > test_modules.yml <<EOF
---
- name: Test Redfish Module Installation
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Test community.general.redfish_info module exists
      ansible.builtin.debug:
        msg: "Module test - will try to import redfish_info"
    
    - name: Check module documentation
      ansible.builtin.command:
        cmd: ansible-doc community.general.redfish_info
      register: module_check
      changed_when: false
      failed_when: "'not found' in module_check.stderr"
    
    - name: Display success
      ansible.builtin.debug:
        msg: "✅ community.general.redfish_info module is installed and available"
EOF
```

Run the test:

```bash
ansible-playbook test_modules.yml
```

## Troubleshooting

### Issue 1: "Module not found" Error

**Error message:**
```
ERROR! couldn't resolve module/action 'community.general.redfish_info'
```

**Solutions:**

1. **Install the collection:**
   ```bash
   ansible-galaxy collection install community.general
   ```

2. **Check collection path:**
   ```bash
   ansible-config dump | grep COLLECTIONS_PATHS
   ```
   
   Should show:
   ```
   COLLECTIONS_PATHS(default) = ['/home/user/.ansible/collections', '/usr/share/ansible/collections']
   ```

3. **Verify installation location:**
   ```bash
   ls -la ~/.ansible/collections/ansible_collections/community/general/
   ```

4. **Install to specific path:**
   ```bash
   ansible-galaxy collection install community.general -p ~/.ansible/collections
   ```

### Issue 2: Permission Denied During Installation

**Error message:**
```
ERROR! Unable to write to /usr/share/ansible/collections/ansible_collections
```

**Solutions:**

1. **Install to user directory (recommended):**
   ```bash
   ansible-galaxy collection install community.general
   ```
   (Installs to `~/.ansible/collections` by default)

2. **Use sudo for system-wide installation:**
   ```bash
   sudo ansible-galaxy collection install community.general
   ```

3. **Specify user path explicitly:**
   ```bash
   ansible-galaxy collection install community.general -p ~/.ansible/collections
   ```

### Issue 3: Old Version Installed

**Check version:**
```bash
ansible-galaxy collection list community.general
```

**Upgrade to latest:**
```bash
ansible-galaxy collection install community.general --upgrade --force
```

**Install specific version:**
```bash
ansible-galaxy collection install community.general:8.0.0 --force
```

### Issue 4: Multiple Installation Paths

**Problem:** Collection installed in multiple locations, causing confusion.

**Solution:** Check all paths and remove duplicates:

```bash
# Find all installations
find ~ -path "*/ansible_collections/community/general" -type d 2>/dev/null
find /usr/share -path "*/ansible_collections/community/general" -type d 2>/dev/null

# Check which one Ansible uses
ansible-galaxy collection list community.general

# Remove old/duplicate installations
rm -rf ~/.local/share/ansible/collections/ansible_collections/community/general
```

### Issue 5: Behind Corporate Proxy

**Set proxy environment variables:**
```bash
export http_proxy="http://proxy.company.com:8080"
export https_proxy="http://proxy.company.com:8080"
export no_proxy="localhost,127.0.0.1"

# Then install
ansible-galaxy collection install community.general
```

**Or configure in ansible.cfg:**
```ini
[galaxy]
server_list = galaxy

[galaxy_server.galaxy]
url = https://galaxy.ansible.com
```

### Issue 6: Offline Installation

**On a machine with internet:**
```bash
# Download collection
ansible-galaxy collection download community.general
# This creates: community-general-8.0.0.tar.gz
```

**On offline machine:**
```bash
# Copy the .tar.gz file to offline machine, then:
ansible-galaxy collection install community-general-8.0.0.tar.gz
```

## Installation Locations

### Default Collection Paths

Ansible searches for collections in these locations (in order):

1. **User collections** (preferred):
   ```
   ~/.ansible/collections/ansible_collections/
   ```

2. **System collections**:
   ```
   /usr/share/ansible/collections/ansible_collections/
   ```

3. **Custom paths** (if specified in ansible.cfg):
   ```ini
   [defaults]
   collections_paths = ./collections:~/.ansible/collections:/usr/share/ansible/collections
   ```

### Verify Which Path Ansible Uses

```bash
# Show collection search paths
ansible-config dump | grep COLLECTIONS_PATHS

# Show where specific collection is installed
ansible-galaxy collection list community.general --format json | jq
```

## Testing Your Installation

### Quick Test Script

Create and run this test:

```bash
cat > test_redfish_module.yml <<'EOF'
---
- name: Test Redfish Module Installation
  hosts: localhost
  gather_facts: false
  
  tasks:
    - name: Test 1 - Check module is available
      ansible.builtin.command:
        cmd: ansible-doc -l community.general.redfish_info
      register: module_list
      changed_when: false
      failed_when: module_list.rc != 0
    
    - name: Test 2 - Display module info
      ansible.builtin.command:
        cmd: ansible-doc -s community.general.redfish_info
      register: module_doc
      changed_when: false
    
    - name: Test 3 - Try to use the module (will fail without real BMC)
      community.general.redfish_info:
        baseuri: "192.0.2.1"  # TEST-NET address, will fail
        username: "test"
        password: "test"
        validate_certs: false
        category: Systems
        command: GetSystemInfo
      register: test_result
      ignore_errors: true
    
    - name: Display results
      ansible.builtin.debug:
        msg:
          - "✅ Module is installed and importable"
          - "Module location: {{ module_doc.stdout_lines[0] | default('Unknown') }}"
          - "Test connection result: {{ 'Success' if not test_result.failed else 'Failed (expected without real BMC)' }}"
EOF

ansible-playbook test_redfish_module.yml
```

### Test with Your BMC

If you have a real BMC to test against:

```bash
# Test actual connection
ansible-playbook simple_monitor_module.yml \
  -i inventory.simple.yml \
  -e "iterations=1"
```

## Complete Setup Example

Here's a complete setup workflow:

```bash
# 1. Check Ansible version
ansible --version

# 2. Check current collections
ansible-galaxy collection list

# 3. Install required collections
ansible-galaxy collection install community.general

# 4. Verify installation
ansible-galaxy collection list community.general

# 5. Check module documentation
ansible-doc community.general.redfish_info | head -20

# 6. Navigate to examples
cd ~/gemini-workspace/ansible-examples/007_monitor_iso_boot

# 7. Create inventory
cp inventory.simple.yml inventory.yml
vi inventory.yml  # Edit with your BMC details

# 8. Test the setup
ansible-playbook -i inventory.yml simple_monitor_module.yml -e "iterations=2"

# 9. If successful, run full monitoring
ansible-playbook -i inventory.yml simple_monitor_module.yml
```

## Additional Collections (Optional)

### Dell OpenManage Collection

For Dell-specific advanced features:

```bash
# Install
ansible-galaxy collection install dellemc.openmanage

# Verify
ansible-galaxy collection list dellemc.openmanage

# Check modules
ansible-doc dellemc.openmanage.idrac_virtual_media
```

### HPE iLO Collection

For HPE-specific features:

```bash
# Install
ansible-galaxy collection install hpe.ilo

# Verify
ansible-galaxy collection list hpe.ilo
```

## Requirements File for Production

Create a `requirements.yml` for your project:

```yaml
---
collections:
  # Required for Redfish monitoring
  - name: community.general
    version: ">=8.0.0"
  
  # Optional: Dell-specific features
  - name: dellemc.openmanage
    version: ">=8.0.0"
    
  # Optional: HPE-specific features  
  - name: hpe.ilo
    version: ">=1.0.0"
```

Install all at once:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Keeping Collections Updated

### Check for Updates

```bash
# List installed with versions
ansible-galaxy collection list

# Check for newer versions on Galaxy
ansible-galaxy collection list community.general --format json
```

### Update Regularly

```bash
# Update specific collection
ansible-galaxy collection install community.general --upgrade

# Update all from requirements file
ansible-galaxy collection install -r requirements.yml --upgrade --force
```

### Automated Update Script

```bash
#!/bin/bash
# update_collections.sh

echo "Updating Ansible collections..."

ansible-galaxy collection install community.general --upgrade
ansible-galaxy collection install dellemc.openmanage --upgrade

echo "Current versions:"
ansible-galaxy collection list | grep -E "community.general|dellemc.openmanage"

echo "✅ Collections updated"
```

## See Also

- [Ansible Galaxy](https://galaxy.ansible.com/)
- [Community.General Collection](https://galaxy.ansible.com/community/general)
- [Dell OpenManage Collection](https://galaxy.ansible.com/dellemc/openmanage)
- [Main README](README.md)

