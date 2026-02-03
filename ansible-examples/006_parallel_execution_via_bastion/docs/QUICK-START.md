# Quick Start Guide: Parallel Execution via Bastion (AAP)

**For Ansible Automation Platform users running from an Execution Environment**

## TL;DR - What Should I Use?

### 📊 Decision Tree

```
Do you need tasks to complete in order across all hosts?
├─ YES → Use serial execution (current approach)
└─ NO → Continue ↓

Are your tasks quick (<30 seconds each)?
├─ YES → Use parallel_forks.yml (easiest upgrade)
└─ NO → Continue ↓

Do you have multiple long-running tasks per host?
├─ YES → Use parallel_async.yml (maximum speed)
└─ NO → Use parallel_forks.yml
```

## 🚀 Fastest Migration Path (AAP)

### Step 0: Architecture Understanding

```
AAP Execution Environment (your playbook runs here)
  ↓ SSH with ProxyJump
Bastion (just a proxy)
  ↓ SSH
Target Nodes (tasks execute here)
```

### Step 1: Configure SSH Credentials in AAP

**AAP Web UI → Credentials → Add → Machine**
- **Name:** `Bastion SSH Key`
- **Username:** `admin` (for target nodes)
- **SSH Private Key:** (paste key that works for bastion → targets)

### Step 2: Update Your Inventory

Add bastion configuration to your inventory file:

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
      vars:
        # Key setting for bastion proxy
        ansible_ssh_common_args: '-o ProxyJump=bastion-user@bastion.example.com -o StrictHostKeyChecking=no'
        ansible_user: admin
```

Import this into AAP (**Inventories → Add → sync from SCM or paste YAML**)

### Step 3: Choose Your Parallelism Level

#### Option A: Quick Win (5 minutes to implement)
**Remove `serial: 1` from your playbook and increase forks in AAP**

```yaml
# Before:
- hosts: target_nodes
  serial: 1
  tasks: ...

# After:
- hosts: target_nodes
  # serial: 1  ← Remove this line!
  tasks: ...
```

**In AAP Job Template:**
- Set **Forks:** `20` (or higher)
- Attach your Machine Credential
- Attach your Inventory

**Result:** 5-10x faster for most workloads

---

#### Option B: Maximum Performance (30 minutes to implement)
**Use async for long-running tasks**

```yaml
# Start all tasks
- name: Long task 1
  command: /some/command
  async: 3600
  poll: 0
  register: job1

- name: Long task 2
  command: /another/command
  async: 3600
  poll: 0
  register: job2

# Wait for completion
- name: Wait for job1
  async_status:
    jid: "{{ job1.ansible_job_id }}"
  register: result1
  until: result1.finished
  retries: 360
  delay: 10
```

**Result:** 10-50x faster for long-running tasks

## 🔧 Configuration Files

### ansible.cfg (in your project/Git repo)
```ini
[defaults]
# Note: forks setting here is overridden by Job Template setting in AAP
host_key_checking = False
stdout_callback = yaml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

Place this in your project root (will be used by AAP)

### AAP Job Template Settings (This is where you control parallelism!)
- **Forks:** `20` (primary parallelism control)
- **Timeout:** `3600` (1 hour for long tasks)
- **Enable Concurrent Jobs:** Yes (if running against different groups)

## 📝 Copy-Paste Templates

### Template 1: Basic Parallel Playbook
```yaml
---
- name: Run tasks in parallel
  hosts: target_nodes
  gather_facts: false
  
  tasks:
    - name: Your task here
      command: your-command
```
**Create AAP Job Template:**
- Inventory: Your inventory with bastion config
- Credentials: Your Machine credential
- Forks: 20
- Then click **Launch**

---

### Template 2: Async Parallel Playbook
```yaml
---
- name: Run long tasks in parallel
  hosts: target_nodes
  gather_facts: false
  
  tasks:
    - name: Start long task
      command: your-long-command
      async: 3600
      poll: 0
      register: job
      
    - name: Wait for completion
      async_status:
        jid: "{{ job.ansible_job_id }}"
      register: result
      until: result.finished
      retries: 360
      delay: 10
```

