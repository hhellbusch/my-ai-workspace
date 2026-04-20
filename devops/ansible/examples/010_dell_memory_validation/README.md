# Dell PowerEdge Memory Validation Audit

Automated Ansible playbook to detect Dell PowerEdge servers where memory DIMMs failed POST (Power-On Self-Test) validation but the server still booted into production.

## Problem Statement

This playbook solves the scenario where servers were deployed with memory modules that failed POST validation, resulting in:
- Reduced memory capacity (server boots with less RAM than installed)
- No obvious errors visible from the OS perspective
- Potential performance issues due to missing memory

## How It Works

The playbook uses a **dual-source verification** approach:

1. **iDRAC/Redfish API** (Out-of-Band): Queries hardware controller for installed memory
2. **OS Memory Check** (In-Band): Queries `/proc/meminfo` for OS-detected memory
3. **Discrepancy Calculation**: Compares installed vs. detected to identify failures
4. **System Event Log**: Checks SEL for historical POST failure evidence

### Detection Logic

```
Installed (from iDRAC) - OS Detected = Discrepancy

If discrepancy < 5GB:    Status = OK (normal system reserved)
If discrepancy < 35GB:   Status = WARNING (possible single DIMM failure)
If discrepancy >= 35GB:  Status = CRITICAL (multiple DIMMs failed)
```

## Features

- ✅ **Out-of-band detection** - Works independently of OS state
- ✅ **Fleet-wide auditing** - Scan hundreds of servers in one run
- ✅ **Historical evidence** - Extracts SEL logs showing when/which DIMMs failed
- ✅ **Detailed reports** - Generates per-server reports for WARNING/CRITICAL servers
- ✅ **CSV summary** - Machine-readable summary for further analysis
- ✅ **CoreOS compatible** - Designed for Red Hat CoreOS/OpenShift environments
- ✅ **Error handling** - Gracefully handles iDRAC or node access failures

## Prerequisites

### 1. Ansible Environment

```bash
# Install Ansible (if not already installed)
sudo dnf install ansible  # RHEL/Fedora
# OR
pip install ansible

# Install required collection
ansible-galaxy collection install -r requirements.yml
```

### 2. Access Requirements

- **iDRAC Access**:
  - iDRAC IP addresses for all servers
  - iDRAC credentials (root or admin user)
  - Network access to iDRAC management network
  - iDRAC Enterprise license recommended (Basic/Express may have API limitations)

- **Node Access**:
  - SSH access to servers (for in-band memory check)
  - SSH key or password authentication
  - User with privileges to read `/proc/meminfo` (typically any user)

### 3. Information Needed

- List of server hostnames and iDRAC IPs
- Expected memory configuration per server (for reference)

## Setup

### 1. Create Inventory

```bash
# Copy example inventory
cp inventory.example.yml inventory.yml

# Edit inventory with your servers
vim inventory.yml
```

Example inventory:
```yaml
dell_servers:
  hosts:
    ocp-worker-01:
      ansible_host: 192.168.1.101
      idrac_ip: 192.168.10.101
      expected_memory_gb: 512
    
    ocp-worker-02:
      ansible_host: 192.168.1.102
      idrac_ip: 192.168.10.102
      expected_memory_gb: 512
```

### 2. Configure Credentials

Create encrypted vault for iDRAC credentials:

```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml
```

Add credentials:
```yaml
vault_idrac_user: root
vault_idrac_password: your-idrac-password-here
```

Save and exit (`:wq` in vim).

### 3. Test Connectivity

```bash
# Test iDRAC access (one server)
curl -k -u root:password https://idrac-ip/redfish/v1/

# Test SSH access
ansible dell_servers -i inventory.yml -m ping --ask-vault-pass
```

## Usage

### Basic Audit

Run the playbook:

```bash
ansible-playbook -i inventory.yml memory_audit.yml --ask-vault-pass
```

### Limit to Specific Servers

