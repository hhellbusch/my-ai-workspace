# Monitor ISO Boot and Installation

This directory contains Ansible playbooks for monitoring system status during ISO boot and installation via Redfish API (iDRAC, iLO, etc.).

## Overview

When booting servers from ISO for installation (CoreOS, RHCOS, etc.), you need to monitor the boot process to know when installation completes. These playbooks poll the BMC (iDRAC) via Redfish API and display real-time status.

## Files

### Using Direct Redfish API (URI Module)

| File | Purpose | Complexity |
|------|---------|------------|
| `simple_monitor.yml` | Basic polling with URI module | ⭐ Simple |
| `monitor_system_status.yml` | Multiple monitoring strategies (URI) | ⭐⭐ Medium |
| `monitor_iteration.yml` | Reusable monitoring task (URI) | ⭐⭐ Helper |
| `complete_iso_boot.yml` | Full workflow with URI | ⭐⭐⭐ Complete |

### Using Redfish Module (Recommended)

| File | Purpose | Complexity | Display |
|------|---------|------------|---------|
| `simple_monitor_module.yml` | Basic polling with redfish_info module | ⭐ Simple | Live |
| `simple_monitor_live.yml` | Live monitoring with include_tasks | ⭐ Simple | Live |
| `monitor_live_advanced.yml` | Advanced live monitoring (system + media) | ⭐⭐ Medium | Live |
| `monitor_with_module.yml` | Advanced monitoring with redfish_info | ⭐⭐ Medium | Batch |
| `monitor_iteration_module.yml` | Reusable monitoring task (module) | ⭐⭐ Helper | - |
| `wait_for_condition_module.yml` | Wait for specific conditions | ⭐⭐ Flexible | Live |
| `poll_and_display.yml` | Single poll iteration helper | ⭐ Helper | - |

## Quick Start

**Recommended: Start monitoring in 2 steps**

**Step 1: Create inventory**
```bash
cp inventory.example.yml inventory.yml
# Edit inventory.yml with your BMC details (IP, username, password)
```

**Step 2: Run live monitoring**
```bash
ansible-playbook -i inventory.yml simple_monitor_live.yml
```

This will poll your BMC every 10 seconds and display system status in real-time until installation completes.

**See [INVENTORY-GUIDE.md](INVENTORY-GUIDE.md) for complete inventory documentation.**

## Alternative Approaches

### Using Command-Line Variables

If you prefer not to create an inventory file, pass credentials directly:

```bash
ansible-playbook simple_monitor_live.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "iterations=60" \
  -e "interval=10"
```

### Advanced Monitoring Options

**Monitor system + virtual media status:**
```bash
ansible-playbook -i inventory.yml monitor_live_advanced.yml
```

**Wait for specific conditions:**
```bash
# Wait for system to power on
ansible-playbook -i inventory.yml wait_for_condition_module.yml \
  -e "wait_condition=power_on"

# Wait for ISO to be ejected
ansible-playbook -i inventory.yml wait_for_condition_module.yml \
  -e "wait_condition=iso_ejected"

# Wait for complete installation
ansible-playbook -i inventory.yml wait_for_condition_module.yml \
  -e "wait_condition=installation_complete"
```

**Complete ISO boot workflow:**
```bash
ansible-playbook -i inventory.yml complete_iso_boot.yml \
  -e "iso_url=http://server.example.com/rhcos.iso" \
  -e "expected_server_ip=192.168.1.50"
```

### Using Direct API (URI Module)

If you don't have the `community.general` collection installed:

```bash
ansible-playbook simple_monitor.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "iterations=60" \
  -e "interval=10"
```

## What Gets Monitored

### System Status

- **Power State**: Off, On, PoweringOn, PoweringOff
- **Health Status**: OK, Warning, Critical
- **System State**: Enabled, Disabled, StandbyOffline
- **Boot Source**: None, Cd, Hdd, Pxe, etc.

### Virtual Media Status (ISO)

- **Inserted**: Whether ISO is mounted
- **Image**: URL/path of mounted image
- **ConnectedVia**: URI, NotConnected

## Installation Completion Indicators

The playbooks check for these conditions to determine when installation is complete:

1. ✅ **ISO ejected** - `Inserted: false`
2. ✅ **Boot source changed** - No longer booting from CD
3. ✅ **System powered on** - `PowerState: On`
4. ✅ **Network accessible** - SSH port responds (if IP known)

## Prerequisites

### Quick Setup

```bash
# Install required collections
ansible-galaxy collection install -r requirements.yml

# Or install individually
ansible-galaxy collection install community.general

# Verify installation
./check_setup.sh
```

**See [SETUP-GUIDE.md](SETUP-GUIDE.md) for complete installation instructions and troubleshooting.**

### Required Collections

```bash
# Community collection for Redfish support (REQUIRED for module-based playbooks)
ansible-galaxy collection install community.general

# Dell OpenManage collection (optional, for Dell-specific features)
ansible-galaxy collection install dellemc.openmanage
```

### Which Approach to Use?

| Approach | Pros | Cons | Use When |
|----------|------|------|----------|
| **Module** (`redfish_info`) | ✅ Clean syntax<br>✅ Abstracted<br>✅ Portable | ⚠️ Requires collection<br>⚠️ Module limitations | General use, cleaner code |
| **Direct API** (`uri`) | ✅ Full control<br>✅ No dependencies<br>✅ All endpoints | ⚠️ More verbose<br>⚠️ Manual parsing | Troubleshooting, custom endpoints |

