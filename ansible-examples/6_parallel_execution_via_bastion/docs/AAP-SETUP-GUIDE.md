# Ansible Automation Platform Setup Guide

This guide shows how to configure parallel execution through a bastion host when running on **Ansible Automation Platform (AAP)**.

## Architecture Overview

```
┌────────────────────────────────────────┐
│  Ansible Automation Platform           │
│  ┌──────────────────────────────────┐  │
│  │  Controller                       │  │
│  │  - Job scheduling                 │  │
│  │  - Credential management          │  │
│  │  - Inventory management           │  │
│  └──────────────┬───────────────────┘  │
│                 │                       │
│  ┌──────────────▼───────────────────┐  │
│  │  Execution Environment (EE)      │  │
│  │  - Runs Ansible playbooks        │  │
│  │  - Contains ansible-core         │  │
│  │  - Isolated container            │  │
│  └──────────────┬───────────────────┘  │
└─────────────────┼────────────────────────┘
                  │ SSH via ProxyJump
                  ▼
         ┌────────────────┐
         │  Bastion Host  │
         │  (Jump Server) │
         └────────┬───────┘
                  │ SSH
                  ▼
      ┌───────────────────────┐
      │  Target Nodes         │
      │  node1, node2, node3  │
      └───────────────────────┘
```

## Step-by-Step Configuration

### 1. Prepare Your Inventory

Create an inventory with bastion ProxyJump configuration:

```yaml
# inventory.yml
all:
  children:
    target_nodes:
      hosts:
        node1:
          ansible_host: 192.168.1.101
        node2:
          ansible_host: 192.168.1.102
        node3:
          ansible_host: 192.168.1.103
      vars:
        ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com'
        ansible_user: admin
        ansible_become: true
```

### 2. Configure SSH Credentials in AAP

#### Option A: Single SSH Key (Simplest)
If the same SSH key works for both bastion and target nodes:

**AAP Web UI → Credentials → Add**
- **Name:** `Bastion and Targets SSH Key`
- **Credential Type:** `Machine`
- **Username:** `admin` (user on target nodes)
- **SSH Private Key:** (paste your private key)
- **Privilege Escalation Method:** `sudo`
- **Privilege Escalation Username:** `root`

#### Option B: Different SSH Keys
If bastion and targets use different keys:

**Credential 1 - Bastion Key:**
- **Name:** `Bastion SSH Key`
- **Username:** `bastion-user`
- **SSH Private Key:** (bastion key)

**Credential 2 - Target Nodes Key:**
- **Name:** `Targets SSH Key`
- **Username:** `admin`
- **SSH Private Key:** (target nodes key)

Then modify inventory:
```yaml
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o IdentityFile=/path/to/bastion/key'
```

### 3. Create/Update Inventory in AAP

**AAP Web UI → Inventories → Add → Inventory**

1. **Name:** `Production Servers via Bastion`
2. **Organization:** Select your organization
3. Click **Save**

Then add the inventory source:

**Inventories → Your Inventory → Sources → Add**

- **Option A - SCM:** Point to Git repo with inventory.yml
- **Option B - Manual:** Go to Inventories → Hosts → Add hosts manually
- **Option C - Direct YAML:** Some AAP versions allow direct YAML paste

### 4. Create a Project

**AAP Web UI → Projects → Add**

- **Name:** `My Playbooks`
- **Source Control Type:** `Git`
- **Source Control URL:** `https://github.com/yourorg/yourrepo.git`
- **Branch:** `main`
- Click **Save**

### 5. Create Job Template with Parallelism

**AAP Web UI → Templates → Add → Job Template**

#### Basic Settings:
- **Name:** `Parallel Node Maintenance`
- **Inventory:** `Production Servers via Bastion`
- **Project:** `My Playbooks`
- **Playbook:** `parallel_async.yml` (or your playbook)
- **Credentials:** Add your Machine credential

#### Parallelism Settings (IMPORTANT):
- **Forks:** `20` (or higher - this controls parallelism!)
- **Job Slicing:** Leave empty (unless 1000+ hosts)
- **Timeout:** `3600` (1 hour - increase for long async tasks)

#### Advanced Options:
- Enable **Privilege Escalation** (if using become)
- Enable **Concurrent Jobs** if you want multiple instances running

### 6. Test Connectivity

Create a simple test playbook:

```yaml
# test_connectivity.yml
---
- name: Test bastion connectivity
  hosts: target_nodes
  gather_facts: false
  serial: 1  # Test one at a time first
  
  tasks:
    - name: Ping test
      ping:
      
    - name: Show host info
      debug:
        msg: "Successfully connected to {{ inventory_hostname }} via bastion"
```

Run this first to verify your bastion configuration works!

