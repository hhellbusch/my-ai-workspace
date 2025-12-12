# CoreOS Network Troubleshooting - Index

## Quick Start

**Start here if you have a non-working network:**

1. **Run the diagnostic script first:**
   ```bash
   cd ~/gemini-workspace/ocp-troubleshooting/coreos-networking-issues
   chmod +x diagnose-network.sh
   ./diagnose-network.sh | tee network-diagnostic-output.txt
   ```

2. **Review the summary at the end of the diagnostic output**

3. **Use the Quick Reference for immediate fixes:**
   - See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) for copy-paste commands

4. **Compare your output with examples:**
   - See [EXAMPLES.md](./EXAMPLES.md) to identify your specific scenario

5. **Deep dive if needed:**
   - See [README.md](./README.md) for comprehensive troubleshooting guide

## Files in This Guide

### [README.md](./README.md)
**Comprehensive troubleshooting guide** with detailed phase-by-phase diagnostics.

**Use when:**
- You need to understand what each diagnostic step does
- Quick fixes didn't work
- You want to learn systematic troubleshooting

**Contains:**
- Phase-by-phase troubleshooting steps
- Explanation of what to look for
- Common scenarios with solutions
- CoreOS-specific checks

### [diagnose-network.sh](./diagnose-network.sh)
**Automated diagnostic script** that gathers all network information.

**Use when:**
- You want a quick overview of the entire system
- You need to save diagnostic output for later review
- You want to share system state with someone helping you

**Provides:**
- Complete network configuration dump
- Service status
- Recent logs
- Connectivity tests
- Summary of key findings

### [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
**Quick command reference** with copy-paste solutions.

**Use when:**
- You know what's wrong and just need the fix command
- You want quick status checks
- You need a one-liner diagnostic
- You're in a hurry

**Contains:**
- Essential diagnostic commands
- Quick fix commands
- Decision tree flowchart
- Common error messages
- One-liner diagnostic command

### [EXAMPLES.md](./EXAMPLES.md)
**Real-world output examples** from various failure scenarios.

**Use when:**
- You want to compare your output with known issues
- You're not sure which scenario matches your problem
- You want to see what healthy output looks like
- You want to verify a fix worked correctly

**Contains:**
- Healthy system output for reference
- 6 common failure scenarios with actual output
- Comparison table
- Specific fixes for each scenario

## Troubleshooting Workflow

```
┌─────────────────────────────────────────┐
│ Network not working?                    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 1. Run diagnose-network.sh              │
│    ./diagnose-network.sh | tee diag.txt │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 2. Check SUMMARY section at end         │
│    Look for [FAIL] markers              │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 3. Try relevant Quick Fix from          │
│    QUICK-REFERENCE.md                   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ Fixed? ──YES──> Done! 🎉                │
│   │                                      │
│   NO                                     │
│   │                                      │
│   ▼                                      │
│ 4. Compare output with EXAMPLES.md      │
│    Find matching scenario                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 5. Follow scenario-specific fix         │
│    from EXAMPLES.md                      │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ Still stuck?                             │
│ Use README.md for deep troubleshooting  │
└─────────────────────────────────────────┘
```

## Common Scenarios Quick Index

| Problem | Quick Check | File | Section |
|---------|-------------|------|---------|
| No network at all | `systemctl is-active NetworkManager` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 5 |
| Interface shows NO-CARRIER | `cat /sys/class/net/ens3/carrier` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 2 |
| Has 169.254.x.x IP | `ip addr show` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 1 |
| Can't reach gateway | `ping $(ip route \| grep default \| awk '{print $3}')` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 3 or 6 |
| Can ping IPs but not hostnames | `nslookup google.com` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 4 |
| Can reach local network only | `ip route \| grep default` | [EXAMPLES.md](./EXAMPLES.md) | Scenario 6 |

## Essential Commands at a Glance

```bash
# Quick status overview
systemctl is-active NetworkManager && \
ip link show && \
ip addr show && \
ip route show && \
ping -c 1 8.8.8.8 && \
echo "Network is working!"

# Quick restart
systemctl restart NetworkManager

# Quick connection restart
nmcli connection down "Wired connection 1" && \
nmcli connection up "Wired connection 1"

# Quick diagnostic
./diagnose-network.sh
```

## File Sizes and Reading Times

- **QUICK-REFERENCE.md** - ~5 minutes read, use for quick lookups
- **EXAMPLES.md** - ~15 minutes read, skim to find your scenario
- **README.md** - ~30 minutes read, comprehensive reference
- **diagnose-network.sh** - Run time: ~30 seconds

## Tips for Using This Guide

1. **Start with the script** - Always run `diagnose-network.sh` first
2. **Save the output** - Use `| tee filename.txt` to save diagnostic output
3. **Work systematically** - Don't skip steps; network issues often have multiple causes
4. **Check the simple things first** - Is NetworkManager running? Is the interface UP?
5. **Use examples** - Real output examples help you know what to look for
6. **One change at a time** - Make one fix, test, then proceed

## Getting Additional Help

If you're still stuck after going through this guide:

1. **Save full diagnostic output:**
   ```bash
   ./diagnose-network.sh > full-diagnostic-$(date +%Y%m%d-%H%M%S).txt
   ```

2. **Note your specific symptoms:**
   - What works?
   - What doesn't work?
   - What error messages do you see?
   - Is this a VM or bare metal?

3. **Check CoreOS/RHCOS documentation:**
   - [Fedora CoreOS Docs](https://docs.fedoraproject.org/en-US/fedora-coreos/)
   - [Red Hat CoreOS Docs](https://docs.openshift.com/container-platform/latest/architecture/architecture-rhcos.html)

4. **Community resources:**
   - CoreOS Discourse
   - Red Hat forums
   - ServerFault for specific issues

## Related Troubleshooting Guides

This guide is part of a collection:

- **[../bare-metal-node-inspection-timeout/](../bare-metal-node-inspection-timeout/)** - BMH inspection issues
- **[../csr-management/](../csr-management/)** - Certificate signing requests
- **[../kube-controller-manager-crashloop/](../kube-controller-manager-crashloop/)** - Kubernetes control plane issues

## Contributing

Found an issue or have a suggestion? This is part of a personal knowledge base, but feedback is always appreciated.

---

**Last Updated:** December 9, 2025
**Version:** 1.0