### BMC Requirements

- Redfish API support (iDRAC 7+, iLO 4+, etc.)
- Network access to BMC IP
- Valid credentials with appropriate permissions

### iDRAC Firmware

- iDRAC 7/8/9: Firmware 2.50 or later
- Verify Redfish endpoint: `https://IDRAC_IP/redfish/v1/`

## Output Examples

### Simple Monitor Output

```
================================================
Poll 5/60 - 14:23:45
================================================
Power State:  On
Health:       OK
State:        Enabled
Boot Source:  Cd
Boot Enabled: Once
================================================
```

### Detailed Monitor Output

```
========================================================
Poll #12 - 2025-12-04 14:25:30
========================================================
SYSTEM:
  Power State:       On
  System Health:     OK
  System State:      Enabled
  Boot Source:       Cd
  Boot Enabled:      Once

VIRTUAL MEDIA (ISO):
  Inserted:          true
  Image:             http://server.example.com/rhcos.iso
  Connected Via:     URI

INDICATORS:
  ✅ System powered on
  📀 ISO mounted
  💿 Booting from Cd
========================================================
```

## Customization

### Adjust Polling Interval

```yaml
vars:
  poll_interval: 15  # Poll every 15 seconds
  max_iterations: 80 # For up to 20 minutes (80 * 15s)
```

### Monitor Specific Conditions

```yaml
until: >
  system_status.json.PowerState == "On" and
  system_status.json.Boot.BootSourceOverrideTarget != "Cd"
```

### Add Custom Checks

```yaml
- name: Check for specific BIOS version
  ansible.builtin.debug:
    msg: "BIOS version: {{ system_status.json.BiosVersion }}"
  when: system_status.json.BiosVersion is version('2.8.0', '>=')
```

## Troubleshooting

### Error: "Failed to connect to Redfish API"

**Check connectivity:**
```bash
curl -k -u root:calvin https://192.168.1.100/redfish/v1/
```

**Solutions:**
- Verify BMC IP address is correct
- Check network connectivity
- Verify BMC is powered on
- Check firewall rules

### Error: "Authentication failed"

**Solutions:**
- Verify credentials are correct
- Check user has appropriate privileges in BMC
- Try resetting BMC user password

### Wrong System Path

Some BMCs use different system paths. Check with:

```bash
curl -k -u root:calvin https://IDRAC_IP/redfish/v1/Systems/ | jq
```

Look for the actual system ID and update the playbook:
```yaml
url: "https://{{ idrac_ip }}/redfish/v1/Systems/YOUR_SYSTEM_ID"
```

### No Virtual Media Data

If virtual media endpoint doesn't exist:

```bash
# List available virtual media devices
curl -k -u root:calvin https://IDRAC_IP/redfish/v1/Managers/iDRAC.Embedded.1/VirtualMedia/ | jq
```

Common device IDs:
- `CD` - Virtual CD/DVD
- `RemovableDisk` - Virtual USB

## Redfish API Reference

### Useful Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/redfish/v1/` | Service root |
| `/redfish/v1/Systems/` | List compute systems |
| `/redfish/v1/Systems/System.Embedded.1` | System details |
| `/redfish/v1/Managers/` | List managers (iDRAC) |
| `/redfish/v1/Managers/iDRAC.Embedded.1/VirtualMedia/` | Virtual media |

### Manual Testing

```bash
# Get system status
curl -sk -u root:calvin \
  https://192.168.1.100/redfish/v1/Systems/System.Embedded.1 | jq

# Get virtual media status
curl -sk -u root:calvin \
  https://192.168.1.100/redfish/v1/Managers/iDRAC.Embedded.1/VirtualMedia/CD | jq

# Watch power state
watch -n 5 'curl -sk -u root:calvin \
  https://192.168.1.100/redfish/v1/Systems/System.Embedded.1 | \
  jq -r ".PowerState"'
```

## Best Practices

1. **Start with simple_monitor.yml** - Verify connectivity and data structure
2. **Use appropriate timeouts** - ISO installations can take 20-30 minutes
3. **Monitor multiple indicators** - Don't rely on just one check
4. **Handle errors gracefully** - Use `failed_when: false` for monitoring
5. **Log output** - Redirect to file for later analysis

## Example: Complete Workflow

```bash
# 1. Mount ISO
ansible-playbook mount_iso.yml -e "idrac_ip=192.168.1.100" ...

# 2. Power on and set boot device
ansible-playbook boot_from_iso.yml -e "idrac_ip=192.168.1.100" ...

# 3. Monitor installation (this runs until complete)
ansible-playbook simple_monitor.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "iterations=120" \
  -e "interval=15"

# 4. Verify installation
ssh core@192.168.1.50 "rpm-ostree status"
```

## See Also

- [Ansible redfish_info module](https://docs.ansible.com/ansible/latest/collections/community/general/redfish_info_module.html)
- [Dell iDRAC Redfish API Guide](https://www.dell.com/support/manuals/en-us/idrac9-lifecycle-controller-v3.x-series/)
- [DMTF Redfish Specification](https://www.dmtf.org/standards/redfish)