```bash
# Single server
ansible-playbook -i inventory.yml memory_audit.yml --limit ocp-worker-01 --ask-vault-pass

# Multiple servers
ansible-playbook -i inventory.yml memory_audit.yml --limit ocp-worker-01,ocp-worker-02 --ask-vault-pass

# Pattern matching
ansible-playbook -i inventory.yml memory_audit.yml --limit "ocp-worker-*" --ask-vault-pass
```

### Dry Run (Check Mode)

```bash
ansible-playbook -i inventory.yml memory_audit.yml --check --ask-vault-pass
```

### Adjust Thresholds

Customize detection thresholds for your environment:

```bash
ansible-playbook -i inventory.yml memory_audit.yml \
  -e "warning_threshold=8" \
  -e "critical_threshold=40" \
  --ask-vault-pass
```

## Output

### Console Output

During execution, you'll see detailed output for each server:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Server: ocp-worker-01
iDRAC: 192.168.10.101
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Memory Modules: 16
Installed (iDRAC): 512.0 GB
OS Detected:       448.0 GB
Discrepancy:       64.0 GB
Status:            CRITICAL

Recent Memory SEL Entries: 2
- [Critical] 2025-12-15T08:23:15: The system board DIMM.Socket.A3 Memory device status is disabled.
- [Critical] 2025-12-15T08:23:16: The system board DIMM.Socket.B3 Memory device status is disabled.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Fleet Summary

At the end, you'll see a fleet-wide summary:

```
╔═══════════════════════════════════════════════════════════════╗
║           FLEET-WIDE MEMORY AUDIT SUMMARY                     ║
╚═══════════════════════════════════════════════════════════════╝

Total Servers Audited: 10

STATUS BREAKDOWN:
  ✓ OK:       7 servers
  ⚠ WARNING:  1 servers  
  ✗ CRITICAL: 2 servers

CRITICAL SERVERS (require immediate attention):
  • ocp-worker-01 (192.168.10.101)
    Discrepancy: 64.0 GB
    SEL Entries: 2
  • ocp-worker-05 (192.168.10.105)
    Discrepancy: 96.0 GB
    SEL Entries: 3

Detailed reports generated in: ./reports/

╚═══════════════════════════════════════════════════════════════╝
```

### Generated Reports

The playbook creates:

1. **Detailed Text Reports** (`./reports/`)
   - One file per WARNING or CRITICAL server
   - Filename: `{STATUS}_{hostname}_{date}.txt`
   - Contains:
     - Complete memory inventory
     - SEL entries with timestamps
     - Analysis and recommendations
     - Specific failed DIMM slots

2. **CSV Summary** (`./reports/memory_audit_summary_{date}.csv`)
   - Machine-readable format
   - All servers in one file
   - Easy to import into spreadsheets or databases

Example CSV:
```csv
Hostname,iDRAC IP,Status,Installed GB,OS Detected GB,Discrepancy GB,Module Count,SEL Entries
ocp-worker-01,192.168.10.101,CRITICAL,512.0,448.0,64.0,16,2
ocp-worker-02,192.168.10.102,OK,512.0,509.8,2.2,16,0
```

## Understanding Results

### Status Meanings

- **OK**: Discrepancy < 5GB - Normal system reserved memory (firmware, integrated GPU, memory-mapped I/O)
- **WARNING**: Discrepancy 5-35GB - Possible single DIMM failure (verify with SEL)
- **CRITICAL**: Discrepancy ≥ 35GB - Multiple DIMMs likely failed

### System Reserved Memory

Not all installed memory is available to the OS. Typical reservations:

- Integrated graphics (if present): 1-2GB
- BIOS/firmware: 100-500MB
- Memory-mapped I/O: varies by configuration
- **Total typical: 2-4GB**

### Interpreting Discrepancies

Example with 16x 32GB DIMMs (512GB installed):

