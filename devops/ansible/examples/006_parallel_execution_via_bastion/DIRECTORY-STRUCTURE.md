# Directory Structure

Complete organizational overview of the parallel execution example.

```
006_parallel_execution_via_bastion/
│
├── 📄 README.md
│   └── Main overview, quick start, performance examples
│
├── 📄 INDEX.md  
│   └── Complete navigation guide to all files
│
├── 📄 DIRECTORY-STRUCTURE.md (this file)
│   └── Visual layout of all files and their purposes
│
├── 📄 inventory.yml
│   └── Example inventory with bastion ProxyJump configuration
│
├── 📄 ansible.cfg
│   └── Recommended Ansible settings for AAP and bastion
│
├── 📁 docs/                          ← Detailed Documentation
│   │
│   ├── 📄 AAP-README.md              ⭐ START HERE
│   │   └── AAP overview, quick start, architecture, common scenarios
│   │
│   ├── 📄 AAP-SETUP-GUIDE.md         📖 Step-by-Step Guide
│   │   └── Credentials, inventories, job templates, troubleshooting
│   │
│   ├── 📄 EXECUTION-ENVIRONMENT.md   🔧 Advanced
│   │   └── EE specifics, SSH config, network, custom EE building
│   │
│   ├── 📄 QUICK-START.md             ⚡ Quick Reference
│   │   └── Decision trees, templates, copy-paste examples
│   │
│   └── 📄 COMPARISON.md              📊 Analysis
│       └── Performance calculations, visual timelines, method comparison
│
└── 📁 playbooks/                     ← Runnable Examples
    │
    ├── 📄 test_connectivity.yml      ⭐ TEST FIRST
    │   └── Validates bastion configuration, credentials, SSH connectivity
    │
    ├── 📄 serial_execution.yml       📉 Baseline
    │   └── Current serial approach (one node at a time) for comparison
    │
    ├── 📄 parallel_forks.yml         🚀 Simple (5-20x faster)
    │   └── Basic parallelism using forks - easiest upgrade
    │
    ├── 📄 parallel_async.yml         🚀🚀 Maximum (10-100x faster)
    │   └── True parallelism with async/await for long tasks
    │
    ├── 📄 parallel_strategy_free.yml ⚡ Specialized
    │   └── Each host runs independently - for specific use cases
    │
    └── 📄 parallel_async_real_world.yml 🏭 Production Example
        └── System updates with error handling and best practices
```

## File Purposes at a Glance

### Root Level Files

| File | Purpose | Read When |
|------|---------|-----------|
| `README.md` | Main overview and entry point | First visit |
| `INDEX.md` | Complete file navigation | Finding specific content |
| `DIRECTORY-STRUCTURE.md` | This file - visual layout | Understanding organization |
| `inventory.yml` | Example bastion configuration | Setting up inventory |
| `ansible.cfg` | Recommended settings | Optimizing performance |

### docs/ Directory

| File | Purpose | Target Audience | Time |
|------|---------|-----------------|------|
| `AAP-README.md` | AAP quick start & overview | All AAP users | 5 min |
| `AAP-SETUP-GUIDE.md` | Detailed step-by-step setup | First-time setup | 15 min |
| `EXECUTION-ENVIRONMENT.md` | EE troubleshooting & advanced | Debugging issues | 20 min |
| `QUICK-START.md` | Decision trees & templates | Need quick answers | 5 min |
| `COMPARISON.md` | Performance analysis | Choosing a method | 10 min |

### playbooks/ Directory

| File | Purpose | Speed Gain | When to Use |
|------|---------|------------|-------------|
| `test_connectivity.yml` | Validate configuration | N/A | Always run first |
| `serial_execution.yml` | Baseline comparison | 1x | For comparison only |
| `parallel_forks.yml` | Simple parallelism | 5-20x | Quick tasks, easy upgrade |
| `parallel_async.yml` | Maximum parallelism | 10-100x | Long tasks (30+ sec) |
| `parallel_strategy_free.yml` | Independent execution | Variable | Specialized cases |
| `parallel_async_real_world.yml` | Production example | 20-50x | Real-world patterns |

## Recommended Reading Order

### For AAP Users (New to This):

1. `README.md` - Get oriented (2 min)
2. `docs/AAP-README.md` - Understand AAP setup (5 min)
3. `inventory.yml` - See configuration example (2 min)
4. `playbooks/test_connectivity.yml` - Test your setup
5. `docs/AAP-SETUP-GUIDE.md` - Detailed implementation (15 min)
6. `docs/QUICK-START.md` - Apply to your playbooks (5 min)

