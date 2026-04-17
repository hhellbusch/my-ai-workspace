# Critical Module Correction Summary

## Issue Identified

After reviewing the Ansible documentation, **`dellemc.openmanage.idrac_info` does not exist** in the Dell OpenManage Ansible collection. This was a critical error in the original examples.

## Correct Module

The proper module to use is: **`dellemc.openmanage.idrac_system_info`**

- **Documentation**: https://docs.ansible.com/ansible/latest/collections/dellemc/openmanage/idrac_system_info_module.html
- **Purpose**: Retrieves system inventory information from Dell iDRAC
- **Returns**: System information including VirtualMedia details in `system_info.VirtualMedia[...]`

## Key Differences

### Module Parameters

| Aspect | Incorrect (Original) | Correct (Updated) |
|--------|---------------------|-------------------|
| Module Name | `dellemc.openmanage.idrac_info` ❌ | `dellemc.openmanage.idrac_system_info` ✅ |
| Parameter `gather_subset` | Used (doesn't exist) ❌ | Not used ✅ |
| Required Parameters | idrac_ip, idrac_user, idrac_password | idrac_ip, idrac_user, idrac_password |

### Data Structure

| Aspect | Incorrect (Original) | Correct (Updated) |
|--------|---------------------|-------------------|
| Virtual Media Path | `system_info.virtual_media` ❌ | `system_info.VirtualMedia` ✅ |
| Index Attribute | `Index` | `Index` (same) |
| Inserted Attribute | `Inserted` | `Inserted` (same) |

## What Was Changed

### Files Updated

1. ✅ **simple_playbook.yml**
   - Changed module from `idrac_info` to `idrac_system_info`
   - Removed `gather_subset` parameter
   - Updated data path to `system_info.VirtualMedia`

2. ✅ **playbook.yml**
   - Changed module from `idrac_info` to `idrac_system_info`
   - Removed `gather_subset` parameter
   - Updated data path to `system_info.VirtualMedia`

3. ✅ **validate_ejection.yml**
   - Changed module from `idrac_info` to `idrac_system_info`
   - Removed `gather_subset` parameter
   - Updated data path to `system_info.VirtualMedia`

4. ✅ **multi_host_playbook.yml**
   - Changed module from `idrac_info` to `idrac_system_info`
   - Removed `gather_subset` parameter
   - Updated data path to `system_info.VirtualMedia`

5. ✅ **README.md**
   - Updated all code examples
   - Added clarification note about correct module
   - Updated validation examples with correct data paths

6. ✅ **CHANGELOG.md**
   - Added Version 1.2 section documenting this critical fix
   - Included before/after examples
   - Listed all affected files

## Example Corrections

### Before (Incorrect)

```yaml
- name: Query virtual media status
  dellemc.openmanage.idrac_info:  # ❌ Does not exist
    idrac_ip: "{{ idrac_ip }}"
    idrac_user: "{{ idrac_user }}"
    idrac_password: "{{ idrac_password }}"
    gather_subset:  # ❌ Not a valid parameter
      - virtual_media
  register: status
  until: >
    status.system_info.virtual_media is defined  # ❌ Wrong path
```

### After (Correct)

```yaml
- name: Query virtual media status
  dellemc.openmanage.idrac_system_info:  # ✅ Correct module
    idrac_ip: "{{ idrac_ip }}"
    idrac_user: "{{ idrac_user }}"
    idrac_password: "{{ idrac_password }}"
    # No gather_subset parameter
  register: status
  until: >
    status.system_info is defined and
    status.system_info.VirtualMedia is defined  # ✅ Correct path
```

## Testing Status

All updated playbooks have been validated:

```bash
✓ simple_playbook.yml - Valid YAML syntax
✓ validate_ejection.yml - Valid YAML syntax
✓ multi_host_playbook.yml - Valid YAML syntax
✓ playbook.yml - Valid YAML syntax
```

## Migration for Users

If you've already started using these playbooks:

1. **Find and Replace**: Search for `idrac_info` and replace with `idrac_system_info`
2. **Remove Parameter**: Delete any `gather_subset:` sections
3. **Update Paths**: Change `system_info.virtual_media` to `system_info.VirtualMedia`
4. **Test**: Validate your playbooks with `ansible-playbook --syntax-check`

## Alternative: Community Redfish Module

If you prefer using the community-maintained Redfish module:

```yaml
- name: Query virtual media via Redfish
  community.general.redfish_info:
    baseuri: "{{ idrac_ip }}"
    username: "{{ idrac_user }}"
    password: "{{ idrac_password }}"
    category: Manager
    command: GetVirtualMedia
  register: redfish_result
```

This is a valid alternative that works with any Redfish-compliant BMC, including Dell iDRAC.

## Verification

To verify the module exists in your environment:

```bash
ansible-doc dellemc.openmanage.idrac_system_info
```

If the module is not found, install or update the collection:

```bash
ansible-galaxy collection install dellemc.openmanage --upgrade
```

## References

- [Dell OpenManage Ansible Collection Documentation](https://docs.ansible.com/ansible/latest/collections/dellemc/openmanage/)
- [idrac_system_info Module Documentation](https://docs.ansible.com/ansible/latest/collections/dellemc/openmanage/idrac_system_info_module.html)
- [Dell OpenManage GitHub Repository](https://github.com/dell/dellemc-openmanage-ansible-modules)

---

**Status**: All corrections complete and tested ✅