| OS Detected | Discrepancy | Interpretation |
|-------------|-------------|----------------|
| 510 GB      | 2 GB        | OK - System reserved |
| 480 GB      | 32 GB       | WARNING - 1 DIMM failed |
| 448 GB      | 64 GB       | CRITICAL - 2 DIMMs failed |
| 416 GB      | 96 GB       | CRITICAL - 3 DIMMs failed |

### SEL Entry Patterns

Look for these messages in SEL:

- ✗ "Memory device status is disabled" - DIMM failed POST
- ✗ "Memory configuration error" - Configuration issue
- ✗ "Memory training failure" - DIMM couldn't initialize
- ⚠ "Correctable memory error" - Soft error (not POST failure)

## Troubleshooting

### iDRAC Connection Failures

```
ERROR: Unable to access iDRAC at 192.168.10.101
```

**Solutions:**
1. Verify network connectivity: `ping 192.168.10.101`
2. Check HTTPS access: `curl -k https://192.168.10.101/redfish/v1/`
3. Verify credentials
4. Check iDRAC license (Enterprise recommended)
5. Ensure Redfish is enabled in iDRAC settings

### SSH Connection Failures

```
ERROR: Unable to access node ocp-worker-01 via SSH
```

**Solutions:**
1. Test SSH manually: `ssh core@192.168.1.101`
2. Check SSH key authentication
3. Verify ansible_user in inventory
4. Check firewall rules

### Python Interpreter Issues

```
ERROR: /usr/bin/python3 not found
```

**Solution:** Update inventory with correct Python path:
```yaml
dell_servers:
  vars:
    ansible_python_interpreter: /usr/bin/python3.9
```

### Permission Denied Reading /proc/meminfo

```
ERROR: Permission denied
```

**Solution:** `/proc/meminfo` is world-readable. If you get this error, check:
1. User has basic access to the system
2. No SELinux/AppArmor blocking access
3. Node is responsive (not in maintenance mode)

### Ansible Vault Issues

```
ERROR: Vault password was not provided
```

**Solution:** Use `--ask-vault-pass` flag:
```bash
ansible-playbook -i inventory.yml memory_audit.yml --ask-vault-pass
```

Or store password in file:
```bash
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook -i inventory.yml memory_audit.yml --vault-password-file .vault_pass
```

### No SEL Entries Found

If no SEL entries appear but discrepancy exists:

1. **SEL may have wrapped** - Old entries deleted as log filled
2. **SEL was cleared** - Someone cleared the log
3. **POST testing was disabled** - Check BIOS MemTest setting

**Mitigation:** Configure SEL forwarding to syslog for permanent retention.

## Customization

### Adjust Thresholds

Edit `memory_audit.yml`:

```yaml
vars:
  warning_threshold: 5    # Adjust based on your system reserved amounts
  critical_threshold: 35  # Adjust based on your DIMM sizes
```

### Change Report Directory

```bash
ansible-playbook -i inventory.yml memory_audit.yml -e "report_dir=/path/to/reports" --ask-vault-pass
```

### Add Email Notifications

Add mail task at the end of playbook:

```yaml
- name: Email critical server report
  mail:
    host: smtp.example.com
    to: sysadmin@example.com
    subject: "CRITICAL: Memory Validation Failures Detected"
    body: "{{ lookup('file', report_dir + '/CRITICAL_*.txt') }}"
  when: critical_count | int > 0
```

### Schedule Regular Audits

Create cron job:

```cron
# Weekly memory audit every Sunday at 2 AM
0 2 * * 0 cd /path/to/playbooks && ansible-playbook -i inventory.yml memory_audit.yml --vault-password-file .vault_pass
```

## What to Do If Failures Found

### Immediate Actions

1. **Document findings** - Save all reports
2. **Prioritize CRITICAL servers** - These have significant memory missing
3. **Check workloads** - Are affected servers running production workloads?
4. **Plan maintenance windows** - Memory replacement requires downtime

### Investigation Steps

