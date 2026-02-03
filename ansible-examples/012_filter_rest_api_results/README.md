# Filter REST API Results with Ansible

This example demonstrates how to filter data returned from REST APIs using Ansible's powerful Jinja2 filters. Specifically focuses on filtering S3 credentials by bucket name, but the patterns apply to any REST API response.

## Overview

**The Problem:** REST APIs often return large datasets, but you only need specific items  
**The Solution:** Use Ansible's built-in filters (`selectattr`, `rejectattr`, `json_query`) to filter results efficiently

**Use Cases:**
- Filter S3 credentials by bucket name
- Select specific resources from cloud APIs
- Extract relevant data from large API responses
- Pre-process API data before further operations
- Security audits and compliance checks

## Prerequisites

No special collections required! All filters used are built into Ansible.

For `json_query` examples (optional):
```bash
pip install jmespath
```

## Quick Start

### 1. Simple Exact Match Filter

```bash
ansible-playbook simple_filter.yml
```

Demonstrates basic filtering with exact bucket name match.

### 2. Multiple Filter Patterns

```bash
ansible-playbook filter_patterns.yml
```

Shows various filtering techniques:
- Exact match (`equalto`)
- Partial match (`search`, `match`)
- Multiple values (`in`)
- Negation (`rejectattr`)
- Complex conditions

### 3. Real-World Example

```bash
ansible-playbook practical_example.yml
```

Complete workflow showing:
- Fetching from REST API
- Filtering credentials
- Writing filtered results to files
- Error handling

### 4. Advanced Patterns

```bash
ansible-playbook advanced_filters.yml
```

Advanced techniques:
- Nested data filtering
- Multiple condition filtering
- Custom filter combinations
- JSON Query (JMESPath) patterns

## How It Works

### Basic Filter Pattern

```yaml
# Fetch from API
- name: Get S3 credentials
  ansible.builtin.uri:
    url: "{{ api_endpoint }}"
    method: GET
    headers:
      Authorization: "Bearer {{ api_token }}"
    return_content: yes
  register: api_response

# Filter by bucket name
- name: Filter credentials
  ansible.builtin.set_fact:
    filtered_creds: "{{ api_response.json | selectattr('bucket_name', 'equalto', target_bucket) | list }}"
```

### Filter Methods Comparison

| Filter | Use Case | Example |
|--------|----------|---------|
| `selectattr('field', 'equalto', 'value')` | Exact match | Bucket name exactly "prod-data" |
| `selectattr('field', 'search', 'pattern')` | Contains substring | Bucket name contains "prod" |
| `selectattr('field', 'match', '^pattern')` | Regex match | Bucket name starts with "prod-" |
| `selectattr('field', 'in', list)` | Multiple values | Bucket name in list |
| `rejectattr('field', 'equalto', 'value')` | Exclude match | NOT dev buckets |
| `json_query('[?field==`value`]')` | Complex queries | Advanced filtering |

## Common Patterns

### Pattern 1: Exact Match (Single Bucket)

```yaml
- name: Get credentials for specific bucket
  ansible.builtin.set_fact:
    my_bucket_creds: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'equalto', 'my-production-bucket') |
        list
      }}
```

### Pattern 2: Partial Match (Contains)

```yaml
- name: Get all production buckets
  ansible.builtin.set_fact:
    prod_creds: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'search', 'prod') |
        list
      }}
```

### Pattern 3: Starts With (Regex)

```yaml
- name: Get buckets by prefix
  ansible.builtin.set_fact:
    prefixed_creds: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'match', '^prod-') |
        list
      }}
```

### Pattern 4: Multiple Buckets

```yaml
- name: Get credentials for multiple buckets
  ansible.builtin.set_fact:
    multi_creds: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'in', ['bucket1', 'bucket2', 'bucket3']) |
        list
      }}
```

### Pattern 5: Exclude Matches

```yaml
- name: Get all non-development buckets
  ansible.builtin.set_fact:
    non_dev_creds: >-
      {{
        api_response.json.credentials |
        rejectattr('bucket_name', 'search', 'dev') |
        list
      }}
```

