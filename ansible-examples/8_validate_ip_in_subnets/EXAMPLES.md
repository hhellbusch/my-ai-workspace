# Example Output and Usage

## Example 1: Simple Validation

### Command
```bash
ansible-playbook simple_playbook.yml
```

### Output
```
PLAY [Simple IP Subnet Validation] *********************************************

TASK [Check each IP against all subnets] ***************************************
ok: [localhost] => (item=10.50.100.25 vs 10.0.0.0/8)
ok: [localhost] => (item=10.50.100.25 vs 172.16.0.0/12)
ok: [localhost] => (item=10.50.100.25 vs 192.168.1.0/24)
...

TASK [Display validation results] **********************************************
ok: [localhost] => {
    "msg": "IP Address Validation Results:
10.50.100.25: VALID ✓
172.16.5.10: VALID ✓
192.168.1.50: VALID ✓
8.8.8.8: INVALID ✗
192.168.2.100: INVALID ✗
"
}
```

### What it shows
- ✓ `10.50.100.25` is in `10.0.0.0/8`
- ✓ `172.16.5.10` is in `172.16.0.0/12`
- ✓ `192.168.1.50` is in `192.168.1.0/24`
- ✗ `8.8.8.8` is not in any allowed subnet
- ✗ `192.168.2.100` is not in any allowed subnet (note: `192.168.1.0/24` doesn't cover it)

---

## Example 2: Practical Validation

### Command
```bash
ansible-playbook practical_example.yml
```

### Output
```
TASK [Display validation status] ***********************************************
ok: [localhost] => (item=10.1.50.10) => {
    "msg": "IP 10.1.50.10 is ALLOWED"
}
ok: [localhost] => (item=10.2.100.20) => {
    "msg": "IP 10.2.100.20 is ALLOWED"
}
ok: [localhost] => (item=10.10.5.50) => {
    "msg": "IP 10.10.5.50 is ALLOWED"
}
ok: [localhost] => (item=172.20.30.40) => {
    "msg": "IP 172.20.30.40 is ALLOWED"
}
ok: [localhost] => (item=192.168.1.100) => {
    "msg": "IP 192.168.1.100 is NOT ALLOWED"
}

TASK [Display approved IPs] ****************************************************
ok: [localhost] => {
    "msg": "Approved IPs for deployment: ['10.1.50.10', '10.2.100.20', '10.10.5.50', '172.20.30.40']"
}

TASK [Display rejected IPs] ****************************************************
ok: [localhost] => {
    "msg": "Rejected IPs (contact network team): ['192.168.1.100']"
}
```

### Use Case
This pattern is perfect for:
- Pre-deployment validation
- Creating lists of approved servers
- Filtering IPs for further processing
- CI/CD pipeline checks

---

## Example 3: Complete Validation with Detailed Reporting

### Command
```bash
ansible-playbook complete_validation.yml
```

### Output
```
TASK [Display summary] *********************************************************
ok: [localhost] => {
    "msg": [
        "======================================",
        "IP SUBNET VALIDATION SUMMARY",
        "======================================",
        "Total IPs checked: 6",
        "Valid IPs: 4",
        "Invalid IPs: 2",
        ""
    ]
}

TASK [Display detailed results] ************************************************
ok: [localhost] => (item=10.50.100.25) => {
    "msg": [
        "IP: 10.50.100.25",
        "Status: VALID ✓",
        "Matching Subnets: 10.0.0.0/8",
        "---"
    ]
}
ok: [localhost] => (item=172.16.5.10) => {
    "msg": [
        "IP: 172.16.5.10",
        "Status: VALID ✓",
        "Matching Subnets: 172.16.0.0/12",
        "---"
    ]
}
ok: [localhost] => (item=192.168.1.50) => {
    "msg": [
        "IP: 192.168.1.50",
        "Status: VALID ✓",
        "Matching Subnets: 192.168.1.0/24",
        "---"
    ]
}
ok: [localhost] => (item=203.0.113.15) => {
    "msg": [
        "IP: 203.0.113.15",
        "Status: VALID ✓",
        "Matching Subnets: 203.0.113.0/24",
        "---"
    ]
}
ok: [localhost] => (item=8.8.8.8) => {
    "msg": [
        "IP: 8.8.8.8",
        "Status: INVALID ✗",
        "Matching Subnets: None",
        "---"
    ]
}
ok: [localhost] => (item=192.168.2.100) => {
    "msg": [
        "IP: 192.168.2.100",
        "Status: INVALID ✗",
        "Matching Subnets: None",
        "---"
    ]
}
```

### Behavior When Invalid IPs Are Found

The playbook automatically fails when invalid IPs are detected:

### Output (with failure)
```
TASK [Fail if any invalid IPs found (optional)] ********************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "Validation failed! The following IPs are not covered by allowed subnets:
- 8.8.8.8
- 192.168.2.100
"}

TASK [Handle validation failure] ***********************************************
ok: [localhost] => {
    "msg": "Validation completed with errors. Check the results above."
}
```

---

## Customizing for Your Environment

### Using with Your Own Data

#### From Inventory
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

```bash
ansible-playbook -i inventory.yml practical_example.yml \
  -e "corporate_subnets={{ allowed_subnets }}" \
  -e "server_ips={{ groups['all'] | map('extract', hostvars, 'ansible_host') | list }}"
```

#### From Command Line
```bash
ansible-playbook simple_playbook.yml \
  -e '{"allowed_subnets": ["10.0.0.0/8"], "ip_addresses": ["10.1.1.1", "192.168.1.1"]}'
```

#### From Variable File
```bash
# network_config.yml
allowed_subnets:
  - "10.0.0.0/8"
  - "172.16.0.0/12"
ip_addresses:
  - "10.50.100.25"
  - "172.16.5.10"
```

```bash
ansible-playbook simple_playbook.yml -e @network_config.yml
```

---

## Integration Patterns

### CI/CD Pipeline
```yaml
# .gitlab-ci.yml or similar
validate-network:
  stage: validate
  script:
    - ansible-playbook complete_validation.yml
  only:
    - merge_requests
```

### Pre-Deployment Check
```yaml
- name: Validate before deployment
  hosts: localhost
  tasks:
    - name: Run IP validation
      ansible.builtin.include_tasks: check_ips.yml
      # Validation will automatically fail if invalid IPs are found
```

### Scheduled Audit
```bash
#!/bin/bash
# Run daily audit - continue even if validation fails
ansible-playbook complete_validation.yml \
  > /var/log/ip_audit_$(date +%Y%m%d).log 2>&1 || \
  echo "Validation failed - check log file"
```

---

## Filtering and Processing Results

### Extract Only Valid IPs
```yaml
- name: Get valid IPs for deployment
  ansible.builtin.set_fact:
    deploy_targets: "{{ validation_report | selectattr('allowed', 'equalto', true) | map(attribute='ip') | list }}"

- name: Deploy to valid hosts
  ansible.builtin.include_role:
    name: deploy_app
  vars:
    target_ip: "{{ item }}"
  loop: "{{ deploy_targets }}"
```

### Generate Report File
```yaml
- name: Save validation report
  ansible.builtin.copy:
    content: |
      IP Validation Report - {{ ansible_date_time.iso8601 }}
      ================================================
      {% for item in validation_details %}
      {{ item.ip }} ({{ item.description }}): {{ 'VALID' if item.is_valid else 'INVALID' }}
        Subnets: {{ item.matching_subnets | join(', ') }}
      {% endfor %}
    dest: "/var/log/ip_validation_{{ ansible_date_time.date }}.txt"
```

---

## Common Subnet Patterns

### RFC 1918 Private Networks
```yaml
allowed_subnets:
  - "10.0.0.0/8"          # Class A private
  - "172.16.0.0/12"       # Class B private
  - "192.168.0.0/16"      # Class C private
```

### Data Center Networks
```yaml
corporate_subnets:
  - "10.1.0.0/16"         # DC1
  - "10.2.0.0/16"         # DC2
  - "10.10.0.0/16"        # Cloud
  - "172.20.0.0/16"       # DMZ
  - "172.30.0.0/16"       # Management
```

### Kubernetes Pod/Service Networks
```yaml
k8s_networks:
  - "10.244.0.0/16"       # Pod network
  - "10.96.0.0/12"        # Service network
```

---

## Troubleshooting

### All IPs show as invalid
**Cause:** `ansible.utils` collection not installed  
**Solution:**
```bash
ansible-galaxy collection install ansible.utils
pip install netaddr
```

### Filter errors
**Cause:** Incorrect filter syntax or version  
**Solution:** Check filter usage:
```bash
ansible localhost -m debug -a "msg={{ '10.1.1.1' | ansible.utils.ipaddr('10.1.0.0/16') }}"
```

### Performance issues with large lists
**Solution:** Process in batches:
```yaml
- name: Validate in batches
  ansible.builtin.include_tasks: validate_batch.yml
  loop: "{{ large_ip_list | batch(100) | list }}"
```

---

## Next Steps

1. **Start with `simple_playbook.yml`** to understand the basics
2. **Try `practical_example.yml`** with your own IP lists
3. **Use `complete_validation.yml`** for production audits
4. **Integrate into CI/CD** - validation will fail pipelines automatically
5. **Customize** for your specific network topology

For more details, see [README.md](README.md) and [QUICK-REFERENCE.md](QUICK-REFERENCE.md).

