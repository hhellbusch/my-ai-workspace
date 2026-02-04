# AAP SSH MTU Issues - Documentation Index

> **AI Disclosure:** This documentation was created with AI assistance (Claude 3.5 Sonnet via Cursor) on 2026-02-04.

Quick navigation for troubleshooting SSH connection issues from Ansible Automation Platform on OpenShift.

## 📚 Documentation Structure

### Core Documents

1. **[README.md](README.md)** - Complete troubleshooting guide
   - Overview and symptoms
   - Investigation workflow
   - Resolution strategies
   - Verification procedures
   - Prevention best practices

2. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - One-liners and quick fixes
   - Diagnostic one-liners
   - Quick fixes
   - MTU values reference
   - Interpretation guides

3. **[EXAMPLES.md](EXAMPLES.md)** - Real-world scenarios
   - 6 detailed real-world examples
   - Diagnosis steps
   - Resolution approaches
   - Verification methods

### Tools

4. **[diagnose-mtu.sh](diagnose-mtu.sh)** - Automated diagnostic script
   ```bash
   ./diagnose-mtu.sh <aap-namespace> <target-host-ip>
   ```

### Technical Documentation

5. **[TECHNICAL-ACCURACY-REVIEW.md](TECHNICAL-ACCURACY-REVIEW.md)** - Complete technical review
   - What was corrected and why
   - Valid vs invalid SSH options
   - Verification sources
   - Recommendations for existing users

6. **[MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md)** - Node-level MTU configuration
   - Why you cannot configure individual nodes with different MTU
   - Cluster-wide MTU requirements
   - What you can do instead (MSS clamping, dedicated nodes)
   - Real-world scenarios and solutions

## 🚀 Quick Start Paths