### Pattern 6: Filter in Loop

```yaml
- name: Process only specific bucket
  ansible.builtin.debug:
    msg: "Processing {{ item.bucket_name }}: {{ item.access_key }}"
  loop: "{{ api_response.json.credentials }}"
  when: item.bucket_name == target_bucket
```

### Pattern 7: Multiple Conditions

```yaml
- name: Filter by multiple criteria
  ansible.builtin.set_fact:
    filtered: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'search', 'prod') |
        selectattr('region', 'equalto', 'us-east-1') |
        selectattr('enabled', 'equalto', true) |
        list
      }}
```

### Pattern 8: JSON Query (Advanced)

```yaml
- name: Complex filtering with JMESPath
  ansible.builtin.set_fact:
    filtered: >-
      {{
        api_response.json.credentials |
        json_query('[?bucket_name==`prod-data` && enabled==`true`]')
      }}
```

## API Response Structures

### Simple Flat List

```json
[
  {
    "bucket_name": "prod-data",
    "access_key": "AKIA...",
    "secret_key": "..."
  },
  {
    "bucket_name": "dev-data",
    "access_key": "AKIA...",
    "secret_key": "..."
  }
]
```

**Filtering:**
```yaml
filtered: "{{ api_response.json | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

### Nested Structure

```json
{
  "credentials": [
    {
      "bucket_name": "prod-data",
      "access_key": "AKIA...",
      "metadata": {
        "region": "us-east-1",
        "enabled": true
      }
    }
  ]
}
```

**Filtering:**
```yaml
filtered: "{{ api_response.json.credentials | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

### With Pagination

```json
{
  "data": {
    "credentials": [...],
    "next_page": "https://..."
  },
  "metadata": {
    "total": 150,
    "page": 1
  }
}
```

**Filtering:**
```yaml
filtered: "{{ api_response.json.data.credentials | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

## Real-World Use Cases

### Use Case 1: Deploy Application with Specific S3 Credentials

```yaml
---
- name: Deploy app with filtered S3 credentials
  hosts: app_servers
  vars:
    s3_api_url: "https://api.example.com/s3/credentials"
    app_bucket: "myapp-production-data"
  
  tasks:
    - name: Fetch all S3 credentials
      ansible.builtin.uri:
        url: "{{ s3_api_url }}"
        method: GET
        headers:
          Authorization: "Bearer {{ lookup('env', 'API_TOKEN') }}"
        return_content: yes
      delegate_to: localhost
      run_once: true
      register: s3_api
    
    - name: Filter for app bucket
      ansible.builtin.set_fact:
        app_s3_creds: >-
          {{
            s3_api.json.credentials |
            selectattr('bucket_name', 'equalto', app_bucket) |
            first
          }}
      delegate_to: localhost
      run_once: true
    
    - name: Deploy app configuration
      ansible.builtin.template:
        src: app_config.j2
        dest: /etc/myapp/config.ini
        mode: '0600'
      vars:
        aws_access_key: "{{ app_s3_creds.access_key }}"
        aws_secret_key: "{{ app_s3_creds.secret_key }}"
        s3_bucket: "{{ app_s3_creds.bucket_name }}"
```

### Use Case 2: Audit S3 Bucket Access

```yaml
---
- name: Audit S3 bucket access
  hosts: localhost
  vars:
    s3_api_url: "https://api.example.com/s3/credentials"
    production_prefix: "prod-"
  
  tasks:
    - name: Fetch all S3 credentials
      ansible.builtin.uri:
        url: "{{ s3_api_url }}"
        method: GET
        headers:
          Authorization: "Bearer {{ api_token }}"
        return_content: yes
      register: s3_api
    
    - name: Filter production buckets
      ansible.builtin.set_fact:
        prod_buckets: >-
          {{
            s3_api.json.credentials |
            selectattr('bucket_name', 'match', '^' + production_prefix) |
            list
          }}
    
    - name: Generate audit report
      ansible.builtin.copy:
        content: |
          # S3 Production Buckets Audit
          Date: {{ ansible_date_time.iso8601 }}
          Total Production Buckets: {{ prod_buckets | length }}
          
          {% for cred in prod_buckets %}
          ## {{ cred.bucket_name }}
          - Access Key: {{ cred.access_key }}
          - Region: {{ cred.region | default('N/A') }}
          - Enabled: {{ cred.enabled | default(true) }}
          
          {% endfor %}
        dest: "/tmp/s3_audit_{{ ansible_date_time.date }}.md"
