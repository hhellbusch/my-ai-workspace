# Index: Parallel Execution via Bastion for AAP

Complete guide to parallel task execution through a bastion host when using Ansible Automation Platform.

## 📖 Documentation (in `docs/`)

### For AAP Users (RECOMMENDED READING ORDER):

1. **[docs/AAP-README.md](docs/AAP-README.md)** ⭐ START HERE
   - Architecture overview for AAP
   - Quick start guide
   - Common scenarios and solutions
   - AAP-specific configuration
   - **Read this first if using AAP!**

2. **[docs/AAP-SETUP-GUIDE.md](docs/AAP-SETUP-GUIDE.md)** 
   - Step-by-step AAP configuration
   - Credential setup
   - Job Template configuration
   - Troubleshooting guide
   - Performance tuning

3. **[docs/EXECUTION-ENVIRONMENT.md](docs/EXECUTION-ENVIRONMENT.md)**
   - Execution Environment specifics
   - SSH configuration in containers
   - Network requirements
   - Custom EE building
   - Advanced troubleshooting

### Quick Reference:

4. **[docs/QUICK-START.md](docs/QUICK-START.md)**
   - Decision tree (which method to use?)
   - Copy-paste templates
   - AAP Job Template settings
   - Testing procedures

5. **[docs/COMPARISON.md](docs/COMPARISON.md)**
   - Visual timeline comparisons
   - Performance calculations
   - When to use each method
   - Code complexity analysis

### General Background:

6. **[README.md](README.md)** (root level)
   - Parallelism concepts
   - Async vs Forks vs Strategy
   - Best practices
   - Examples overview

## 🧪 Test & Example Playbooks (in `playbooks/`)

### Testing:

- **[playbooks/test_connectivity.yml](playbooks/test_connectivity.yml)** ⭐ RUN THIS FIRST
  - Validates bastion configuration
  - Tests SSH connectivity
  - Verifies credentials work
  - Tests privilege escalation
  - **Always run this before scaling up!**

### Execution Patterns:

- **[playbooks/serial_execution.yml](playbooks/serial_execution.yml)**
  - Your current approach (baseline)
  - One node at a time
  - For comparison only

- **[playbooks/parallel_forks.yml](playbooks/parallel_forks.yml)**
  - Simple parallelism
  - Just remove `serial: 1` and increase forks
  - **Easiest upgrade - 5-10x faster**
  - Good for quick tasks

- **[playbooks/parallel_async.yml](playbooks/parallel_async.yml)**
  - True parallelism with async
  - For long-running tasks
  - **Maximum speed - 10-50x faster**
  - Best for tasks >30 seconds

- **[playbooks/parallel_strategy_free.yml](playbooks/parallel_strategy_free.yml)**
  - Each host runs independently
  - No synchronization between hosts
  - For specialized use cases

- **[playbooks/parallel_async_real_world.yml](playbooks/parallel_async_real_world.yml)**
  - Production example
  - System updates, maintenance
  - Shows practical patterns
  - Error handling included

## 📋 Configuration Files

- **[inventory.yml](inventory.yml)**
  - Example inventory with bastion ProxyJump
  - AAP-specific comments
  - Different credential scenarios
  - Copy and modify for your environment

- **[ansible.cfg](ansible.cfg)**
  - Recommended Ansible settings
  - SSH connection optimization
  - Fork defaults (note: AAP Job Template overrides this)

## 🎯 Use Cases - Which File to Use?

### "I need to set this up in AAP"
→ Read **docs/AAP-README.md**, then **docs/AAP-SETUP-GUIDE.md**

### "I want to test if my bastion config works"
→ Run **playbooks/test_connectivity.yml** in AAP Job Template

### "My tasks are quick (<30 seconds each)"
→ Use **playbooks/parallel_forks.yml** pattern with Forks: 20 in Job Template

### "My tasks are slow (>30 seconds each)"
→ Use **playbooks/parallel_async.yml** pattern with high forks

### "I need a real-world example"
→ See **playbooks/parallel_async_real_world.yml**

