# Bastion Node Setup for RHACM Automation

This guide helps set up bastion/jump hosts for RHACM cluster import automation.

## The Problem

When delegating Ansible tasks to a bastion node, you may encounter:

```
failed to import the required python library (kubernetes)
```

This happens because the `kubernetes.core` collection requires the Python `kubernetes` library on the node executing the task.

## Solutions

### Solution 1: Keep Delegation to localhost (Recommended)

**Best approach**: Don't delegate Kubernetes tasks to the bastion. Instead, use SSH proxy.

#### inventory/hosts.ini

```ini
[rhacm_hub]
hub-cluster kubeconfig_path=/path/to/hub-kubeconfig

[target_clusters]
prod-cluster-01 kubeconfig_path=/path/to/prod-cluster-01-kubeconfig

# Use SSH proxy for network access
[target_clusters:vars]
ansible_ssh_common_args='-o ProxyJump=bastion.example.com'
```

#### How it works:
- Kubernetes tasks run on your Ansible control node (localhost)
- SSH connections to target clusters tunnel through bastion
- No Python dependencies needed on bastion
- Cleaner separation of concerns

### Solution 2: Install Dependencies on Bastion

If you must delegate to bastion, install required libraries:

#### Manual Installation

```bash
# SSH to bastion
ssh bastion.example.com

# Install pip3
sudo dnf install python3-pip -y  # RHEL/CentOS
# or
sudo apt install python3-pip -y  # Ubuntu/Debian

# Install kubernetes library
pip3 install kubernetes

# Verify
python3 -c "import kubernetes; print(kubernetes.__version__)"
```

#### Automated Installation with Playbook

```bash
# Add bastion to inventory
cat >> inventory/hosts.ini <<EOF

[bastion]
bastion.example.com ansible_user=admin
EOF

# Run setup playbook
ansible-playbook -i inventory/hosts.ini bastion-setup.yml
```

### Solution 3: Use Container/Podman on Bastion

Run Ansible in a container with all dependencies:

```bash
# On bastion
podman run -it --rm \
  -v /path/to/kubeconfigs:/kubeconfigs:Z \
  -v /path/to/playbooks:/playbooks:Z \
  quay.io/ansible/ansible-runner:latest \
  ansible-playbook -i /playbooks/inventory/hosts.ini /playbooks/import-cluster.yml
```

## Comparison

| Approach | Pros | Cons |
|----------|------|------|
| **SSH Proxy (localhost)** | ✅ No bastion dependencies<br>✅ Simpler setup<br>✅ Better security | ⚠️ Requires SSH access from control node |
| **Install on Bastion** | ✅ Direct execution<br>✅ Works in air-gapped | ❌ Dependency management<br>❌ Version conflicts |
| **Container on Bastion** | ✅ Isolated environment<br>✅ Consistent deps | ❌ More complex<br>❌ Requires container runtime |

## Recommended Configuration

### For Most Environments

Use SSH proxy with localhost delegation:

```yaml
# import-cluster.yml (no changes needed - already uses delegate_to: localhost)

# inventory/hosts.ini
[rhacm_hub]
hub-cluster kubeconfig_path=/path/to/hub-kubeconfig

[target_clusters]
prod-cluster-01 kubeconfig_path=/path/to/prod-cluster-01-kubeconfig

[target_clusters:vars]
ansible_ssh_common_args='-o ProxyJump=bastion.example.com'
```

### For Air-Gapped Environments

Install dependencies on bastion and modify delegation:

```yaml
# import-cluster.yml - modify delegation target
- name: Create ManagedCluster resource on hub
  kubernetes.core.k8s:
    # ... config ...
  delegate_to: "{{ bastion_host | default('localhost') }}"
```

```ini
# inventory/hosts.ini
[bastion]
bastion.example.com ansible_user=admin

[target_clusters:vars]
bastion_host=bastion.example.com
```

## Troubleshooting

### Check Python Installation

```bash
# On the node executing tasks (bastion or localhost)
python3 --version
pip3 list | grep kubernetes
python3 -c "import kubernetes; print(kubernetes.__version__)"
```

### Check Delegation Target

Add debug task to playbook:

```yaml
- name: Debug delegation
  debug:
    msg:
      - "Delegated to: {{ inventory_hostname }}"
      - "Python path: {{ ansible_python_interpreter | default('python3') }}"
  delegate_to: localhost  # or your bastion
```

### Test kubernetes.core Module

```bash
# Create test playbook
cat > test-k8s.yml <<EOF
---
- hosts: localhost
  tasks:
    - name: Test kubernetes module
      kubernetes.core.k8s_info:
        kind: Namespace
        name: default
      register: result
    - debug: var=result
EOF

# Run test
ansible-playbook test-k8s.yml
```

### Common Errors and Fixes

**Error:** `ModuleNotFoundError: No module named 'kubernetes'`
```bash
pip3 install kubernetes
```

**Error:** `No module named 'yaml'`
```bash
pip3 install PyYAML
```

**Error:** `requests package required`
```bash
pip3 install requests
```

**Error:** `cannot import name 'client' from 'kubernetes'`
```bash
# Version conflict - reinstall
pip3 uninstall kubernetes -y
pip3 install kubernetes
```

## Network Diagram

### SSH Proxy Approach (Recommended)
```
Ansible Control Node (localhost)
  ↓ (SSH via bastion)
Bastion Host (proxy only, no Python deps needed)
  ↓ (SSH tunnel)
Target Cluster API
```

### Bastion Delegation Approach
```
Ansible Control Node
  ↓ (SSH)
Bastion Host (Python + kubernetes library required)
  ↓ (Direct API call)
Hub/Target Cluster API
```

## Best Practices

1. **Use SSH proxy when possible** - Keeps dependencies on control node
2. **Document bastion requirements** - If delegation required
3. **Version pin dependencies** - In requirements.txt or ansible.cfg
4. **Test in non-prod first** - Verify connectivity and permissions
5. **Automate bastion setup** - Use bastion-setup.yml playbook

## Related Files

- [import-cluster.yml](import-cluster.yml) - Main playbook
- [bastion-setup.yml](bastion-setup.yml) - Bastion dependency installer
- [inventory/hosts.ini](inventory/hosts.ini) - Inventory configuration

---

**Last Updated**: February 19, 2026
