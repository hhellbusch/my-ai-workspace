# Parallel Execution via Bastion for AAP

Transform your serial Ansible playbooks into parallel powerhouses when using **Ansible Automation Platform (AAP)** with a bastion/jump host.

## The Problem

You're running Ansible from AAP through a bastion host, and your tasks execute serially:
- Task runs on node1, completes
- Task runs on node2, completes  
- Task runs on node3, completes
- ...repeat for all nodes

**Result:** If you have 20 nodes and tasks take 5 minutes each, you wait 100 minutes! 😴

## The Solution

Execute tasks in parallel across all nodes simultaneously:
- Tasks run on node1, node2, node3... all at once

**Result:** Same 20 nodes, same 5-minute tasks = **5 minutes total!** ⚡ (20x faster!)

## Architecture

```
┌─────────────────────────┐
│ Ansible Automation      │
│ Platform (Controller)   │ ← Your playbooks run HERE
│ Execution Environment   │
└───────────┬─────────────┘
            │ SSH with ProxyJump
            ↓
┌─────────────────────────┐
│ Bastion/Jump Host       │ ← SSH proxy ONLY
└───────────┬─────────────┘
            │ SSH
            ↓
┌─────────────────────────┐
│ Target Nodes            │ ← Tasks execute HERE
│ (parallel execution)    │
└─────────────────────────┘
```

## Quick Start (5 Minutes)

### 1. **Read the AAP Guide**
👉 **[docs/AAP-README.md](docs/AAP-README.md)** ⭐ Start here!

### 2. **Test Your Setup**
Import and run: **[playbooks/test_connectivity.yml](playbooks/test_connectivity.yml)**

### 3. **Apply to Your Playbook**
Remove `serial: 1`, set **Forks: 20** in Job Template → Done!

## What's Included

```
📁 006_parallel_execution_via_bastion/
│
├── 📄 README.md (you are here)
├── 📄 INDEX.md (complete file navigation)
├── 📄 inventory.yml (example with ProxyJump config)
├── 📄 ansible.cfg (recommended settings)
│
├── 📁 docs/ (detailed documentation)
│   ├── AAP-README.md ⭐ START HERE for AAP users
│   ├── AAP-SETUP-GUIDE.md (step-by-step configuration)
│   ├── EXECUTION-ENVIRONMENT.md (EE troubleshooting)
│   ├── QUICK-START.md (decision trees & templates)
│   └── COMPARISON.md (performance analysis)
│
└── 📁 playbooks/ (runnable examples)
    ├── test_connectivity.yml ⭐ TEST FIRST
    ├── serial_execution.yml (your current approach)
    ├── parallel_forks.yml (5-10x faster)
    ├── parallel_async.yml (10-50x faster)
    ├── parallel_strategy_free.yml (specialized)
    └── parallel_async_real_world.yml (production example)
```

## Three Ways to Parallelize

### Method 1: Increase Forks (Easiest)
**Implementation:** 5 minutes  
**Speedup:** 5-20x

Remove `serial: 1` from playbook, set **Forks: 20** in AAP Job Template.

### Method 2: Use Async (Most Powerful)
**Implementation:** 30 minutes  
**Speedup:** 10-100x

Use async/await pattern for long-running tasks (see `playbooks/parallel_async.yml`)

### Method 3: Strategy Free (Specialized)
**Implementation:** 5 minutes  
**Speedup:** Variable

Each host runs independently at maximum speed.

## Performance Examples

### Example 1: 20 Nodes, 3 Tasks (5 min each)

| Method | Time | Speedup |
|--------|------|---------|
| Serial (current) | 300 min (5 hours) | 1x |
| Forks: 20 | 15 min | **20x faster** |
| Async | 5 min | **60x faster** |

### Example 2: 100 Nodes, Quick Tasks (30 sec each)

| Method | Time | Speedup |
|--------|------|---------|
| Serial | 50 min | 1x |
| Forks: 50 | 1 min | **50x faster** |

## Documentation Index

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[docs/AAP-README.md](docs/AAP-README.md)** | AAP quick start & overview | First time setup |
| **[docs/AAP-SETUP-GUIDE.md](docs/AAP-SETUP-GUIDE.md)** | Detailed AAP configuration | Need step-by-step |
| **[docs/EXECUTION-ENVIRONMENT.md](docs/EXECUTION-ENVIRONMENT.md)** | EE troubleshooting | Connection issues |
| **[docs/QUICK-START.md](docs/QUICK-START.md)** | Templates & decision tree | Want copy-paste |
| **[docs/COMPARISON.md](docs/COMPARISON.md)** | Performance analysis | Choosing a method |
| **[INDEX.md](INDEX.md)** | Complete file navigation | Finding specific info |

## Playbook Examples

| Playbook | Use Case | Speed Gain |
|----------|----------|------------|
| **[playbooks/test_connectivity.yml](playbooks/test_connectivity.yml)** | Test bastion config | N/A (test only) |
| **[playbooks/serial_execution.yml](playbooks/serial_execution.yml)** | Baseline comparison | 1x (current) |
| **[playbooks/parallel_forks.yml](playbooks/parallel_forks.yml)** | Quick tasks | 5-20x |
| **[playbooks/parallel_async.yml](playbooks/parallel_async.yml)** | Long tasks | 10-100x |
| **[playbooks/parallel_async_real_world.yml](playbooks/parallel_async_real_world.yml)** | Production example | 20-50x |

## Common Questions

**Q: Will this work with my current AAP setup?**  
A: Yes! Just needs ProxyJump configuration in inventory and proper credentials.

**Q: Do I need to change my playbooks a lot?**  
A: Minimal changes - often just removing `serial: 1` and adjusting Job Template settings.

**Q: What if tasks depend on each other?**  
A: Keep `serial: 1` for tasks that must run in order (like rolling updates).

**Q: Is this safe for production?**  
A: Yes, if tasks are truly independent. Test with small host counts first.

**Q: My tasks are failing with "connection timeout"**  
A: See [docs/EXECUTION-ENVIRONMENT.md](docs/EXECUTION-ENVIRONMENT.md) troubleshooting section.

## Next Steps

1. ✅ Read **[docs/AAP-README.md](docs/AAP-README.md)**
2. ✅ Review example **[inventory.yml](inventory.yml)** 
3. ✅ Test with **[playbooks/test_connectivity.yml](playbooks/test_connectivity.yml)**
4. ✅ Choose your approach from **[docs/QUICK-START.md](docs/QUICK-START.md)**
5. ✅ Implement and measure results!

## Additional Resources

- **[INDEX.md](INDEX.md)** - Complete navigation of all files
- **[Ansible Async Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)**
- **[AAP Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)**