**Total time:** ~30 minutes to full implementation

### For AAP Users (Already Working, Want to Optimize):

1. `docs/COMPARISON.md` - Understand trade-offs (10 min)
2. `playbooks/parallel_async.yml` - Learn async pattern (5 min)
3. `playbooks/parallel_async_real_world.yml` - Production patterns (10 min)
4. `docs/QUICK-START.md` - Copy templates (5 min)

**Total time:** ~30 minutes to optimization

### For Troubleshooting:

1. `docs/EXECUTION-ENVIRONMENT.md` - EE-specific issues
2. `docs/AAP-SETUP-GUIDE.md` - Setup validation
3. `playbooks/test_connectivity.yml` - Basic connectivity
4. `INDEX.md` - Find specific solutions

## Quick Access by Need

### "I need to set this up in AAP"
→ `docs/AAP-README.md` → `docs/AAP-SETUP-GUIDE.md`

### "I want to test if it works"
→ `playbooks/test_connectivity.yml`

### "Which method should I use?"
→ `docs/QUICK-START.md` (decision tree)

### "How much faster will it be?"
→ `docs/COMPARISON.md` (performance calculations)

### "I'm having connection issues"
→ `docs/EXECUTION-ENVIRONMENT.md` (troubleshooting)

### "I need a copy-paste template"
→ `docs/QUICK-START.md` (templates section)

### "Show me a real example"
→ `playbooks/parallel_async_real_world.yml`

### "I can't find what I'm looking for"
→ `INDEX.md` (complete navigation)

## File Size & Complexity

| File Type | Lines | Complexity | Time to Read |
|-----------|-------|------------|--------------|
| Root README.md | ~150 | Low | 5 min |
| Index | ~200 | Low | 5 min |
| AAP-README.md | ~300 | Medium | 10 min |
| AAP-SETUP-GUIDE.md | ~400 | Medium | 15 min |
| EXECUTION-ENVIRONMENT.md | ~500 | High | 20 min |
| QUICK-START.md | ~250 | Low | 5 min |
| COMPARISON.md | ~300 | Medium | 10 min |
| Test playbook | ~100 | Low | 5 min |
| Example playbooks | ~50-150 | Low-Medium | 5-10 min |

## Navigation Shortcuts

### From Root → Specific Content

```
006_parallel_execution_via_bastion/
│
├─ Need AAP setup guide? → docs/AAP-README.md
├─ Need to test? → playbooks/test_connectivity.yml  
├─ Need performance data? → docs/COMPARISON.md
├─ Need troubleshooting? → docs/EXECUTION-ENVIRONMENT.md
├─ Need templates? → docs/QUICK-START.md
└─ Need complete index? → INDEX.md
```

### From Any File → Back to Navigation

- Root overview: `../README.md` or `../../README.md`
- Complete index: `../INDEX.md` or `../../INDEX.md`
- This structure: `../DIRECTORY-STRUCTURE.md` or `../../DIRECTORY-STRUCTURE.md`

## Maintenance Notes

### File Dependencies

```
INDEX.md
  ├── References all other files
  └── Update when adding new files

README.md (root)
  ├── References docs/ and playbooks/
  └── Update for major structural changes

docs/AAP-README.md
  ├── References all docs/ files
  ├── References playbooks/test_connectivity.yml
  └── Update when adding new playbooks

docs/*.md
  ├── Reference playbooks/ examples
  └── Update when adding new playbooks
```

### Adding New Files

1. **New Playbook:** Add to `playbooks/` directory
   - Update: `INDEX.md`, `README.md`, `docs/AAP-README.md`

2. **New Documentation:** Add to `docs/` directory
   - Update: `INDEX.md`, `README.md`

3. **New Root File:** Add to root directory
   - Update: `INDEX.md`, `DIRECTORY-STRUCTURE.md`

## Summary

- **15 total files** in organized structure
- **3 directories**: root, docs/, playbooks/
- **Clear separation**: Documentation vs. runnable examples
- **Progressive complexity**: Start simple, go deeper as needed
- **Multiple entry points**: README, INDEX, or specific docs
- **Cross-referenced**: Easy navigation between related files

Start with `README.md` for overview, then `docs/AAP-README.md` for AAP-specific guidance!

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
