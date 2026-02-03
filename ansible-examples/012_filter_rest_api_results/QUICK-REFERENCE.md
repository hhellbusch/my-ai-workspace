# Quick Reference - Filtering REST API Results

## Filter Syntax Cheat Sheet

### Basic Patterns

```yaml
# Exact match
{{ data | selectattr('field', 'equalto', 'value') | list }}

# Partial match (contains)
{{ data | selectattr('field', 'search', 'substring') | list }}

# Starts with (regex)
{{ data | selectattr('field', 'match', '^prefix') | list }}

# Multiple values
{{ data | selectattr('field', 'in', ['value1', 'value2']) | list }}

# Exclude/reject
{{ data | rejectattr('field', 'equalto', 'value') | list }}

# First match only
{{ data | selectattr('field', 'equalto', 'value') | first }}

# Get field values only
{{ data | map(attribute='field') | list }}

# Count matches
{{ data | selectattr('field', 'equalto', 'value') | list | length }}
```

### Multiple Conditions

```yaml
# Chain filters (AND logic)
{{ data | selectattr('f1', 'equalto', 'v1') | selectattr('f2', 'equalto', 'v2') | list }}

# Combine with rejectattr
{{ data | selectattr('env', 'equalto', 'prod') | rejectattr('disabled', 'equalto', true) | list }}
```

### Nested Fields

```yaml
# Access nested field with dot notation
{{ data | selectattr('metadata.tags.env', 'equalto', 'prod') | list }}

# Multiple nested conditions
{{ data | selectattr('metadata.owner', 'equalto', 'team-a') | selectattr('metadata.tier', 'equalto', 'critical') | list }}
```

### JSON Query (JMESPath)

```yaml
# Install first: pip install jmespath

# Simple query
{{ data | json_query('[?field==`value`]') }}

# Multiple conditions
{{ data | json_query('[?field1==`value1` && field2==`value2`]') }}

# Numeric comparison
{{ data | json_query('[?age>=`18`]') }}

# OR logic
{{ data | json_query('[?field1==`value1` || field2==`value2`]') }}

# Extract specific fields
{{ data | json_query('[*].field') }}
```

## Common S3 Credential Filtering Examples

### By Bucket Name

```yaml
# Exact bucket
bucket_creds: "{{ all_creds | selectattr('bucket_name', 'equalto', 'my-bucket') | list }}"

# Buckets containing 'prod'
prod_creds: "{{ all_creds | selectattr('bucket_name', 'search', 'prod') | list }}"

# Buckets starting with 'prod-'
prefixed_creds: "{{ all_creds | selectattr('bucket_name', 'match', '^prod-') | list }}"

# Multiple specific buckets
multi_creds: "{{ all_creds | selectattr('bucket_name', 'in', ['bucket1', 'bucket2']) | list }}"
```

### By Region

```yaml
# Single region
us_east_creds: "{{ all_creds | selectattr('region', 'equalto', 'us-east-1') | list }}"

# Multiple regions
us_creds: "{{ all_creds | selectattr('region', 'in', ['us-east-1', 'us-west-2']) | list }}"

# Exclude region
non_eu_creds: "{{ all_creds | rejectattr('region', 'search', 'eu-') | list }}"
```

### By Status/Boolean

```yaml
# Enabled only
enabled_creds: "{{ all_creds | selectattr('enabled', 'equalto', true) | list }}"

# Disabled only
disabled_creds: "{{ all_creds | selectattr('enabled', 'equalto', false) | list }}"
```

### Combined Filters

```yaml
# Production, US-East-1, Enabled
filtered: >-
  {{
    all_creds |
    selectattr('bucket_name', 'search', 'prod') |
    selectattr('region', 'equalto', 'us-east-1') |
    selectattr('enabled', 'equalto', true) |
    list
  }}
```

## API Response Handling

### Simple List Response

```json
[
  {"bucket_name": "prod-data", "access_key": "AKIA..."},
  {"bucket_name": "dev-data", "access_key": "AKIA..."}
]
```

```yaml
- name: Fetch and filter
  block:
    - uri:
        url: "{{ api_url }}"
        return_content: yes
      register: api_response
    
    - set_fact:
        filtered: "{{ api_response.json | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

### Nested Response

```json
{
  "credentials": [
    {"bucket_name": "prod-data", "access_key": "AKIA..."}
  ]
}
```

```yaml
- set_fact:
    filtered: "{{ api_response.json.credentials | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

### Paginated Response

```json
{
  "data": {
    "items": [...],
    "next_page": "..."
  }
}
```

```yaml
- set_fact:
    filtered: "{{ api_response.json.data.items | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

## Error Handling

### Check for Empty Results

```yaml
- name: Filter credentials
  set_fact:
    filtered: "{{ all_creds | selectattr('bucket_name', 'equalto', target) | list }}"

