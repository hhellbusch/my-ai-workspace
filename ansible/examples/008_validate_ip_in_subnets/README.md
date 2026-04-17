# IP Subnet Validation with Ansible

This example demonstrates how to validate that IP addresses belong to specific subnets using Ansible. This is useful for:
- Network security audits
- Validating server deployments
- Ensuring IPs comply with network policies
- Pre-deployment checks

## Prerequisites

Install the required Ansible collection:

```bash
ansible-galaxy collection install ansible.utils
```

Or use the requirements file:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Examples

### 1. Simple Validation (`simple_playbook.yml`)

Basic example showing how to check if IPs are in allowed subnets:

```bash
ansible-playbook simple_playbook.yml
```

**What it does:**
- Defines a list of allowed subnets
- Defines a list of IP addresses to check
- Validates each IP against the subnets
- Shows validation results

### 2. Complete Validation (`complete_validation.yml`)

More sophisticated example with detailed reporting:

```bash
ansible-playbook complete_validation.yml
```

**Features:**
- Simple flat lists for subnets and IPs
- Detailed validation report showing which subnet(s) each IP matches
- Summary statistics
- **Automatically fails if any invalid IPs are found**

**Note:** The playbook will display all validation results before failing, so you can see both valid and invalid IPs in the output.

### 3. Practical Example (`practical_example.yml`)

Real-world usage pattern:

```bash
ansible-playbook practical_example.yml
```

**Shows:**
- How to structure data for real scenarios
- Filtering valid vs invalid IPs
- Creating deployment-ready IP lists
- Optional assertion for enforcement

## How It Works

The examples use the `ansible.utils.ipaddr` filter which:
- Takes an IP address or subnet as input
- Can check if an IP belongs to a subnet
- Returns the IP if it matches, empty string if not

### Basic Pattern

```yaml
# Check if IP is in subnet
{{ '10.1.50.10' | ansible.utils.ipaddr('10.1.0.0/16') }}
# Returns: '10.1.50.10' if in subnet, '' if not

# Check if IP is in any subnet from a list
{{ subnets | map('ansible.utils.ipaddr', '10.1.50.10') | select() | list }}
# Returns: list of matching subnets (empty if no matches)
```

## Common Use Cases

### 1. Pre-Deployment Validation

Validate that all server IPs are in approved networks before deployment:

```yaml
- name: Validate deployment IPs
  ansible.builtin.assert:
    that:
      - approved_subnets | map('ansible.utils.ipaddr', item.ip) | select() | list | length > 0
    fail_msg: "IP {{ item.ip }} not in approved subnets"
  loop: "{{ servers_to_deploy }}"
```

### 2. Security Audit

Find servers with IPs outside approved ranges:

```yaml
- name: Audit server IPs
  ansible.builtin.set_fact:
    unauthorized_servers: >-
      {{
        all_servers | 
        rejectattr('ip', 'ansible.utils.ipaddr', approved_subnets) |
        list
      }}
```

### 3. Network Compliance Check

Regular compliance checks for network policies:

```yaml
- name: Check compliance
  ansible.builtin.assert:
    that:
      - corporate_subnets | map('ansible.utils.ipaddr', ansible_default_ipv4.address) | select() | list | length > 0
    fail_msg: "Host {{ inventory_hostname }} is not in corporate network"
  when: ansible_default_ipv4.address is defined
```

## Loading Data from External Sources

### From Inventory Variables

```yaml
# inventory.yml
all:
  vars:
    allowed_subnets:
      - "10.0.0.0/8"
      - "172.16.0.0/12"
  
  hosts:
    server1:
      ansible_host: 10.1.50.10
    server2:
      ansible_host: 192.168.1.100
```

```yaml
# playbook.yml
- hosts: all
  tasks:
    - name: Validate host IP
      ansible.builtin.assert:
        that:
          - allowed_subnets | map('ansible.utils.ipaddr', ansible_host) | select() | list | length > 0
```

### From Variable File

```yaml
# playbook.yml
- hosts: localhost
  vars_files:
    - network_config.yml
  tasks:
    - name: Validate IPs from config
      # ... validation tasks
```

### From API or Dynamic Source

```yaml
- name: Get approved subnets from API
  ansible.builtin.uri:
    url: "https://api.example.com/networks/approved"
    return_content: yes
  register: api_response

- name: Validate against dynamic subnets
  ansible.builtin.set_fact:
    is_valid: "{{ api_response.json.subnets | map('ansible.utils.ipaddr', my_ip) | select() | list | length > 0 }}"
```

## Tips and Best Practices

1. **Use descriptive names** for subnets and IPs to make reports clearer

2. **Separate validation from enforcement** - validate first, then decide whether to fail

3. **Log validation results** for audit trails:
   ```yaml
   - name: Log validation results
     ansible.builtin.copy:
       content: "{{ validation_report | to_nice_json }}"
       dest: "/var/log/ansible/ip_validation_{{ ansible_date_time.iso8601 }}.json"
   ```

4. **Handle edge cases**:
   - Empty IP lists
   - Invalid IP formats
   - Missing subnet definitions

5. **Performance** - For large IP lists, consider:
   - Batching validations
   - Using async tasks
   - Caching subnet lists

## Troubleshooting

### Collection not found
```
ERROR! couldn't resolve module/action 'ansible.utils.ipaddr'
```

**Solution:** Install the ansible.utils collection:
```bash
ansible-galaxy collection install ansible.utils
```

### Filter returns unexpected results

Test the filter directly:
```bash
ansible localhost -m debug -a "msg={{ '10.1.50.10' | ansible.utils.ipaddr('10.1.0.0/16') }}"
```

### Python netaddr library missing

The `ansible.utils` collection requires the `netaddr` library:
```bash
pip install netaddr
```

## Further Reading

- [Ansible Utils Collection Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/utils/)
- [netaddr Library Documentation](https://netaddr.readthedocs.io/)
- [Ansible Filters Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html)

## Related Examples

See also:
- Example 4: Validate virtual media ejection (server validation)
- Example 5: Block rescue retry (error handling patterns)
- Example 6: Parallel execution (scaling validation checks)