```

### Use Case 3: Rotate Credentials for Multiple Buckets

```yaml
---
- name: Rotate S3 credentials
  hosts: localhost
  vars:
    s3_api_url: "https://api.example.com/s3/credentials"
    buckets_to_rotate:
      - "prod-app-data"
      - "prod-logs"
      - "prod-backups"
  
  tasks:
    - name: Fetch current credentials
      ansible.builtin.uri:
        url: "{{ s3_api_url }}"
        method: GET
        return_content: yes
      register: current_creds
    
    - name: Filter credentials for rotation
      ansible.builtin.set_fact:
        creds_to_rotate: >-
          {{
            current_creds.json.credentials |
            selectattr('bucket_name', 'in', buckets_to_rotate) |
            list
          }}
    
    - name: Display buckets to rotate
      ansible.builtin.debug:
        msg: "Will rotate credentials for: {{ creds_to_rotate | map(attribute='bucket_name') | list }}"
    
    - name: Request credential rotation
      ansible.builtin.uri:
        url: "{{ s3_api_url }}/rotate"
        method: POST
        body_format: json
        body:
          bucket_name: "{{ item.bucket_name }}"
        status_code: [200, 202]
      loop: "{{ creds_to_rotate }}"
      register: rotation_results
```

## Performance Tips

### 1. Filter Early

```yaml
# Good - filter immediately after API call
- name: Get and filter
  ansible.builtin.set_fact:
    filtered: "{{ api_response.json | selectattr('bucket_name', 'equalto', target) | list }}"

# Less optimal - process all, then filter
- name: Process all then filter
  # ... processes all items unnecessarily
```

### 2. Use `first` for Single Results

```yaml
# Get first matching item (more efficient than [0])
my_cred: "{{ credentials | selectattr('bucket_name', 'equalto', target) | first }}"
```

### 3. Cache Filtered Results

```yaml
# Cache filtered results for reuse
- name: Filter once
  ansible.builtin.set_fact:
    prod_creds: "{{ all_creds | selectattr('bucket_name', 'search', 'prod') | list }}"
    cacheable: yes

# Use cached results in subsequent plays
- name: Use cached data
  ansible.builtin.debug:
    var: prod_creds
```

### 4. Avoid Redundant Filtering

```yaml
# Bad - filters twice
- set_fact:
    temp: "{{ data | selectattr('type', 'equalto', 'prod') | list }}"
- set_fact:
    final: "{{ temp | selectattr('enabled', 'equalto', true) | list }}"

# Good - chain filters
- set_fact:
    final: >-
      {{
        data |
        selectattr('type', 'equalto', 'prod') |
        selectattr('enabled', 'equalto', true) |
        list
      }}
```

## Error Handling

### Check for Empty Results

```yaml
- name: Filter credentials
  ansible.builtin.set_fact:
    filtered_creds: "{{ all_creds | selectattr('bucket_name', 'equalto', target) | list }}"

- name: Verify results found
  ansible.builtin.assert:
    that:
      - filtered_creds | length > 0
    fail_msg: "No credentials found for bucket '{{ target }}'"
    success_msg: "Found {{ filtered_creds | length }} credential(s)"
```

### Handle Missing Fields

```yaml
- name: Safe filtering with default values
  ansible.builtin.set_fact:
    filtered: >-
      {{
        all_creds |
        selectattr('bucket_name', 'defined') |
        selectattr('bucket_name', 'equalto', target) |
        list
      }}