### "I need a quick fix NOW"
1. Go to [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
2. Try **Fix 1** (SSH configuration in inventory)
3. If that doesn't work, run diagnostic script

### "I want to understand what's happening"
1. Read [README.md](README.md) → Investigation Workflow section
2. Read [README.md](README.md) → Understanding SSH's Limited MTU Control
3. Run `./diagnose-mtu.sh` to gather evidence
4. Review similar scenarios in [EXAMPLES.md](EXAMPLES.md)

### "I want to see examples like my issue"
1. Go to [EXAMPLES.md](EXAMPLES.md)
2. Find scenario matching your symptoms
3. Follow the diagnosis and resolution steps

## 🎯 Find Information by Symptom

| Symptom | Document | Section |
|---------|----------|---------|
| SSH hangs after authentication | README.md | Investigation → Phase 1 → Step 3 |
| | EXAMPLES.md | Example 1 |
| Works from node, fails from pod | README.md | Investigation → Phase 3 |
| | EXAMPLES.md | Example 2 |
| Package installations fail | EXAMPLES.md | Example 4 |
| File transfers stall | EXAMPLES.md | Example 5 |
| Inconsistent/intermittent failures | EXAMPLES.md | Example 3 |
| Different behavior per network | EXAMPLES.md | Example 6 |

## 📊 Find Information by Task

| Task | Document | Section |
|------|----------|---------|
| Run diagnostics | diagnose-mtu.sh | Automated script |
| | QUICK-REFERENCE.md | Quick Diagnostics |
| Check cluster MTU | QUICK-REFERENCE.md | Check Cluster MTU |
| Test path MTU | README.md | Phase 1 → Step 1 |
| | QUICK-REFERENCE.md | Test MTU from Pod |
| Fix Ansible configuration | README.md | Strategy 1 |
| | QUICK-REFERENCE.md | Quick Fixes |
| Build custom execution environment | README.md | Strategy 1 → Option C |
| | EXAMPLES.md | Example 4 |
| Configure network equipment | README.md | Strategy 3 |
| Verify fix | README.md | Verification section |

## 🔍 Common Searches

### "How do I test MTU from an AAP pod?"
→ [QUICK-REFERENCE.md](QUICK-REFERENCE.md#test-mtu-from-pod)

### "What MTU should my cluster have?"
→ [QUICK-REFERENCE.md](QUICK-REFERENCE.md#common-mtu-values)

### "How do I fix this in my Ansible inventory?"
→ [README.md](README.md#strategy-1-configure-ansible-to-handle-mtu-recommended)  
→ [QUICK-REFERENCE.md](QUICK-REFERENCE.md#fix-1-ssh-configuration-in-inventory-recommended)

### "Can I configure some nodes with different MTU?"
→ [MTU-NODE-CONFIGURATION.md](MTU-NODE-CONFIGURATION.md) - **No, and here's why**

### "Can I see a real example of this issue?"
→ [EXAMPLES.md](EXAMPLES.md) - 6 detailed scenarios

### "What should I tell my network team?"
→ [QUICK-REFERENCE.md](QUICK-REFERENCE.md#network-team-quick-reference)  
→ [README.md](README.md) Strategy 3 (MSS Clamping)

### "How do I verify the fix worked?"
→ [README.md](README.md#verification)

## 📖 Reading Recommendations

### First Time Here
1. Start with [README.md](README.md) Overview section
2. Run [diagnose-mtu.sh](diagnose-mtu.sh) if you have access
3. Review [EXAMPLES.md](EXAMPLES.md) for similar scenarios

### Experienced Administrator
1. Go straight to [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
2. Apply known fixes
3. Reference [EXAMPLES.md](EXAMPLES.md) if needed

### Network Engineer
1. Read [README.md](README.md) Root Cause section
2. Check [QUICK-REFERENCE.md](QUICK-REFERENCE.md#network-team-quick-reference)
3. Review [README.md](README.md) Strategy 3 (MSS Clamping)

### Sharing with Team
1. Send [README.md](README.md) for comprehensive guide
2. Send [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for daily use
3. Send [EXAMPLES.md](EXAMPLES.md) for learning
4. Send [TECHNICAL-ACCURACY-REVIEW.md](TECHNICAL-ACCURACY-REVIEW.md) if they used original docs

## 🛠 Tool Reference

### Diagnostic Script
```bash
# Full diagnostics
./diagnose-mtu.sh ansible-automation-platform 192.168.100.50

# Output includes:
# - Cluster MTU configuration
# - Pod MTU settings
# - Progressive MTU testing
# - Path MTU discovery
# - SSH connection test
# - Recommendations
```

### Manual Testing
```bash
# Quick MTU test
oc exec -n <namespace> <pod> -- ping -M do -s 1472 <target-ip> -c 4

# Path MTU discovery
oc exec -n <namespace> <pod> -- tracepath <target-ip>

# Verbose SSH
oc exec -it -n <namespace> <pod> -- ssh -vvv <target-host>
```

## 🔗 Related Documentation

- [CoreOS Networking Issues](../coreos-networking-issues/) - General RHCOS networking
- [API Slowness](../api-slowness-web-console/) - May include network issues

## 📝 Document Status

- **Created:** 2026-02-04
- **Last Updated:** 2026-02-04 (Technical accuracy review completed)
- **Tested Versions:** 
  - OpenShift 4.12-4.16
  - AAP 2.3-2.5
- **Status:** Active

### Technical Accuracy Notes

This documentation underwent technical review to ensure accuracy:
- ✅ OVN-Kubernetes MTU (1400 for standard networks) - Verified correct
- ✅ Valid SSH options (`IPQoS`, `Compression`) - Verified against OpenSSH documentation
- ⚠️ Pod label selectors - Made generic due to variation across AAP versions
- 📝 Added section explaining SSH's limited direct MTU control
- 📝 Clarified that SSH options provide workarounds, not direct MTU control
- 📝 Emphasized network-level solutions (MSS clamping, ICMP) as primary fixes

## 🤝 Contributing

When adding new information:
- Add real-world examples to [EXAMPLES.md](EXAMPLES.md)
- Update quick fixes in [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Enhance investigation steps in [README.md](README.md)
- Keep [INDEX.md](INDEX.md) (this file) updated

## 📞 Quick Help

**Emergency?** Go to [QUICK-REFERENCE.md](QUICK-REFERENCE.md)  
**Learning?** Start with [README.md](README.md)  
**Examples?** See [EXAMPLES.md](EXAMPLES.md)  
**Diagnostics?** Run [diagnose-mtu.sh](diagnose-mtu.sh)
