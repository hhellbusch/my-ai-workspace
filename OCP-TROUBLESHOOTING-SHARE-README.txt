OpenShift Troubleshooting Guides
==================================

Contents: ocp-troubleshooting-guides.zip (64 KB)
Created: December 3, 2025

WHAT'S INCLUDED
---------------

This archive contains comprehensive troubleshooting guides for OpenShift issues:

1. kube-controller-manager Crash Loop
   - Complete troubleshooting guide with 6 common root causes
   - Automated diagnostic script
   - Visual flowcharts and decision trees
   - Quick reference commands
   - Example outputs for different scenarios
   - Operator-specific error handling

2. Bare Metal Node Inspection Timeout
   - Complete guide for nodes stuck in inspecting state
   - BMC connectivity troubleshooting
   - Automated diagnostic script
   - Hardware compatibility issues
   - Active troubleshooting session example (master-2 NVIDIA ConnectX NIC issue)

HOW TO USE
----------

1. Extract the zip file:
   unzip ocp-troubleshooting-guides.zip

2. Navigate to the relevant guide:
   cd ocp-troubleshooting/

3. Start with the README.md in each subdirectory for an overview

4. For quick fixes, check QUICK-REFERENCE.md files

5. Run diagnostic scripts when available (diagnose-*.sh)

STRUCTURE
---------

ocp-troubleshooting/
├── README.md                                  (Main index)
├── kube-controller-manager-crashloop/         (Control plane issues)
│   ├── README.md                              (Complete guide)
│   ├── QUICK-REFERENCE.md                     (Fast commands)
│   ├── TROUBLESHOOTING-FLOWCHART.md          (Visual decision tree)
│   ├── diagnostic-script.sh                   (Automated diagnostics)
│   ├── EXAMPLE-OUTPUT.md                      (Sample outputs)
│   ├── INDEX.md                               (Navigation guide)
│   └── OPERATOR-ERRORS.md                     (Operator-specific issues)
└── bare-metal-node-inspection-timeout/        (Bare metal provisioning)
    ├── README.md                              (Complete guide)
    ├── QUICK-REFERENCE.md                     (Fast commands)
    ├── diagnose-bmh.sh                        (Automated diagnostics)
    ├── YOUR-ISSUE-SUMMARY.md                  (Common scenario)
    └── active-sessions/                       (Example session)
        └── master2-dec3-2025/                 (Real troubleshooting example)
            ├── SESSION-SUMMARY-master2-inspection.md
            └── TOMORROW-QUICKSTART.md

KEY FEATURES
------------

✓ Production-tested commands
✓ Automated diagnostic scripts
✓ Step-by-step troubleshooting processes
✓ Visual decision trees and flowcharts
✓ Real-world troubleshooting session examples
✓ Quick reference guides for emergencies
✓ Prevention and best practices

REQUIREMENTS
------------

- OpenShift 4.12+ (tested on 4.12, 4.13, 4.14)
- oc CLI with cluster admin access
- For diagnostic scripts: bash, jq (optional but recommended)

EMERGENCY USE
-------------

For immediate issues:

1. Control plane crash loop:
   ocp-troubleshooting/kube-controller-manager-crashloop/QUICK-REFERENCE.md

2. Bare metal node stuck:
   ocp-troubleshooting/bare-metal-node-inspection-timeout/QUICK-REFERENCE.md

DIAGNOSTIC SCRIPTS
------------------

Both guides include executable diagnostic scripts that:
- Automatically check for common issues
- Collect relevant logs and configurations
- Analyze error patterns
- Generate specific recommendations
- Create archives for support cases

Run with:
  ./diagnostic-script.sh (for kube-controller-manager)
  ./diagnose-bmh.sh [node-name] (for bare metal)

REAL-WORLD EXAMPLE
------------------

The bare-metal-node-inspection-timeout/active-sessions/ directory contains
a complete real troubleshooting session documenting:
- Issue: Third master node stuck in inspection
- Root cause: NVIDIA ConnectX NIC driver error
- Full diagnostic process
- Resolution steps

This provides a template for documenting your own troubleshooting sessions.

CONTRIBUTING
------------

These guides are actively maintained. If you find issues or have
improvements, please share feedback.

NOTES
-----

- All IP addresses and sensitive information have been redacted in examples
- Scripts are designed to be safe for production use (read-only operations)
- Always test in non-production first when possible

LICENSE
-------

These guides are provided for educational and reference purposes.

---

For questions or feedback, contact the OpenShift platform team.

Last Updated: December 3, 2025