```

### API Error Handling

```yaml
- name: Fetch with error handling
  block:
    - name: Call API
      ansible.builtin.uri:
        url: "{{ api_endpoint }}"
        method: GET
        return_content: yes
        status_code: [200]
      register: api_response
    
    - name: Filter results
      ansible.builtin.set_fact:
        filtered: "{{ api_response.json | selectattr('bucket_name', 'equalto', target) | list }}"
  
  rescue:
    - name: Handle API failure
      ansible.builtin.debug:
        msg: "API call failed: {{ api_response.msg | default('Unknown error') }}"
    
    - name: Use cached/default credentials
      ansible.builtin.set_fact:
        filtered: "{{ cached_credentials | default([]) }}"
```

## Troubleshooting

### Issue: Filter returns empty list

**Check:**
1. Verify the field name matches exactly (case-sensitive)
2. Check the API response structure
3. Test with debug to see actual data

```yaml
- name: Debug API response
  ansible.builtin.debug:
    var: api_response.json

- name: Debug field values
  ansible.builtin.debug:
    msg: "{{ item.bucket_name }}"
  loop: "{{ api_response.json }}"
```

### Issue: "No such filter" error

**Problem:** Filter name might be wrong or Ansible version too old

**Solution:**
```bash
# Check Ansible version
ansible --version

# Verify filter availability
ansible localhost -m debug -a "msg={{ [1,2,3] | select() | list }}"
```

### Issue: Filter matches more than expected

**Problem:** Using `search` instead of exact match

**Solution:**
```yaml
# Wrong - matches "prod", "production", "prod-data", etc.
selectattr('bucket_name', 'search', 'prod')

# Right - exact match only
selectattr('bucket_name', 'equalto', 'prod')
```

### Issue: "first" filter fails when no results

**Problem:** Trying to get first item from empty list

**Solution:**
```yaml
# Safe - provides default
my_cred: "{{ credentials | selectattr('bucket_name', 'equalto', target) | first | default({}) }}"

# Or check length first
- name: Get credential
  ansible.builtin.set_fact:
    my_cred: "{{ filtered[0] }}"
  when: filtered | length > 0
```

## What's Included

```
12_filter_rest_api_results/
├── README.md ⭐ Complete guide (you are here)
├── QUICK-REFERENCE.md ⭐ Fast filter syntax reference
├── EXAMPLES.md ⭐ Additional examples and patterns
├── simple_filter.yml ⭐ Start here - basic example
├── filter_patterns.yml (all filter types)
├── practical_example.yml (real-world workflow)
├── advanced_filters.yml (complex scenarios)
├── api_responses.yml (test with mock data)
└── test_examples.sh (run all examples)
```

## Related Examples

See also:
- Example 8: Validate IP in subnets (filtering with network data)
- Example 5: Block rescue retry (error handling patterns)
- Example 6: Parallel execution (scaling API calls)

## Further Reading

- [Ansible Filters Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html)
- [Jinja2 Filters](https://jinja.palletsprojects.com/en/3.1.x/templates/#builtin-filters)
- [JMESPath Tutorial](https://jmespath.org/tutorial.html) (for json_query)
- [URI Module Documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)

## Quick Reference Card

| Task | Filter Expression |
|------|------------------|
| Exact match | `\| selectattr('field', 'equalto', 'value') \| list` |
| Contains | `\| selectattr('field', 'search', 'pattern') \| list` |
| Starts with | `\| selectattr('field', 'match', '^prefix') \| list` |
| In list | `\| selectattr('field', 'in', ['a', 'b']) \| list` |
| Exclude | `\| rejectattr('field', 'equalto', 'value') \| list` |
| First match | `\| selectattr(...) \| first` |
| Multiple conditions | `\| selectattr('f1', ...) \| selectattr('f2', ...) \| list` |
| Get field values | `\| map(attribute='field') \| list` |
| Count results | `\| selectattr(...) \| list \| length` |