1. **Review SEL entries** - Identify specific failed DIMM slots
2. **Physical inspection** - Check DIMM slot LEDs (often amber for failed)
3. **Verify DIMM seating** - Sometimes re-seating fixes issues
4. **Check warranty** - Dell ProSupport covers memory replacement

### Remediation

1. **Replace failed DIMMs** - Note specific slots from SEL
2. **Enable BIOS Memory Testing** - Prevent future deployments with bad RAM
3. **Re-run audit** - Verify fix
4. **Update documentation** - Track which servers were affected

### Prevention for New Deployments

Add to deployment checklist:

```bash
# Enable thorough memory testing in BIOS
racadm set BIOS.MemSettings.MemTest Enabled

# Verify memory after deployment
ansible-playbook -i inventory.yml memory_audit.yml --limit new-server
```

## Advanced Usage

### Integration with Tower/AWX

Import playbook into Ansible Tower/AWX:

1. Create Project pointing to repository
2. Create Job Template using `memory_audit.yml`
3. Configure inventory and credentials
4. Schedule regular runs
5. Set up notifications for CRITICAL results

### Export to Monitoring System

Parse CSV output and send to your monitoring:

```bash
# Example: Send metrics to Prometheus Pushgateway
cat reports/memory_audit_summary_*.csv | \
  awk -F, 'NR>1 {print "memory_discrepancy_gb{host=\""$1"\"} "$6}' | \
  curl --data-binary @- http://pushgateway:9091/metrics/job/memory_audit
```

### Parallel Execution

For very large fleets, use parallel execution:

```bash
ansible-playbook -i inventory.yml memory_audit.yml \
  --forks 20 \
  --ask-vault-pass
```

## Architecture Notes

### Why This Approach?

**Out-of-Band (iDRAC) + In-Band (OS) = Definitive Detection**

- iDRAC knows what's physically installed
- OS knows what's actually working
- Gap = Failed memory

### Why Not Just Check OS?

OS can't tell you what's missing because it never saw it. You need hardware perspective to know:
- How much memory *should* be there
- Which specific slots failed
- When failures occurred

### Why Not Just Check iDRAC?

iDRAC alone doesn't show OS perspective. You need OS check to confirm:
- Memory is actually available to applications
- System is using all operational memory
- No OS-level memory issues

## Files in This Directory

```
10_dell_memory_validation/
├── README.md                    # This file
├── memory_audit.yml             # Main playbook
├── requirements.yml             # Ansible Galaxy requirements
├── inventory.example.yml        # Example inventory template
├── vault.example.yml            # Example vault credentials
├── group_vars/                  # Variables directory
│   └── .gitkeep
└── reports/                     # Generated reports (created at runtime)
```

## References

- Dell iDRAC Redfish API: https://www.dell.com/support/kbdoc/en-us/000177182/
- Ansible Redfish Modules: https://docs.ansible.com/ansible/latest/collections/community/general/redfish_info_module.html
- DMTF Redfish Standard: https://www.dmtf.org/standards/redfish
- Red Hat CoreOS: https://docs.openshift.com/container-platform/latest/architecture/architecture-rhcos.html

## Contributing

Improvements welcome! Common enhancements:

- [ ] Add support for other vendors (HPE iLO, Lenovo XCC)
- [ ] HTML report generation
- [ ] Email notifications
- [ ] Slack/Teams webhooks
- [ ] Integration with CMDB
- [ ] Trending analysis over time

## License

This playbook is provided as-is for operational use. Modify as needed for your environment.

## Support

For issues or questions:
1. Review the Troubleshooting section above
2. Check Ansible verbose output: `ansible-playbook ... -vvv`
3. Verify iDRAC API access manually with curl
4. Review Dell documentation for your specific server model

---

**Created:** 2025-12-17  
**For:** Dell PowerEdge R650/R660 with Red Hat CoreOS/OpenShift  
**Tested:** Ansible 2.15+, community.general 8.0+


