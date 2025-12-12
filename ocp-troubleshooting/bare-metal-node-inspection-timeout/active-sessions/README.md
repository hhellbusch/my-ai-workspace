# Active Troubleshooting Sessions

This directory contains ongoing troubleshooting sessions for specific issues.

## Current Sessions

### [master2-dec3-2025/](master2-dec3-2025/)
**Status:** 🔴 Active  
**Date:** December 3, 2025  
**Issue:** master-2 stuck in inspection - NVIDIA ConnectX NIC driver error  
**Next Action:** Compare NIC configuration in iDRAC across all masters

---

## Session Organization

Each session folder contains:
- `SESSION-SUMMARY-*.md` - Complete troubleshooting history
- `TOMORROW-QUICKSTART.md` - Quick resume guide
- `README.md` - Session overview

## Archive Completed Sessions

When a session is resolved, move it to an `archive/` subdirectory:

```bash
mkdir -p archive
mv master2-dec3-2025 archive/master2-dec3-2025-resolved
```

Add resolution summary to the archived session's README.