### "Which method should I use?"
→ Read **docs/QUICK-START.md** decision tree

### "How much faster will this be?"
→ See **docs/COMPARISON.md** performance calculations

### "Having connection issues"
→ Read **docs/EXECUTION-ENVIRONMENT.md** troubleshooting section

### "What's the difference between methods?"
→ Read **docs/COMPARISON.md** visual timelines

## 🚀 Quick Start Checklist

- [ ] 1. Read **docs/AAP-README.md** (5 minutes)
- [ ] 2. Configure SSH credentials in AAP
- [ ] 3. Create inventory with ProxyJump settings (see **inventory.yml**)
- [ ] 4. Import **playbooks/test_connectivity.yml** to AAP
- [ ] 5. Create Job Template with Forks: 1, Limit: one node
- [ ] 6. Run test - verify it works!
- [ ] 7. Remove `serial: 1` from your playbook
- [ ] 8. Update Job Template: Forks: 20, remove Limit
- [ ] 9. Run and measure time improvement
- [ ] 10. If tasks are long, implement async pattern from **playbooks/parallel_async.yml**

## 📊 Performance Summary

| Your Situation | Use This | Expected Speedup |
|----------------|----------|------------------|
| 5-20 quick tasks per host | parallel_forks.yml | 5-20x faster |
| Long tasks (5+ min each) | parallel_async.yml | 10-100x faster |
| 100+ hosts | parallel_forks.yml + Job Slicing | 50-100x faster |
| Mixed quick/long tasks | parallel_async_real_world.yml | 20-50x faster |

## 🔧 AAP Job Template Quick Settings

### Conservative (Start Here):
```
Forks: 10
Timeout: 1800 (30 min)
Limit: node1,node2  (test subset)
```

### Moderate (Most Common):
```
Forks: 20
Timeout: 3600 (1 hour)
Limit: (none - all hosts)
```

### Aggressive (Large Scale):
```
Forks: 50
Timeout: 7200 (2 hours)
Job Slicing: 10 (if 500+ hosts)
```

## 📞 Help & Troubleshooting

### Common Issues:

| Problem | Solution |
|---------|----------|
| Connection timeout | See docs/AAP-SETUP-GUIDE.md → Troubleshooting |
| Permission denied | Check credentials, see docs/EXECUTION-ENVIRONMENT.md |
| Tasks still slow | Read docs/COMPARISON.md, may need async |
| EE can't reach bastion | See docs/EXECUTION-ENVIRONMENT.md → Network |

### Where to Look:

- **Setup issues:** docs/AAP-SETUP-GUIDE.md
- **Connection issues:** docs/EXECUTION-ENVIRONMENT.md
- **Performance issues:** docs/COMPARISON.md
- **Configuration questions:** docs/AAP-README.md
- **"Which method?" questions:** docs/QUICK-START.md

## 🎓 Learning Path

### Beginner (Just getting started):
1. docs/AAP-README.md
2. playbooks/test_connectivity.yml
3. playbooks/parallel_forks.yml
4. docs/AAP-SETUP-GUIDE.md

### Intermediate (Have it working, want to optimize):
1. docs/COMPARISON.md
2. playbooks/parallel_async.yml
3. docs/QUICK-START.md templates
4. playbooks/parallel_async_real_world.yml

### Advanced (Custom configurations):
1. docs/EXECUTION-ENVIRONMENT.md
2. Custom EE building
3. Job Slicing setup
4. Instance Groups

## 📚 External Resources

- [AAP Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)
- [Ansible Async Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
- [SSH ProxyJump Documentation](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html)

## ✅ Next Steps

After reviewing this index:

1. **For AAP users:** Go to **docs/AAP-README.md**
2. **For command-line users:** Go to **README.md**
3. **Just want templates:** Go to **docs/QUICK-START.md**
4. **Need setup help:** Go to **docs/AAP-SETUP-GUIDE.md**
5. **Having issues:** Go to **docs/EXECUTION-ENVIRONMENT.md**

---

**Questions? Start with docs/AAP-README.md - it has everything you need to get started!**

