# Ansible Automation Platform - Parallel Execution via Bastion

**This guide is specifically for users running Ansible from AAP (Ansible Automation Platform) through a bastion host.**

## Architecture You're Working With

```
┌─────────────────────────────────────────────────────┐
│  Your Environment                                    │
│                                                      │
│  ┌───────────────────────────────────────┐          │
│  │ Ansible Automation Platform           │          │
│  │ (Controller + Execution Environment)  │          │
│  │                                       │          │
│  │ • Playbook execution happens HERE     │          │
│  │ • Job Templates configured here       │          │
│  │ • Credentials stored here             │          │
│  │ • Forks setting controlled here       │          │
│  └─────────────────┬─────────────────────┘          │
│                    │                                 │
│                    │ SSH with ProxyJump              │
│                    ↓                                 │
│  ┌───────────────────────────────────────┐          │
│  │ Bastion Host / Jump Server            │          │
│  │                                       │          │
│  │ • Acts as SSH proxy ONLY              │          │
│  │ • No playbook execution               │          │
│  │ • Forwards SSH connections            │          │
│  └─────────────────┬─────────────────────┘          │
│                    │                                 │
│                    │ SSH to target nodes             │
│                    ↓                                 │
│  ┌───────────────────────────────────────┐          │
│  │ Target Nodes                          │          │
│  │ node1, node2, node3, ...              │          │
│  │                                       │          │
│  │ • Tasks execute HERE                  │          │
│  │ • Results returned to AAP             │          │
│  └───────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## Quick Start for AAP Users

### 1. Configure Credentials (AAP Web UI)

**Navigation:** Credentials → Add → Machine

**Settings:**
- **Name:** `SSH Key for Bastion and Targets`
- **Credential Type:** `Machine`
- **Username:** `admin` (or your target node username)
- **SSH Private Key:** Paste the private key that works for:
  - Authenticating to bastion (as bastion-user)
  - Bastion authenticating to targets (as admin)
- **Privilege Escalation Method:** `sudo` (if using `become`)

💡 **Note:** The same key must work for both bastion and target authentication, OR you need to configure SSH agent forwarding (advanced).

### 2. Configure Inventory

Your inventory needs ProxyJump configuration:

```yaml
# inventory.yml (in your Git repo)
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
        # This tells SSH to proxy through bastion
        ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
        
        # User for target nodes
        ansible_user: admin
        
        # If using become/sudo
        ansible_become: true
        ansible_become_method: sudo
```

**Import to AAP:**
- **Option A:** Inventories → Add → Source Control (point to Git)
- **Option B:** Inventories → Add → paste YAML directly

### 3. Create Project

**Navigation:** Projects → Add

- **Name:** `My Ansible Playbooks`
- **Source Control Type:** `Git`
- **Source Control URL:** Your Git repository
- **Branch:** `main` (or your branch)
- Click **Save** and **Sync**

### 4. Create Job Template (This is where parallelism is configured!)

**Navigation:** Templates → Add → Job Template

**Basic Settings:**
- **Name:** `Parallel Node Tasks`
- **Inventory:** Select your inventory (from step 2)
- **Project:** Select your project (from step 3)
- **Playbook:** `parallel_async.yml` (or your playbook)
- **Credentials:** Select your Machine credential (from step 1)

**Critical Settings for Parallelism:**
- **Forks:** `20` ⭐ This controls how many hosts run tasks simultaneously!
  - Default: 5
  - Recommended: 20-50
  - For 100+ hosts: 50-100

**Advanced Settings:**
- **Timeout:** `3600` (1 hour - increase for long tasks)
- **Enable Concurrent Jobs:** Check if you want to run multiple instances

### 5. Update Your Playbook

**Remove Serial Execution:**

```yaml
# ❌ Current (Serial - Slow)
- name: My tasks
  hosts: target_nodes
  serial: 1  # ← Remove this!
  tasks:
    - name: Task 1
      ...
```

```yaml
# ✅ Updated (Parallel - Fast)
- name: My tasks
  hosts: target_nodes
  # No serial setting = parallel execution!
  tasks:
    - name: Task 1
      ...
```

**For Long-Running Tasks, Use Async:**

```yaml
# ✅ Async for maximum parallelism
- name: My long-running tasks
  hosts: target_nodes
  
  tasks:
    # Start all tasks without waiting
    - name: Start task 1
      command: /long/running/command1
      async: 3600
      poll: 0
      register: job1
    
    - name: Start task 2
      command: /long/running/command2
      async: 3600
      poll: 0
      register: job2
    
    # Now wait for completion
    - name: Wait for task 1
      async_status:
        jid: "{{ job1.ansible_job_id }}"
      register: result1
      until: result1.finished
      retries: 360
      delay: 10
    
    - name: Wait for task 2
      async_status:
        jid: "{{ job2.ansible_job_id }}"
      register: result2
      until: result2.finished
      retries: 360
      delay: 10