---

### Template 3: Mixed Quick and Long Tasks
```yaml
---
- name: Mixed workload
  hosts: target_nodes
  
  tasks:
    # Quick tasks (use default parallelism)
    - name: Health check
      command: systemctl is-system-running
      
    # Long tasks (use async)
    - name: Start system update
      yum:
        name: '*'
        state: latest
      async: 3600
      poll: 0
      register: update_job
      
    - name: Start log cleanup
      command: logrotate -f /etc/logrotate.conf
      async: 3600
      poll: 0
      register: logrotate_job
    
    # Wait for long tasks
    - name: Wait for updates
      async_status:
        jid: "{{ update_job.ansible_job_id }}"
      register: update_result
      until: update_result.finished
      retries: 360
      delay: 10
      
    - name: Wait for log cleanup
      async_status:
        jid: "{{ logrotate_job.ansible_job_id }}"
      register: logrotate_result
      until: logrotate_result.finished
      retries: 360
      delay: 10
```

## 🎯 Common Scenarios

### Scenario 1: System Updates on 50 Servers
**Current:** 50 servers × 10 minutes = 500 minutes (8+ hours)  
**With forks=20:** 3 batches × 10 minutes = 30 minutes  
**With async:** 10 minutes (all at once)

**Use:** `parallel_async.yml` or `parallel_async_real_world.yml`

---

### Scenario 2: Collecting Logs from 100 Servers
**Current:** 100 servers × 30 seconds = 50 minutes  
**With forks=50:** 2 batches × 30 seconds = 1 minute  

**Use:** `parallel_forks.yml` with `--forks 50`

---

### Scenario 3: Restarting Services (Must Be One at a Time)
**Current:** Correct approach  
**With parallel:** DON'T DO IT (could cause outage)

**Use:** Keep `serial: 1` (this is correct for rolling updates)

---

### Scenario 4: Database Backups (Can Be Parallel)
**Current:** 20 DBs × 1 hour = 20 hours  
**With async:** 1 hour (all at once)

**Use:** `parallel_async.yml`

## ⚠️ Common Pitfalls

### ❌ DON'T parallelize if:
- Tasks modify shared resources (databases, files)
- You need zero downtime (use rolling updates with `serial`)
- Tasks depend on each other
- You're already at maximum system capacity

### ✅ DO parallelize if:
- Tasks are completely independent
- Each node's tasks don't affect other nodes
- You have headroom on bastion and network
- Tasks are long-running (>30 seconds)

## 🧪 Testing Your Changes (AAP)

### In Job Template:
1. **Limit:** `node1,node2` (test with subset first)
2. **Verbosity:** Level 2 (for debugging)
3. Click **Launch**

### View Results:
- **Jobs → Your Job → Output** (see real-time progress)
- Check **Elapsed Time** to measure improvement

### Compare Performance:
1. Run with **Forks: 1** (serial) - note the time
2. Run with **Forks: 10** - should be ~10x faster
3. Run with **Forks: 20** - should be ~20x faster (up to 20 hosts)

## 📞 Need Help?

1. **Start simple:** Try `parallel_forks.yml` first
2. **Measure:** Use `time` command to compare before/after
3. **Check examples:** Look at `parallel_async_real_world.yml` for production patterns
4. **Read comparison:** See `COMPARISON.md` for detailed analysis

## 🎓 Next Steps (AAP Workflow)

1. ✅ Create Machine Credential in AAP with SSH key
2. ✅ Add bastion config to inventory (ProxyJump)
3. ✅ Import inventory into AAP
4. ✅ Remove `serial: 1` from playbook
5. ✅ Create Job Template with Forks: 20
6. ✅ Test with small host subset
7. ✅ Measure performance improvement
8. ✅ If tasks are long, implement async pattern
9. ✅ Document your changes for team

## 📚 Additional AAP Resources

- **AAP-SETUP-GUIDE.md** - Complete AAP configuration walkthrough
- **EXECUTION-ENVIRONMENT.md** - EE-specific considerations and troubleshooting
- **COMPARISON.md** - Performance analysis and method comparison