- name: Verify found
  assert:
    that: filtered | length > 0
    fail_msg: "No credentials found for {{ target }}"
```

### Safe First Element Access

```yaml
# With default
my_cred: "{{ filtered | first | default({}) }}"

# With conditional
- set_fact:
    my_cred: "{{ filtered[0] }}"
  when: filtered | length > 0
```

### Handle Missing Fields

```yaml
# Filter only items with field defined
filtered: "{{ data | selectattr('field', 'defined') | selectattr('field', 'equalto', 'value') | list }}"

# Use default values
value: "{{ item.field | default('N/A') }}"
```

## Performance Tips

```yaml
# ✓ Good - filter early
filtered: "{{ api_response.json | selectattr('bucket_name', 'equalto', target) | list }}"

# ✗ Avoid - filter late after processing
# (processes all items unnecessarily)

# ✓ Good - use first for single item
item: "{{ data | selectattr('id', 'equalto', my_id) | first }}"

# ✗ Avoid - get list then index
# item: "{{ (data | selectattr('id', 'equalto', my_id) | list)[0] }}"

# ✓ Good - chain filters
result: "{{ data | selectattr('f1', ...) | selectattr('f2', ...) | list }}"

# ✗ Avoid - multiple temp variables
# temp1: "{{ data | selectattr('f1', ...) | list }}"
# result: "{{ temp1 | selectattr('f2', ...) | list }}"
```

## Debugging Filters

```yaml
# See all data
- debug: var=api_response.json

# See available field names
- debug:
    msg: "{{ item.keys() | list }}"
  loop: "{{ api_response.json }}"
  loop_control:
    label: "Fields"

# See field values
- debug:
    msg: "{{ item.bucket_name }}"
  loop: "{{ api_response.json }}"

# Test filter
- debug:
    msg: "{{ api_response.json | selectattr('bucket_name', 'equalto', 'prod-data') | list }}"
```

## Common Mistakes

### ❌ Wrong: Using search for exact match
```yaml
# Matches: prod, production, prod-data, my-prod-bucket
filtered: "{{ data | selectattr('bucket_name', 'search', 'prod') | list }}"
```

### ✓ Right: Use equalto for exact match
```yaml
# Matches: prod (only)
filtered: "{{ data | selectattr('bucket_name', 'equalto', 'prod') | list }}"
```

### ❌ Wrong: Forgetting | list
```yaml
filtered: "{{ data | selectattr('bucket_name', 'equalto', 'prod') }}"
# Returns filter object, not list
```

### ✓ Right: Always end with | list
```yaml
filtered: "{{ data | selectattr('bucket_name', 'equalto', 'prod') | list }}"
```

### ❌ Wrong: Using first on empty results
```yaml
item: "{{ data | selectattr('id', 'equalto', 'missing') | first }}"
# Fails if no match found
```

### ✓ Right: Provide default or check length
```yaml
item: "{{ data | selectattr('id', 'equalto', 'missing') | first | default({}) }}"
```

## Filter Comparison Table

| Filter | Test | Example | Matches |
|--------|------|---------|---------|
| `equalto` | Exact equality | `'prod'` | "prod" |
| `search` | Contains (regex) | `'prod'` | "prod", "production", "my-prod" |
| `match` | Starts with (regex) | `'^prod'` | "prod", "production" (not "my-prod") |
| `in` | In list | `['prod', 'dev']` | "prod" OR "dev" |
| `defined` | Field exists | - | Any non-null value |
| `>`, `<`, `>=`, `<=` | Numeric | `'5'` | Numeric comparison |

## Real-World One-Liners

```yaml
# Get production S3 creds for app
"{{ api.json | selectattr('bucket_name', 'equalto', 'prod-myapp-data') | first }}"

# Get all production buckets
"{{ api.json | selectattr('bucket_name', 'search', '^prod-') | list }}"

# Get enabled US buckets
"{{ api.json | selectattr('region', 'search', 'us-') | selectattr('enabled', 'equalto', true) | list }}"

# Get bucket names only
"{{ api.json | selectattr('enabled', 'equalto', true) | map(attribute='bucket_name') | list }}"

# Count production buckets
"{{ api.json | selectattr('bucket_name', 'search', 'prod') | list | length }}"

# Get access keys for team
"{{ api.json | selectattr('owner', 'equalto', 'team-alpha') | map(attribute='access_key') | list }}"
```

## See Also

- [README.md](README.md) - Complete guide with examples
- [EXAMPLES.md](EXAMPLES.md) - Additional use case examples
- `simple_filter.yml` - Basic filtering example
- `filter_patterns.yml` - All filter types demonstrated
- `advanced_filters.yml` - Complex nested filtering