```

### 6. Test and Launch

1. **Test Connectivity First:**
   - Create simple test playbook with `ping` module
   - Set **Limit:** `node1` in Job Template
   - Click **Launch**
   - Verify it works

2. **Test Parallelism:**
   - Remove the **Limit**
   - Set **Forks:** `10`
   - Launch and note the time
   
3. **Scale Up:**
   - Increase **Forks:** `20`
   - Launch again, should be faster!

## Files in This Directory

| File | Purpose | Start Here? |
|------|---------|-------------|
| **AAP-README.md** (this file) | Overview for AAP users | ✅ YES |
| **AAP-SETUP-GUIDE.md** | Detailed AAP configuration | If you need more detail |
| **EXECUTION-ENVIRONMENT.md** | EE-specific considerations | For troubleshooting |
| **QUICK-START.md** | Quick decision tree and templates | For fast implementation |
| **COMPARISON.md** | Performance comparison of methods | To understand trade-offs |
| **README.md** | General concepts (AAP-updated) | Background reading |
| inventory.yml | Example inventory with bastion | Copy and modify |
| parallel_async.yml | Async execution example | Use for long tasks |
| parallel_forks.yml | Simple fork-based parallelism | Use for quick tasks |
| serial_execution.yml | Your current approach (baseline) | For comparison |

## Common AAP Scenarios

### Scenario 1: "My tasks run serially, one node at a time"

**Problem:** You have `serial: 1` in your playbook, or forks is set to 1

**Solution:**
1. Remove `serial: 1` from playbook
2. In Job Template, set **Forks: 20**
3. Launch job

**Result:** 20x faster (up to 20 hosts)

---

### Scenario 2: "I have 100 nodes, want maximum speed"

**Solution:**
1. Remove `serial: 1` from playbook
2. In Job Template, set **Forks: 50** or **Forks: 100**
3. Consider **Job Slicing: 10** (splits into 10 parallel jobs)

**Result:** 50-100x faster depending on task duration

---

### Scenario 3: "Tasks take 30+ minutes each"

**Solution:**
1. Use `async` pattern in playbook (see examples)
2. Set **Forks: 20** in Job Template
3. Increase **Timeout: 7200** (2 hours)

**Result:** All tasks run simultaneously, completion time = longest single task

---

### Scenario 4: "Connection timeout to bastion"

**Problem:** Network or firewall blocking AAP → Bastion

**Solution:**
1. Verify AAP execution environment can reach bastion:
   - Test with simple ping playbook to bastion host
2. Check firewall rules:
   - AAP controller → bastion.example.com:22 must be allowed
3. Add timeout to inventory:
   ```yaml
   ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o ConnectTimeout=30'
   ```

---

### Scenario 5: "Permission denied through bastion"

**Problem:** SSH key doesn't work for bastion or targets

**Solution:**
1. Verify key in AAP Credential works manually:
   ```bash
   # From AAP controller (if you have access):
   ssh -i /path/to/key bastion-user@bastion.example.com
   ssh -i /path/to/key -J bastion-user@bastion.example.com admin@192.168.1.101
   ```
2. Check `~/.ssh/authorized_keys` on:
   - Bastion (for bastion-user)
   - Target nodes (for admin user)
3. Verify username in inventory matches actual username

## Performance Expectations

### Example: 5 nodes, 3 tasks, each task takes 1 minute

| Method | Forks Setting | Total Time | Speedup |
|--------|---------------|------------|---------|
| Serial (`serial: 1`) | N/A | 15 minutes | 1x (baseline) |
| Parallel (forks) | 5 | 3 minutes | 5x faster |
| Parallel (forks) | 20 | 3 minutes | 5x faster |
| Async | 20 | 1 minute | 15x faster! |

### Example: 50 nodes, 3 tasks, each task takes 5 minutes

| Method | Forks Setting | Total Time | Speedup |
|--------|---------------|------------|---------|
| Serial | N/A | 750 minutes (12.5 hrs) | 1x |
| Parallel | 10 | 75 minutes | 10x faster |
| Parallel | 50 | 15 minutes | 50x faster |
| Async | 50 | 5 minutes | 150x faster! |

## Troubleshooting

### "My Job Template doesn't have a Forks field"

- You might be using an older AAP version
- Try setting in `ansible.cfg` in your project:
  ```ini
  [defaults]
  forks = 20
  ```

### "Execution environment can't reach bastion"

1. Check network path: Controller → Bastion
2. Verify firewall rules
3. Test from controller: `curl -v telnet://bastion.example.com:22`

### "Too many authentication failures"

Add to inventory:
```yaml
ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o IdentitiesOnly=yes'
```

### "Tasks are slow even with high forks"

- Tasks might have dependencies (can't parallelize)
- Check network bandwidth: AAP → Bastion → Targets
- Check bastion load: Too many connections?
- Consider using async for long tasks

### "Job fails with timeout"

1. Increase **Timeout** in Job Template
2. For async tasks, increase `async:` value in playbook:
   ```yaml
   async: 7200  # 2 hours
   ```

## Next Steps

1. ✅ Read this file (you're doing it!)
2. ✅ Set up credentials in AAP
3. ✅ Configure inventory with ProxyJump
4. ✅ Create Job Template with Forks: 20
5. ✅ Test with one node first
6. ✅ Scale up gradually
7. ✅ Implement async for long tasks
8. 📚 Read AAP-SETUP-GUIDE.md for detailed walkthrough
9. 📚 Read EXECUTION-ENVIRONMENT.md for EE troubleshooting

## Additional Resources

- **AAP Documentation:** https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/
- **Ansible ProxyJump:** https://docs.ansible.com/ansible/latest/user_guide/connection_details.html
- **Async Tasks:** https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html

## Questions?

- Check **AAP-SETUP-GUIDE.md** for step-by-step configuration
- Check **EXECUTION-ENVIRONMENT.md** for EE-specific issues
- Review example playbooks in this directory
- Test with the provided `test_connectivity.yml` playbook

