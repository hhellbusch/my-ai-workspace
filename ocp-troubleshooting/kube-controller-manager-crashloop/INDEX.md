# kube-controller-manager Crash Loop - Document Index

This directory contains comprehensive documentation for troubleshooting kube-controller-manager crash loop issues in OpenShift.

## 📚 Documentation Overview

### For Different User Types

#### 🚀 **Quick Start (I need help NOW!)**
Start here if you have a production issue:
1. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Fast commands and decision tree
2. **[diagnostic-script.sh](diagnostic-script.sh)** - Run automated diagnostics
3. **[TROUBLESHOOTING-FLOWCHART.md](TROUBLESHOOTING-FLOWCHART.md)** - Visual decision tree

#### 📖 **Comprehensive Guide (I want to understand)**
For complete understanding:
1. **[README.md](README.md)** - Full troubleshooting guide with all scenarios
2. **[TROUBLESHOOTING-FLOWCHART.md](TROUBLESHOOTING-FLOWCHART.md)** - Visual representation
3. **[EXAMPLE-OUTPUT.md](EXAMPLE-OUTPUT.md)** - What to expect from diagnostics

#### 🔧 **Practical Tools (Give me something to run)**
For hands-on approach:
1. **[diagnostic-script.sh](diagnostic-script.sh)** - Automated diagnostic collection
2. **[EXAMPLE-OUTPUT.md](EXAMPLE-OUTPUT.md)** - Example outputs and interpretations
3. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Command reference

## 📄 Document Descriptions

### [README.md](README.md)
**Purpose:** Complete troubleshooting guide  
**Length:** ~500 lines  
**Best for:** Comprehensive understanding of all scenarios

**Contains:**
- Overview and severity assessment
- Quick diagnosis commands
- 6 common root causes with diagnosis and resolution
- Step-by-step troubleshooting process
- Emergency recovery procedures
- Prevention and best practices
- Support escalation criteria

**Use when:**
- You want complete understanding
- You're dealing with an uncommon scenario
- You're learning troubleshooting procedures
- You need to understand dependencies

### [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
**Purpose:** Fast command reference and quick fixes  
**Length:** ~150 lines  
**Best for:** Experienced admins who need quick commands

**Contains:**
- One-line diagnostic commands
- Quick fixes for common issues
- Decision tree diagram
- Data collection script
- Log pattern matching
- Critical checks matrix
- Escalation criteria

**Use when:**
- You're familiar with the issue
- Time is critical
- You need specific commands
- You want a quick decision tree

### [TROUBLESHOOTING-FLOWCHART.md](TROUBLESHOOTING-FLOWCHART.md)
**Purpose:** Visual decision tree for systematic troubleshooting  
**Length:** ~400 lines  
**Best for:** Following a systematic approach

**Contains:**
- Visual ASCII flowchart from START to resolution
- Step-by-step decision points
- Commands at each decision point
- Clear paths for each issue type
- Success criteria
- Common gotchas

**Use when:**
- You want a systematic approach
- You're unsure what the issue is
- You prefer visual guidance
- You're new to this type of issue

### [diagnostic-script.sh](diagnostic-script.sh)
**Purpose:** Automated diagnostic data collection  
**Length:** Executable script  
**Best for:** Collecting comprehensive diagnostic data

**Features:**
- Automated checks for all common issues
- Collects logs, events, configurations
- Analyzes error patterns
- Generates recommendations
- Creates archive for support cases
- Color-coded output (✓ ⚠ ✗)

**Use when:**
- You need to collect diagnostic data
- You want automated analysis
- You're preparing for support escalation
- You want a thorough assessment

### [EXAMPLE-OUTPUT.md](EXAMPLE-OUTPUT.md)
**Purpose:** Show what diagnostic script outputs look like  
**Length:** ~400 lines  
**Best for:** Understanding script results

**Contains:**
- 4 scenario examples (certificate, etcd, OOM, healthy)
- Complete script output for each scenario
- Resolution steps taken
- List of files created
- Interpretation guide

**Use when:**
- You want to see what to expect
- You're interpreting script output
- You're learning to use the diagnostic script
- You want to see resolution examples

## 🎯 Usage Scenarios

### Scenario 1: Production Emergency
**Path:** Quick Reference → Diagnostic Script → Full Guide (if needed)

```bash
# 1. Quick assessment
oc get pods -n openshift-kube-controller-manager
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --previous | tail -50

# 2. Run diagnostics
./diagnostic-script.sh

# 3. Follow RECOMMENDATIONS.txt
# 4. If still stuck, consult README.md for your specific error
```

**Documents to use:**
1. QUICK-REFERENCE.md - Get oriented
2. diagnostic-script.sh - Collect data
3. README.md - Deep dive if needed

### Scenario 2: Learning/Training
**Path:** Full Guide → Flowchart → Quick Reference

```bash
# 1. Read comprehensive guide
cat README.md

# 2. Study the decision tree
cat TROUBLESHOOTING-FLOWCHART.md

# 3. Bookmark quick reference
cat QUICK-REFERENCE.md

# 4. Practice with diagnostic script
./diagnostic-script.sh
```

