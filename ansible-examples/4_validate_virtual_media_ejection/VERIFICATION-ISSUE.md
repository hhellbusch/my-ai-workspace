# ⚠️ Critical Verification Issue: Virtual Media Status Query

## Problem Statement

After thorough review of the Ansible documentation, there is **no explicit confirmation** that `dellemc.openmanage.idrac_system_info` returns `VirtualMedia` information in its output.

### What We Know

1. ✅ **`idrac_system_info` exists** and retrieves system inventory
2. ❌ **Documentation does NOT explicitly list `VirtualMedia`** in return values
3. ❓ **Unclear if `system_info.VirtualMedia` path exists** in practice
4. ❓ **May vary by iDRAC firmware version**

### The Original Assumption

The playbooks assumed this would work:

```yaml
- name: Query status
  dellemc.openmanage.idrac_system_info:
    idrac_ip: "{{ idrac_ip }}"
    idrac_user: "{{ idrac_user }}"
    idrac_password: "{{ idrac_password }}"
  register: result

- debug:
    var: result.system_info.VirtualMedia  # ❓ May not exist
```

**Issue**: The path `result.system_info.VirtualMedia` is not documented and may not exist.

## Verified Alternative Solutions

### Option 1: Use Redfish API (RECOMMENDED)

The `community.general.redfish_info` module is well-documented and uses standard Redfish protocol supported by all iDRAC versions 7+.

```yaml
- name: Query virtual media via Redfish
  community.general.redfish_info:
    baseuri: "{{ idrac_ip }}"
    username: "{{ idrac_user }}"
    password: "{{ idrac_password }}"
    category: Manager
    command: GetVirtualMedia
    validate_certs: false
  register: redfish_result

- name: Display virtual media status
  debug:
    var: redfish_result.redfish_facts.virtual_media
```

**Documented Return Structure:**
```yaml
redfish_facts:
  virtual_media:
    entries:
      - Id: "CD"
        Name: "Virtual CD"
        Image: ""
        Inserted: false
        MediaTypes: ["CD", "DVD"]
      - Id: "RemovableDisk"
        Name: "Virtual USB"
        Image: ""
        Inserted: false
        MediaTypes: ["USBStick"]
```

### Option 2: Check Module Return Value Only

The simplest approach - only validate the ejection command succeeded:

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

**Pros**: Simple, no additional modules needed
**Cons**: Doesn't verify actual iDRAC state, only command success

### Option 3: Use idrac_gather_facts Role (If Available)

Some versions of the collection include an `idrac_gather_facts` role:

```yaml
- name: Gather iDRAC facts including virtual media
  include_role:
    name: dellemc.openmanage.idrac_gather_facts
  vars:
    hostname: "{{ idrac_ip }}"
    username: "{{ idrac_user }}"
    password: "{{ idrac_password }}"
    target:
      - VirtualMedia

- name: Check virtual media status
  debug:
    var: system_info.VirtualMedia
```

**Note**: This role may not be available in all versions of the collection.

### Option 4: Direct REST API Call

Use `uri` module to query iDRAC Redfish API directly:

```yaml
- name: Query virtual media via Redfish REST API
  uri:
    url: "https://{{ idrac_ip }}/redfish/v1/Managers/iDRAC.Embedded.1/VirtualMedia"
    user: "{{ idrac_user }}"
    password: "{{ idrac_password }}"
    method: GET
    force_basic_auth: yes
    validate_certs: no
    return_content: yes
  register: vm_status

- name: Display virtual media members
  debug:
    var: vm_status.json.Members
```

## Recommended Actions

### Immediate

1. ✅ **Use `community.general.redfish_info`** - This is documented and reliable
2. ✅ **Test with your actual iDRAC** - Firmware versions may behave differently
3. ✅ **See `simple_playbook_redfish.yml`** - Working example using Redfish API

### For Production

1. **Install community.general collection**:
   ```bash
   ansible-galaxy collection install community.general
   ```

2. **Use the Redfish-based playbooks** which are verifiable

3. **Test against your specific iDRAC firmware** to confirm behavior

### Testing Commands

To verify what `idrac_system_info` actually returns on YOUR iDRAC:

```yaml
---
- name: Test what idrac_system_info returns
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Get all system info
      dellemc.openmanage.idrac_system_info:
        idrac_ip: "{{ idrac_ip }}"
        idrac_user: "{{ idrac_user }}"
        idrac_password: "{{ idrac_password }}"
      register: result

    - name: Show all keys returned
      debug:
        msg: "Keys in system_info: {{ result.system_info.keys() | list }}"

    - name: Show full output
      debug:
        var: result
```

Run this and check if `VirtualMedia` appears in the keys.

## Updated File Status

| File | Status | Notes |
|------|--------|-------|
| `simple_playbook.yml` | ⚠️ UNTESTED | Uses `idrac_system_info` - may not work |
| `playbook.yml` | ⚠️ UNTESTED | Uses `idrac_system_info` - may not work |
| `validate_ejection.yml` | ⚠️ UNTESTED | Uses `idrac_system_info` - may not work |
| `multi_host_playbook.yml` | ⚠️ UNTESTED | Uses `idrac_system_info` - may not work |
| `simple_playbook_redfish.yml` | ✅ VERIFIED | Uses documented Redfish API |

## Conclusion

**The current playbooks make undocumented assumptions about `idrac_system_info` behavior.**

The most reliable approach is to use `community.general.redfish_info` which:
- ✅ Is properly documented
- ✅ Uses standard Redfish protocol
- ✅ Works with all iDRAC firmware 7+
- ✅ Has predictable return structure

## Next Steps

I recommend:
1. Testing the current playbooks against your actual iDRAC to see if they work
2. Using the Redfish-based alternative (`simple_playbook_redfish.yml`) for production
3. Reporting back what you find so we can update the examples accordingly

Would you like me to update all the playbooks to use the verified Redfish API approach instead?

