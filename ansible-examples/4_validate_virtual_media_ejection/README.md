# Example 4: Validate Virtual Media Ejection from Dell iDRAC

This example demonstrates how to eject virtual media from a Dell iDRAC endpoint and validate that the ejection was successful.

## Overview

When working with Dell iDRAC virtual media, it's important to verify that operations complete successfully. This example shows multiple methods to validate virtual media ejection:

1. **Method 1**: Check the return value from the ejection module
2. **Method 2**: Query the actual virtual media status and validate
3. **Method 3**: Use reusable validation tasks

> **Important**: This example uses `dellemc.openmanage.idrac_system_info` to query virtual media status. The module returns system inventory data in the structure `system_info.VirtualMedia[...]`.

## Files

- `playbook.yml` - Complete example with all validation methods
- `simple_playbook.yml` - Minimal example for quick reference
- `validate_ejection.yml` - Reusable validation tasks

## Prerequisites

### Required Ansible Collection

```bash
ansible-galaxy collection install dellemc.openmanage
```

### Required Variables

- `idrac_ip` - IP address or hostname of the iDRAC
- `idrac_user` - iDRAC username (typically 'root')
- `idrac_password` - iDRAC password

## Usage

### Basic Usage

```bash
ansible-playbook playbook.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin"
```

### Simple Version

```bash
ansible-playbook simple_playbook.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin"
```

### With Custom Media Index

```bash
ansible-playbook playbook.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "media_index=2"
```

### Using Vault for Credentials

1. Create a vault file:
```bash
ansible-vault create vars/idrac_credentials.yml
```

2. Add credentials:
```yaml
idrac_user: root
idrac_password: calvin
```

3. Run with vault:
```bash
ansible-playbook playbook.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "@vars/idrac_credentials.yml" \
  --ask-vault-pass
```

## Validation Methods Explained

### Method 1: Return Value Check

```yaml
- name: Eject virtual media
  dellemc.openmanage.idrac_virtual_media:
    virtual_media:
      - index: 1
        state: "absent"
  register: eject_result

- name: Verify ejection command succeeded
  assert:
    that:
      - eject_result.failed == false
      - eject_result.changed == true
```

**Pros**: Fast, simple
**Cons**: Only confirms the command was accepted, not that media is actually ejected

### Method 2: Status Query with Retry

```yaml
- name: Query virtual media status
  dellemc.openmanage.idrac_system_info:
    idrac_ip: "{{ idrac_ip }}"
    idrac_user: "{{ idrac_user }}"
    idrac_password: "{{ idrac_password }}"
  register: idrac_status
  until: >
    idrac_status.system_info.VirtualMedia is defined and
    (idrac_status.system_info.VirtualMedia[0].Inserted == false)
  retries: 5
  delay: 5

- name: Assert media is ejected
  assert:
    that:
      - target_media.Inserted == false
      - target_media.Image == ""
```

**Pros**: Verifies actual state, handles async operations
**Cons**: Slower, requires additional API call

### Method 3: Reusable Tasks (with Retry Logic)

```yaml
- name: Use separate validation task file
  include_tasks: validate_ejection.yml
  vars:
    media_index: 1
    max_validation_retries: 5
    validation_delay: 5
```

**Pros**: Reusable, maintainable, consistent, includes robust retry logic
**Cons**: Requires separate file management

**Note**: The reusable task file now includes built-in retry logic, making it just as robust as Method 2.

## Virtual Media Status Fields

When querying virtual media status, you'll get information like:

```json
{
  "Index": 1,
  "MediaTypes": ["CD", "DVD"],
  "Inserted": false,
  "Image": "",
  "ConnectedVia": "NotConnected",
  "WriteProtected": true
}
```

Key fields for validation:
- `Inserted`: Should be `false` when ejected
- `Image`: Should be empty string or null when ejected
- `ConnectedVia`: Should be "NotConnected" when ejected

## Customization

You can customize the validation behavior by adjusting these variables in `playbook.yml`:

```yaml
vars:
  media_index: 1                    # Which virtual media device (1=CD/DVD, 2=Floppy)
  max_validation_retries: 5         # How many times to retry validation
  validation_delay: 5               # Seconds between retries
  validate_certs: false             # SSL certificate validation
```

## Error Handling

The playbook includes comprehensive error handling:

- **Ejection Failure**: Logs error details and optionally continues
- **Validation Timeout**: Fails after max retries with detailed status
- **Network Issues**: Displays connection errors clearly

## Important Implementation Notes

### Correct Index Filtering

When validating virtual media status, always filter by the specific media index rather than assuming array position:

**❌ Incorrect (brittle):**
```yaml
until: status.system_info.VirtualMedia[0].Inserted == false
```

**✅ Correct (robust):**
```yaml
until: >
  status.system_info is defined and
  status.system_info.VirtualMedia is defined and
  (status.system_info.VirtualMedia | 
   selectattr('Index', 'equalto', 1) | 
   map(attribute='Inserted') | first | default(true) == false)
```

The incorrect approach assumes the first item in the array is always your target device, but iDRAC may return devices in any order.

### Retry Logic for Async Operations

Virtual media operations may take time to complete on the iDRAC side. Always use `until`/`retries`/`delay` when querying status after an operation:

```yaml
register: status
until: <condition>
retries: 5
delay: 5
```

This gives the iDRAC time to process the operation and update its internal state.

## Common Issues

### Issue: "Module not found"
**Solution**: Install the collection:
```bash
ansible-galaxy collection install dellemc.openmanage
```

### Issue: "Validation fails but media appears ejected"
**Solution**: Increase `validation_delay` to give iDRAC more time to update status

### Issue: "SSL Certificate verification failed"
**Solution**: Set `validate_certs: false` (or properly configure SSL certs)

### Issue: "Authentication failed"
**Solution**: Verify credentials and ensure iDRAC user has sufficient permissions

## Integration with CI/CD

This playbook can be integrated into CI/CD pipelines for automated testing:

```bash
# Example GitLab CI job
validate_media_ejection:
  script:
    - ansible-playbook playbook.yml 
        -e "idrac_ip=$IDRAC_IP" 
        -e "idrac_user=$IDRAC_USER" 
        -e "idrac_password=$IDRAC_PASSWORD"
  only:
    - schedules
```

## Related Examples

- **Example 1** (`1_retry_on_timeout`): Retry logic patterns
- **Example 2** (`2_log_ignored_errors`): Error logging strategies
- **Example 3** (`3_conditional_block`): Conditional execution blocks

## Further Reading

- [Dell OpenManage Ansible Modules Documentation](https://github.com/dell/dellemc-openmanage-ansible-modules)
- [iDRAC Virtual Media REST API](https://developer.dell.com/apis/2978/versions/6.xx/docs/1Introduction/1Overview.md)
- [Ansible Assert Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assert_module.html)
- [Ansible Until/Retry Logic](https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html#retrying-a-task-until-a-condition-is-met)

