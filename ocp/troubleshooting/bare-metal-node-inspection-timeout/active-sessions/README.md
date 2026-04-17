# Active Troubleshooting Sessions

This directory contains detailed notes from ongoing or recently completed troubleshooting sessions. Each session is stored in its own subdirectory with comprehensive documentation of the problem, investigation, and resolution.

## ⚠️ Important Notice

**Each session is cluster-specific.** Do not assume that issues from one cluster apply to another cluster, even if symptoms appear similar. Always:
- Start with fresh diagnostics for your specific cluster
- Verify cluster operators and network configuration independently
- Use these sessions as reference examples, not as exact playbooks

## Current Sessions

### [master2-dec3-2025/](master2-dec3-2025/)
**Status:** 🔴 Completed - Cluster Not Recoverable  
**Date:** December 3, 2025  
**Cluster:** Specific cluster with VIP misconfiguration (NOT applicable to other clusters)  
**Issue:** master-2 stuck in inspection, escalated to critical etcd failure  
**Root Cause:** VIP misconfiguration from installation (cluster-specific)  
**Next Action:** Reinstallation required

**⚠️ This session involved a fundamentally broken cluster due to VIP misconfiguration. These specific issues do NOT apply to other clusters unless they have the same installation error.**

---

## Using These Sessions

These sessions provide:
- Real-world troubleshooting workflows
- Actual error messages and solutions
- Lessons learned from complex scenarios
- Commands that worked (and didn't work)
- Examples of diagnostic approaches

**Critical Reminder**: 
- ✅ Use these as **reference examples** of troubleshooting methodology
- ✅ Learn from the diagnostic approaches and commands used
- ❌ Do NOT assume the same root causes apply to your cluster
- ❌ Do NOT skip diagnostics because another cluster had different issues

## General Troubleshooting Approach

For any new cluster issue:
1. Start with the main [README.md](../README.md) quick checks
2. Run diagnostics specific to YOUR cluster
3. Check YOUR cluster's operator status
4. Reference these sessions for similar symptoms, but verify independently

## Session Organization

Each session folder contains:
- `SESSION-SUMMARY-*.md` - Complete troubleshooting history
- `FINAL-SESSION-SUMMARY.md` - Complete analysis and lessons learned
- `README.md` - Session overview and navigation
- Other specific documents as needed

## Archive Completed Sessions

When a session is resolved, consider moving it to an `archive/` subdirectory:

```bash
mkdir -p archive
mv master2-dec3-2025 archive/master2-dec3-2025-resolved
```

Add resolution summary to the archived session's README.
