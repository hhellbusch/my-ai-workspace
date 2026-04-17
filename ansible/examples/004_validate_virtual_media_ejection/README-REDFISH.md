# Virtual Media Validation Using Verified Redfish API

## Why This Version?

After reviewing the Ansible documentation, **we cannot confirm** that `dellemc.openmanage.idrac_system_info` returns VirtualMedia information. The official documentation does not explicitly list this in the return values.

This version uses the **well-documented and verified** `community.general.redfish_info` module which:

✅ Has documented return values
✅ Uses standard Redfish protocol  
✅ Works with iDRAC 7, 8, 9 (firmware 2.50+)
✅ Has predictable, tested behavior

## Prerequisites

### Install Required Collections

```bash
# Dell OpenManage collection (for idrac_virtual_media)
ansible-galaxy collection install dellemc.openmanage

# Community General collection (for redfish_info)
ansible-galaxy collection install community.general
```

### iDRAC Requirements

- iDRAC 7, 8, or 9
- Firmware version 2.50 or later (for Redfish support)
- Network access to iDRAC IP
- Valid credentials with virtual media privileges

## Files

- **`playbook_redfish.yml`** - Complete example using Redfish API
- **`simple_playbook_redfish.yml`** - Minimal example for quick reference
- **`VERIFICATION-ISSUE.md`** - Detailed explanation of the issue

## Usage

### Basic Usage

```bash
ansible-playbook playbook_redfish.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin"
```

### Specify Different Virtual Media Device

```bash
ansible-playbook playbook_redfish.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "media_device_id=RemovableDisk"  # For USB devices
```

## Virtual Media Device IDs

Common device IDs in iDRAC:

| Device ID | Description |
|-----------|-------------|
| `CD` | Virtual CD/DVD drive |
| `RemovableDisk` | Virtual USB drive |
| `Floppy` | Virtual floppy drive (older systems) |

To see all available devices:

```yaml
- name: List all virtual media devices
  community.general.redfish_info:
    baseuri: "{{ idrac_ip }}"
    username: "{{ idrac_user }}"
    password: "{{ idrac_password }}"
    category: Manager
    command: GetVirtualMedia
  register: result

- debug:
    var: result.redfish_facts.virtual_media.entries
```

## Return Value Structure

The `community.general.redfish_info` module with `GetVirtualMedia` command returns:

```yaml
redfish_facts:
  virtual_media:
    entries:
      - Id: "CD"
        Name: "Virtual CD"
        Description: "Virtual Removable Media"
        Image: ""  # URL of mounted image, or empty if ejected
        Inserted: false  # true if media is inserted, false if ejected
        MediaTypes:
          - CD
          - DVD
        WriteProtected: true
        ConnectedVia: "NotConnected"  # or "URI" if connected
        
      - Id: "RemovableDisk"
        Name: "Virtual USB"
        Description: "Virtual Removable Media"
        Image: ""
        Inserted: false
        MediaTypes:
          - USBStick
        WriteProtected: false
        ConnectedVia: "NotConnected"
```

## Validation Logic

The playbook validates ejection by checking:

1. **Inserted Status**: Must be `false`
2. **Image Field**: Must be empty, null, or undefined
3. **Retry Logic**: Polls status with configurable retries/delays

```yaml
until: >
  redfish_status.redfish_facts.virtual_media.entries | 
  selectattr('Id', 'equalto', media_device_id) | 
  map(attribute='Inserted') | first | default(true) == false
retries: 5
delay: 5
```

## Troubleshooting

### Error: "Module not found: community.general.redfish_info"

**Solution**: Install the community.general collection:
```bash
ansible-galaxy collection install community.general
```

### Error: "Redfish not supported by this iDRAC"

**Solution**: Your iDRAC firmware is too old. Upgrade to firmware 2.50+ or use the older WSMAN protocol (not covered here).

### Error: "Authentication failed"

**Solution**: 
1. Verify credentials are correct
2. Ensure user has sufficient privileges
3. Check if account is locked

### Validation times out but media appears ejected manually

**Solution**: Increase retry count or delay:
```bash
ansible-playbook playbook_redfish.yml \
  -e "max_validation_retries=10" \
  -e "validation_delay=10"
```

## Comparison: idrac_system_info vs Redfish API

| Aspect | idrac_system_info | redfish_info |
|--------|-------------------|--------------|
| VirtualMedia return | ❓ Not documented | ✅ Documented |
| Dell-specific | ✅ Yes | ❌ No (standard Redfish) |
| Documentation | ⚠️ Unclear for VM | ✅ Complete |
| Firmware support | All iDRAC versions | iDRAC 7+ (2.50+) |
| Recommendation | ⚠️ Untested | ✅ Recommended |

## Alternative: Check Return Value Only

If you don't want to install `community.general`, you can use a simpler approach that only checks the ejection command result:

```yaml
- name: Eject virtual media
  dellemc.openmanage.idrac_virtual_media:
    idrac_ip: "{{ idrac_ip }}"
    idrac_user: "{{ idrac_user }}"
    idrac_password: "{{ idrac_password }}"
    virtual_media:
      - index: 1
        state: "absent"
  register: eject_result

- name: Verify command succeeded
  assert:
    that:
      - not eject_result.failed
      - eject_result.changed or "No changes" in (eject_result.msg | default(''))
```

**Pros**: No extra collections needed  
**Cons**: Doesn't verify actual iDRAC state, only that command was accepted

## Testing Your iDRAC

To test what data structure YOUR specific iDRAC firmware returns:

```yaml
---
- name: Test Redfish virtual media query
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Query via Redfish
      community.general.redfish_info:
        baseuri: "{{ idrac_ip }}"
        username: "{{ idrac_user }}"
        password: "{{ idrac_password }}"
        category: Manager
        command: GetVirtualMedia
        validate_certs: false
      register: result

    - name: Show full structure
      debug:
        var: result
        verbosity: 0
```

Run with:
```bash
ansible-playbook test.yml -e "idrac_ip=YOUR_IP" -e "idrac_user=root" -e "idrac_password=PASSWORD"
```

## Summary

Use these Redfish-based playbooks for **production-ready, documented behavior**. The `idrac_system_info` based examples may work, but rely on undocumented behavior that varies by firmware version.

For questions or issues, refer to:
- [community.general.redfish_info documentation](https://docs.ansible.com/ansible/latest/collections/community/general/redfish_info_module.html)
- [Dell iDRAC Redfish API guide](https://www.dell.com/support/manuals/en-us/idrac9-lifecycle-controller-v3.x-series/idrac_3.00.00.00_redfishapiguide/)