### 7. Run Your Parallel Playbook

Once connectivity is confirmed, switch to your parallel playbook:

```yaml
# parallel_maintenance.yml
---
- name: Parallel maintenance via bastion
  hosts: target_nodes
  gather_facts: false
  # No serial - will use forks from Job Template
  
  tasks:
    - name: Start system update
      yum:
        name: '*'
        state: latest
      async: 3600
      poll: 0
      register: update_job
      
    # ... rest of tasks
```

## AAP-Specific Parallelism Features

### 1. Forks (Primary Control)
Set in **Job Template → Forks** field
- Default: 5
- Recommended: 20-50 for most workloads
- Maximum: Limited by controller resources

### 2. Instance Groups
For very large deployments, use Instance Groups to distribute load:

**AAP Web UI → Instance Groups → Add**
- Assign different node groups to different execution nodes
- Each instance can run with its own fork setting

### 3. Job Slicing
For 1000+ hosts, use job slicing:

**Job Template → Job Slicing:** `10`
- Splits inventory into 10 slices
- Each slice runs as separate job
- Massive parallelism across controller

### 4. Concurrent Jobs
**Job Template → Options → Enable Concurrent Jobs**
- Allows same job template to run multiple times simultaneously
- Useful for different inventory groups

## Troubleshooting

### Issue: "Connection timeout" through bastion

**Check:**
```yaml
# Add to inventory vars:
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o ConnectTimeout=30 -o ServerAliveInterval=60'
```

### Issue: "Too many authentication failures"

**Fix:** Limit SSH key attempts:
```yaml
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o IdentitiesOnly=yes'
```

### Issue: "Permission denied" on bastion

**Check:**
1. Verify SSH key is correct in AAP Credential
2. Test manually from controller: `ssh bastion-user@bastion.example.com`
3. Check bastion's `~/.ssh/authorized_keys`

### Issue: "Can reach bastion but not targets"

**Check:**
1. Can bastion reach targets? `ssh admin@192.168.1.101` from bastion
2. Verify ansible_user is correct for targets
3. Check firewall rules: bastion → targets

### Issue: High memory usage on controller

**Fix:** Reduce forks or enable job slicing
```
# Job Template settings:
Forks: 10 (reduce from 50)
Job Slicing: 5 (split work across instances)
```

## Performance Tuning

### 1. SSH Connection Reuse

Enable ControlMaster for connection reuse:

```yaml
# In inventory vars or ansible.cfg in your project
ansible_ssh_common_args: >-
  -o ProxyJump=bastion-user@bastion.example.com
  -o ControlMaster=auto
  -o ControlPersist=300s
  -o ControlPath=/tmp/ansible-ssh-%h-%p-%r
```

### 2. Disable Unnecessary Fact Gathering

```yaml
- hosts: target_nodes
  gather_facts: false  # Saves time if facts not needed
```

### 3. Use Appropriate Forks

| Hosts | Recommended Forks |
|-------|------------------|
| 1-10 | 10 |
| 10-50 | 20 |
| 50-100 | 50 |
| 100-500 | 50-100 |
| 500+ | 100 + Job Slicing |

### 4. Async for Long Tasks

Always use async for tasks > 30 seconds:
```yaml
async: 3600
poll: 0
```

## Example Job Template Settings

### Conservative (Safe Start)
```
Forks: 10
Timeout: 1800 (30 min)
```

### Moderate (Good Balance)
```
Forks: 20
Timeout: 3600 (1 hour)
```

### Aggressive (Maximum Speed)
```
Forks: 50
Timeout: 7200 (2 hours)
Job Slicing: 10 (for 500+ hosts)
```

## Security Best Practices

1. **Use Vault for Sensitive Data:**
   ```yaml
   # In your playbook
   vars:
     db_password: !vault |
       $ANSIBLE_VAULT;1.1;AES256...
   ```

2. **Rotate SSH Keys Regularly:**
   - Update Machine Credentials in AAP
   - Don't hardcode keys in inventory

3. **Limit Bastion Access:**
   - Use firewall rules: Only AAP → Bastion
   - Use jump host account with limited privileges

4. **Enable Audit Logging:**
   - AAP logs all job executions
   - Review regularly for anomalies

## Next Steps

1. ✅ Set up credentials in AAP
2. ✅ Import inventory with bastion config
3. ✅ Create test job template with low forks
4. ✅ Test connectivity with simple ping playbook
5. ✅ Gradually increase forks
6. ✅ Implement async for long-running tasks
7. ✅ Monitor controller resources
8. ✅ Document your configuration for team

## Resources

- [AAP Documentation - Job Templates](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)
- [AAP Documentation - Credentials](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)
- [Ansible - ProxyJump Configuration](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html)