**Documents to use:**
1. README.md - Learn concepts
2. TROUBLESHOOTING-FLOWCHART.md - Understand flow
3. EXAMPLE-OUTPUT.md - See examples
4. QUICK-REFERENCE.md - Quick lookup

### Scenario 3: Support Case Preparation
**Path:** Diagnostic Script → README (context) → Archive

```bash
# 1. Run comprehensive diagnostics
./diagnostic-script.sh

# 2. Review README for additional context
cat README.md | grep -A 20 "your-specific-error"

# 3. Attach generated .tar.gz to support case
# 4. Include relevant sections from README.md
```

**Documents to use:**
1. diagnostic-script.sh - Collect all data
2. README.md - Provide context
3. Generated archive - Attach to case

### Scenario 4: Post-Mortem/Documentation
**Path:** All documents for comprehensive understanding

```bash
# 1. Review what happened
cat kcm-diagnostics-*/RECOMMENDATIONS.txt

# 2. Document the issue
# Reference sections from README.md

# 3. Update runbooks
# Use FLOWCHART.md structure

# 4. Share learnings
# Reference QUICK-REFERENCE.md commands used
```

**Documents to use:**
All documents for complete understanding

## 🔍 Finding Information

### By Topic

| Topic | Primary Document | Secondary |
|-------|-----------------|-----------|
| Certificate Issues | README.md (Section: Certificate Issues) | QUICK-REFERENCE.md |
| etcd Problems | README.md (Section: Storage/etcd) | TROUBLESHOOTING-FLOWCHART.md |
| OOM/Resources | README.md (Section: Resource Constraints) | EXAMPLE-OUTPUT.md |
| Quick Commands | QUICK-REFERENCE.md | README.md |
| Decision Tree | TROUBLESHOOTING-FLOWCHART.md | QUICK-REFERENCE.md |
| Automated Check | diagnostic-script.sh | EXAMPLE-OUTPUT.md |

### By Time Available

| Time Available | Start With | Then |
|----------------|------------|------|
| 2 minutes | QUICK-REFERENCE.md | diagnostic-script.sh |
| 10 minutes | diagnostic-script.sh → RECOMMENDATIONS.txt | QUICK-REFERENCE.md |
| 30 minutes | TROUBLESHOOTING-FLOWCHART.md | README.md specific section |
| 1+ hours | README.md | All other documents |

### By Experience Level

| Experience | Primary Path | Notes |
|------------|--------------|-------|
| New to OCP | README.md → TROUBLESHOOTING-FLOWCHART.md | Read thoroughly |
| Experienced OCP Admin | QUICK-REFERENCE.md → diagnostic-script.sh | Quick assessment |
| OCP Expert | diagnostic-script.sh → README.md (as needed) | Use judgment |

## 🛠️ Quick Command Reference

### Most Common Commands

```bash
# Quick status check
oc get pods -n openshift-kube-controller-manager && oc get co kube-controller-manager

# Get logs
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --previous

# Run full diagnostics
./diagnostic-script.sh

# Fix certificate issue
oc delete secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager
```

## 📞 Getting Help

### If These Guides Don't Resolve Your Issue

1. **Collect Data:**
   ```bash
   ./diagnostic-script.sh
   oc adm must-gather
   ```

2. **Open Support Case:**
   - Attach diagnostic archive
   - Include relevant sections from README.md
   - Note: Steps already attempted from this guide

3. **Internal Escalation:**
   - Share RECOMMENDATIONS.txt output
   - Reference specific section from README.md
   - Provide timeline of issue

## 📝 Contributing

If you find issues with these guides or have suggestions:

1. Test all commands before suggesting
2. Follow existing document structure
3. Add examples where helpful
4. Keep commands copy-pasteable
5. Update this INDEX.md if adding new documents

## 🔄 Document Maintenance

**Last Updated:** December 3, 2025  
**OpenShift Version Tested:** 4.12, 4.13, 4.14  
**Review Frequency:** Quarterly

**Change Log:**
- 2025-12-03: Initial creation
- Guide covers OCP 4.12+
- Tested on production clusters

---

## Summary Table

| Document | Length | Purpose | Best For | Time to Read |
|----------|--------|---------|----------|--------------|
| [README.md](README.md) | Long | Complete guide | Understanding | 30+ min |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | Short | Fast lookup | Quick fixes | 5 min |
| [TROUBLESHOOTING-FLOWCHART.md](TROUBLESHOOTING-FLOWCHART.md) | Medium | Visual guide | Systematic approach | 15 min |
| [diagnostic-script.sh](diagnostic-script.sh) | Script | Automated tool | Data collection | 2 min (run) |
| [EXAMPLE-OUTPUT.md](EXAMPLE-OUTPUT.md) | Medium | Examples | Understanding output | 10 min |

**Start here based on your situation:**
- 🚨 **Emergency:** QUICK-REFERENCE.md
- 📊 **Need data:** diagnostic-script.sh  
- 🗺️ **Need guidance:** TROUBLESHOOTING-FLOWCHART.md
- 📚 **Want to learn:** README.md

