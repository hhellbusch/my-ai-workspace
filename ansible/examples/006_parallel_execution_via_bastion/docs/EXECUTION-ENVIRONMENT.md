# Execution Environment Considerations for AAP

When running Ansible playbooks from an Execution Environment (EE) on Ansible Automation Platform through a bastion host, there are specific considerations.

## What is an Execution Environment?

An Execution Environment is a container image that contains:
- Ansible (ansible-core)
- Python dependencies
- System packages
- Collections

**Key Point:** The EE runs on the AAP Controller, NOT on the bastion host. The bastion is only used as an SSH jump host.

## SSH Configuration in Execution Environments

### 1. SSH Client Requirements

Your execution environment must have:
- **OpenSSH client** 7.3+ (for ProxyJump support)
- **SSH agent** (optional, for key management)

Most modern EEs include this by default. To verify:

```dockerfile
# In your execution-environment.yml (if building custom EE)
dependencies:
  system:
    - openssh-clients
```

### 2. SSH Key Management

#### Option A: AAP Machine Credentials (Recommended)
AAP injects SSH keys into the execution environment at runtime:

```yaml
# inventory.yml - No key paths needed
all:
  children:
    target_nodes:
      vars:
        ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com'
        ansible_user: admin
```

AAP handles the key automatically based on the Machine Credential attached to the Job Template.

#### Option B: Custom Key Paths (Advanced)
If you need specific key files:

```yaml
# This assumes keys are mounted into the EE
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o IdentityFile=/path/to/key'
```

### 3. SSH Known Hosts

In containerized environments, you typically disable host key checking:

```yaml
# In inventory or ansible.cfg
ansible_ssh_common_args: >-
  -o ProxyJump=bastion-user@bastion.example.com
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
```

**Security Note:** In production, consider:
- Pre-populating known_hosts in custom EE
- Using HashKnownHosts
- Managing host keys through AAP

## Network Connectivity Requirements

### Required Network Paths

```
┌─────────────────────────┐
│ Execution Environment   │
│ (on AAP Controller)     │
└───────────┬─────────────┘
            │
            │ Must be able to reach:
            │ - bastion.example.com:22
            ↓
┌─────────────────────────┐
│ Bastion Host            │
└───────────┬─────────────┘
            │
            │ Must be able to reach:
            │ - 192.168.1.101:22 (node1)
            │ - 192.168.1.102:22 (node2)
            │ - etc.
            ↓
┌─────────────────────────┐
│ Target Nodes            │
└─────────────────────────┘
```

### Firewall Rules Needed

1. **AAP Controller → Bastion**
   - Port: 22 (SSH)
   - Protocol: TCP
   
2. **Bastion → Target Nodes**
   - Port: 22 (SSH)
   - Protocol: TCP

3. **No direct access needed:** EE → Target Nodes (goes through bastion)

## Parallelism Considerations in EE

### 1. Container Resource Limits

Each EE container has resource limits. High fork counts can hit these limits:

```yaml
# Check EE resources in AAP
# Settings → Jobs → Default execution environment
# 
# Typical limits:
# - Memory: 1-2 GB per EE instance
# - CPU: 1-2 cores per EE instance
```

**Recommendation:** For high parallelism (forks > 50), consider:
- Increasing EE resource limits
- Using Job Slicing to distribute across multiple EE instances
- Using Instance Groups for load distribution

### 2. SSH Connection Pooling

Enable SSH ControlMaster to reuse connections:

```ini
# ansible.cfg in your project
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o ControlPath=/tmp/ansible-ssh-%h-%p-%r
pipelining = True
```

**Important:** `/tmp` in the EE is ephemeral. This is fine for connection pooling during a single job run.

### 3. Temporary File Storage

Async jobs create temporary files in the EE:

```yaml
# Default location: /tmp in the EE container
# Files cleaned up when job completes

# If needed, specify custom temp directory
environment:
  ANSIBLE_REMOTE_TMP: /tmp/ansible-remote
```

## Building Custom Execution Environments

If you need custom SSH configurations or tools:

### execution-environment.yml
```yaml
---
version: 3

images:
  base_image:
    name: quay.io/ansible/creator-base:v0.1.0

dependencies:
  galaxy: requirements.yml
  python: requirements.txt
  system: bindep.txt

additional_build_steps:
  append_final:
    - RUN mkdir -p /etc/ssh && \
      echo "Host *" >> /etc/ssh/ssh_config && \
      echo "  ServerAliveInterval 60" >> /etc/ssh/ssh_config && \
      echo "  ServerAliveCountMax 3" >> /etc/ssh/ssh_config
```

### bindep.txt (system packages)
```
openssh-clients [platform:rpm]
openssh-client [platform:dpkg]
```

### Build and push:
```bash
ansible-builder build -t my-custom-ee:latest
podman push my-custom-ee:latest quay.io/myorg/my-custom-ee:latest
```

### Use in AAP:
**Settings → Execution Environments → Add**
- Name: My Custom EE
- Image: quay.io/myorg/my-custom-ee:latest

## Common Issues and Solutions

### Issue: "Connection timed out" to bastion

**Cause:** EE cannot reach bastion (network/firewall issue)

