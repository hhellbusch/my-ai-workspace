# IP Subnet Validation - Quick Reference

## Installation

```bash
ansible-galaxy collection install ansible.utils
pip install netaddr
```

## Basic Patterns

### Check if single IP is in subnet

```yaml
- name: Check if IP is in subnet
  ansible.builtin.debug:
    msg: "{{ '10.1.50.10' | ansible.utils.ipaddr('10.1.0.0/16') }}"
  # Returns: '10.1.50.10' if in subnet, '' if not
```

### Check if IP is in any subnet from list

```yaml
- name: Check against multiple subnets
  ansible.builtin.set_fact:
    is_valid: "{{ subnets | map('ansible.utils.ipaddr', my_ip) | select() | list | length > 0 }}"
```

### Validate list of IPs

```yaml
- name: Validate multiple IPs
  ansible.builtin.set_fact:
    validation_results: >-
      {{
        validation_results | default({}) | combine({
          item: subnets | map('ansible.utils.ipaddr', item) | select() | list | length > 0
        })
      }}
  loop: "{{ ip_list }}"
```

### Filter valid IPs only

```yaml
- name: Get only valid IPs
  ansible.builtin.set_fact:
    valid_ips: "{{ all_ips | select('ansible.utils.ipaddr', my_subnet) | list }}"
```

### Assert IP is valid (fail if not)

```yaml
- name: Enforce IP validation
  ansible.builtin.assert:
    that:
      - subnets | map('ansible.utils.ipaddr', item) | select() | list | length > 0
    fail_msg: "IP {{ item }} not in allowed subnets"
  loop: "{{ ips_to_check }}"
```

## Common Use Cases

### Pre-Deployment Check

```yaml
- name: Validate deployment IPs
  hosts: servers_to_deploy
  vars:
    approved_subnets:
      - "10.0.0.0/8"
      - "172.16.0.0/12"
  tasks:
    - name: Check if host IP is approved
      ansible.builtin.assert:
        that:
          - approved_subnets | map('ansible.utils.ipaddr', ansible_host) | select() | list | length > 0
        fail_msg: "Host {{ inventory_hostname }} IP {{ ansible_host }} not in approved networks"
```

### Security Audit

```yaml
- name: Find unauthorized IPs
  ansible.builtin.set_fact:
    unauthorized_ips: >-
      {{
        all_server_ips |
        reject('ansible.utils.ipaddr', corporate_subnets) |
        list
      }}

- name: Report unauthorized servers
  ansible.builtin.debug:
    msg: "WARNING: {{ unauthorized_ips | length }} servers outside corporate networks"
  when: unauthorized_ips | length > 0
```

### Create Approval List

```yaml
- name: Filter IPs for deployment
  ansible.builtin.set_fact:
    approved_for_deployment: >-
      {{
        candidate_ips |
        select('ansible.utils.ipaddr', prod_subnets) |
        list
      }}
```

## Complete Validation Function

```yaml
- name: Complete IP validation
  block:
    - name: Validate each IP
      ansible.builtin.set_fact:
        ip_report: >-
          {{
            ip_report | default([]) + [{
              'ip': item,
              'valid': allowed_subnets | map('ansible.utils.ipaddr', item) | select() | list | length > 0,
              'matching_subnets': allowed_subnets | select('ansible.utils.ipaddr', item) | list
            }]
          }}
      loop: "{{ ips_to_check }}"
    
    - name: Separate valid and invalid
      ansible.builtin.set_fact:
        valid_ips: "{{ ip_report | selectattr('valid', 'equalto', true) | map(attribute='ip') | list }}"
        invalid_ips: "{{ ip_report | selectattr('valid', 'equalto', false) | map(attribute='ip') | list }}"
    
    - name: Display results
      ansible.builtin.debug:
        msg:
          - "Valid: {{ valid_ips }}"
          - "Invalid: {{ invalid_ips }}"
```

## Loading Data

### From Inventory

```yaml
# inventory.yml
all:
  vars:
    allowed_subnets: ["10.0.0.0/8"]
  hosts:
    server1:
      ansible_host: 10.1.50.10
```

### From Variable File

```yaml
# playbook.yml
- hosts: localhost
  vars_files:
    - network_config.yml  # Contains: allowed_subnets: [...]
```

### From API

```yaml
- name: Get subnets from API
  ansible.builtin.uri:
    url: "https://api.example.com/networks"
  register: api_response

- name: Use dynamic subnets
  ansible.builtin.set_fact:
    subnets: "{{ api_response.json.subnets }}"
```

## Conditional Logic

### Only validate if IP is defined

```yaml
when: ansible_host is defined and ansible_host | length > 0
```

### Skip validation for specific hosts

```yaml
when: inventory_hostname not in skip_validation_hosts
```

### Different subnets per environment

```yaml
- name: Set environment-specific subnets
  ansible.builtin.set_fact:
    allowed_subnets: "{{ prod_subnets if env == 'production' else dev_subnets }}"
```

## Error Handling

### Graceful failure

```yaml
- name: Validate with error handling
  block:
    - name: Check IP validity
      ansible.builtin.assert:
        that:
          - subnets | map('ansible.utils.ipaddr', item) | select() | list | length > 0
      loop: "{{ ips }}"
  rescue:
    - name: Log validation failure
      ansible.builtin.debug:
        msg: "Validation failed - check logs"
```

### Continue on error

```yaml
ignore_errors: true
register: validation_result

- name: Handle failures later
  when: validation_result is failed
```

## Performance Tips

### Batch processing for large lists

```yaml
- name: Process in batches
  ansible.builtin.include_tasks: validate_batch.yml
  loop: "{{ ip_list | batch(100) | list }}"
  loop_control:
    loop_var: ip_batch
```

### Cache subnet list

```yaml
- name: Cache subnets
  ansible.builtin.set_fact:
    cached_subnets: "{{ lookup('file', 'subnets.json') | from_json }}"
    cacheable: yes
```

## Troubleshooting

### Test filter directly

```bash
ansible localhost -m debug -a "msg={{ '10.1.50.10' | ansible.utils.ipaddr('10.1.0.0/16') }}"
```

### Check collection is installed

```bash
ansible-galaxy collection list | grep ansible.utils
```

### Verify netaddr library

```bash
python3 -c "import netaddr; print('OK')"
```

### Debug subnet matching

```yaml
- name: Debug subnet check
  ansible.builtin.debug:
    msg:
      - "IP: {{ my_ip }}"
      - "Subnets: {{ allowed_subnets }}"
      - "Matches: {{ allowed_subnets | map('ansible.utils.ipaddr', my_ip) | select() | list }}"
```

## Examples in This Directory

| File | Purpose | When to Use |
|------|---------|-------------|
| `simple_playbook.yml` | Basic validation | Learning the pattern |
| `complete_validation.yml` | Detailed reporting | Production validation with reports |
| `practical_example.yml` | Real-world pattern | Deployment automation |
| `test_examples.sh` | Run all examples | Testing/verification |

## One-Liners

```bash
# Quick test
ansible localhost -m debug -a "msg={{ '10.1.1.1' | ansible.utils.ipaddr('10.1.0.0/16') }}"

# Validate from command line
ansible-playbook simple_playbook.yml -e '{"ip_addresses": ["10.1.1.1", "192.168.1.1"]}'

# Override subnets
ansible-playbook practical_example.yml -e '{"corporate_subnets": ["10.0.0.0/8"]}'
```