**Debug:**
```yaml
# Add to a debug playbook
- name: Test bastion connectivity
  hosts: localhost
  tasks:
    - name: Try to connect to bastion
      command: ssh -v bastion-user@bastion.example.com echo "Connected"
      delegate_to: localhost
```

**Fix:** Verify network path from AAP controller to bastion

---

### Issue: "Too many authentication failures"

**Cause:** SSH trying multiple keys before the right one

**Fix:**
```yaml
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o IdentitiesOnly=yes'
```

---

### Issue: "Permission denied (publickey)"

**Cause:** SSH key in AAP credential doesn't work for bastion or targets

**Debug:**
1. Check AAP Machine Credential has correct key
2. Test key manually: `ssh -i /path/to/key bastion-user@bastion.example.com`
3. Check authorized_keys on bastion and target nodes

---

### Issue: "Resource limits exceeded" with high forks

**Cause:** EE container hitting memory/CPU limits

**Fix:**
- Reduce forks in Job Template (e.g., 50 → 20)
- Enable Job Slicing to distribute across multiple EEs
- Increase EE resource limits in AAP settings

---

### Issue: "Async jobs not completing"

**Cause:** Async timeout too short or network issues

**Fix:**
```yaml
# Increase async timeout
async: 7200  # 2 hours instead of 1
poll: 0

# Increase retries and delay
- async_status:
    jid: "{{ job.ansible_job_id }}"
  register: result
  until: result.finished
  retries: 720  # 2 hours worth
  delay: 10
```

## Testing Your EE Configuration

### 1. Basic Connectivity Test

```yaml
# test_ee_bastion.yml
---
- name: Test EE to bastion to targets
  hosts: target_nodes
  gather_facts: false
  serial: 1  # Test one at a time
  
  tasks:
    - name: Test ping
      ping:
      
    - name: Show connection info
      debug:
        msg: |
          Successfully connected to {{ inventory_hostname }}
          via bastion from execution environment
```

### 2. Parallelism Test

```yaml
# test_parallel.yml
---
- name: Test parallel execution
  hosts: target_nodes
  gather_facts: false
  
  tasks:
    - name: Record start time
      set_fact:
        start_time: "{{ ansible_date_time.epoch }}"
      
    - name: Simulate work
      command: sleep 5
      
    - name: Record end time
      set_fact:
        end_time: "{{ ansible_date_time.epoch }}"
        
    - name: Show timing
      debug:
        msg: "Completed {{ inventory_hostname }} in {{ end_time|int - start_time|int }} seconds"
```

Run with different fork settings to test parallelism:
```bash
# From AAP Job Template, set Forks to:
# - 1 (should take 5 seconds × number of hosts)
# - 10 (should take ~5 seconds total for up to 10 hosts)
# - 50 (should take ~5 seconds total for up to 50 hosts)
```

### 3. Async Test

```yaml
# test_async.yml
---
- name: Test async execution
  hosts: target_nodes
  gather_facts: false
  
  tasks:
    - name: Start async sleep
      command: sleep 10
      async: 60
      poll: 0
      register: async_job
      
    - name: Do other work while waiting
      debug:
        msg: "Other tasks can run while async job runs"
        
    - name: Wait for async job
      async_status:
        jid: "{{ async_job.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 30
      delay: 2
      
    - name: Report success
      debug:
        msg: "Async job completed on {{ inventory_hostname }}"
```

## Best Practices for EE with Bastion

1. ✅ **Use AAP Machine Credentials** - Don't hardcode keys
2. ✅ **Disable host key checking** - In containerized environments
3. ✅ **Enable SSH connection pooling** - Reuse connections
4. ✅ **Set appropriate timeouts** - For slow networks or long tasks
5. ✅ **Test with small host counts first** - Before scaling up forks
6. ✅ **Monitor EE resources** - Watch for memory/CPU limits
7. ✅ **Use Job Slicing for large inventories** - Distribute load
8. ⚠️ **Don't set forks too high** - Respect EE resource limits
9. ⚠️ **Consider bastion load** - Too many parallel connections can overwhelm it

## Monitoring and Debugging

### View EE Logs in AAP

**Jobs → Your Job → Output**
- Shows real-time ansible-playbook output
- Includes SSH connection details with `-vvv`

### Enable Verbose SSH Output

In Job Template, add to **Extra Variables**:
```yaml
ansible_verbosity: 3
```

Or in playbook:
```yaml
- hosts: target_nodes
  tasks:
    - name: Debug connection
      ping:
      environment:
        ANSIBLE_DEBUG: 1
```

### Check EE Resource Usage

From AAP API or UI:
```bash
# Check job execution details
GET /api/v2/jobs/<job_id>/
# Look for:
# - execution_node (which controller ran it)
# - forks (parallelism setting)
# - elapsed (total runtime)
```

## Summary

- **EE runs on AAP Controller**, not bastion
- **Bastion is just an SSH proxy** - ProxyJump handles this
- **AAP manages SSH keys** - Use Machine Credentials
- **Network must allow**: EE → Bastion → Targets
- **Parallelism limited by**: EE resources, network bandwidth, bastion capacity
- **Use Job Slicing** for 500+ hosts
- **Test incrementally** - Start with low forks, increase gradually

