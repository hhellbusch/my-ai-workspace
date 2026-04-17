# Index - Filter REST API Results

## Quick Navigation

### 📚 Documentation

- **[README.md](README.md)** - Complete guide with examples, patterns, and best practices
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Filter syntax cheat sheet and one-liners
- **[EXAMPLES.md](EXAMPLES.md)** - Additional real-world use cases

### 🎯 Playbooks

Start with these in order:

1. **[simple_filter.yml](simple_filter.yml)** ⭐ **START HERE**
   - Basic filtering example
   - Filter S3 credentials by exact bucket name
   - 5 seconds to understand
   - Run: `ansible-playbook simple_filter.yml`

2. **[filter_patterns.yml](filter_patterns.yml)** ⭐ **LEARN ALL PATTERNS**
   - Demonstrates all filter types
   - Exact match, partial match, regex, multiple values, exclude, boolean
   - Chaining conditions
   - Run: `ansible-playbook filter_patterns.yml`

3. **[practical_example.yml](practical_example.yml)** ⭐ **REAL WORKFLOW**
   - Complete real-world example
   - Fetch from API → Filter → Write config files → Generate reports
   - Error handling and validation
   - Run: `ansible-playbook practical_example.yml`

4. **[advanced_filters.yml](advanced_filters.yml)** ⭐ **COMPLEX SCENARIOS**
   - Nested field filtering
   - Multiple condition combinations
   - JSON Query (JMESPath)
   - Grouping and transformations
   - Run: `ansible-playbook advanced_filters.yml`

### 🧪 Testing

- **[test_examples.sh](test_examples.sh)** - Run all examples
  ```bash
  ./test_examples.sh              # Run all
  ./test_examples.sh simple       # Run specific example
  ./test_examples.sh patterns     # Run patterns example
  ```

## Quick Start Guide

### For Complete Beginners

```bash
# 1. Start with the simple example
ansible-playbook simple_filter.yml

# 2. Try it with a different bucket
ansible-playbook simple_filter.yml -e "target_bucket_name=dev-data"

# 3. See all available patterns
ansible-playbook filter_patterns.yml

# 4. Run a complete workflow
ansible-playbook practical_example.yml
```

### For Experienced Users

```bash
# Jump straight to advanced examples
ansible-playbook advanced_filters.yml

# Or check the quick reference
cat QUICK-REFERENCE.md
```

## Filter Patterns Overview

| Pattern | When to Use | Example File |
|---------|-------------|--------------|
| Exact match | Specific bucket/resource name | `simple_filter.yml` |
| Partial match | Environment prefixes (prod, dev) | `filter_patterns.yml` |
| Regex | Complex name patterns | `filter_patterns.yml` |
| Multiple values | List of specific buckets | `filter_patterns.yml` |
| Exclude/Reject | Filter out dev/test | `filter_patterns.yml` |
| Multiple conditions | Production + Region + Enabled | `advanced_filters.yml` |
| Nested fields | Metadata, tags, compliance | `advanced_filters.yml` |
| JSON Query | Complex boolean logic | `advanced_filters.yml` |

## Common Use Cases

### By Use Case

- **CI/CD Integration** → `EXAMPLES.md` (Example 1, 2)
- **Multi-Environment Deployment** → `EXAMPLES.md` (Example 3, 4)
- **Credential Rotation** → `EXAMPLES.md` (Example 5, 6)
- **Security Auditing** → `EXAMPLES.md` (Example 7, 8)
- **Cost Management** → `EXAMPLES.md` (Example 9)
- **Disaster Recovery** → `EXAMPLES.md` (Example 10)
- **Multi-Cloud** → `EXAMPLES.md` (Example 11)

### By Skill Level

**Beginner:**
1. `simple_filter.yml`
2. `filter_patterns.yml` (Patterns 1-5)
3. `practical_example.yml`

**Intermediate:**
1. `filter_patterns.yml` (Patterns 6-11)
2. `advanced_filters.yml` (Patterns 1-5)
3. `EXAMPLES.md` (Examples 1-4)

**Advanced:**
1. `advanced_filters.yml` (Patterns 6-10)
2. `EXAMPLES.md` (Examples 5-11)
3. Custom implementations

## Filter Syntax Quick Lookup

```yaml
# Exact match
{{ data | selectattr('field', 'equalto', 'value') | list }}

# Contains
{{ data | selectattr('field', 'search', 'substring') | list }}

# Starts with
{{ data | selectattr('field', 'match', '^prefix') | list }}

# Multiple values
{{ data | selectattr('field', 'in', ['val1', 'val2']) | list }}

# Exclude
{{ data | rejectattr('field', 'equalto', 'value') | list }}

# Multiple conditions
{{ data | selectattr('f1', ...) | selectattr('f2', ...) | list }}

# First match
{{ data | selectattr('field', 'equalto', 'value') | first }}

# Extract field values
{{ data | map(attribute='field') | list }}

# Nested fields
{{ data | selectattr('metadata.tags.env', 'equalto', 'prod') | list }}

# JSON Query
{{ data | json_query('[?field==`value`]') }}
```

## Documentation Map

```
12_filter_rest_api_results/
│
├── INDEX.md (you are here)
│
├── 📖 Documentation
│   ├── README.md (complete guide)
│   ├── QUICK-REFERENCE.md (syntax cheat sheet)
│   └── EXAMPLES.md (use case library)
│
├── 🎯 Basic Examples
│   ├── simple_filter.yml ⭐ START
│   └── filter_patterns.yml
│
├── 🎯 Advanced Examples
│   ├── practical_example.yml
│   └── advanced_filters.yml
│
└── 🧪 Testing
    └── test_examples.sh
```

## Learning Path

### Path 1: Quick Start (15 minutes)

1. Read: [README.md](README.md) introduction
2. Run: `ansible-playbook simple_filter.yml`
3. Read: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
4. Modify: Change `target_bucket_name` in simple example
5. Done: You can now filter API responses!

### Path 2: Complete Understanding (1 hour)

1. Read: [README.md](README.md) completely
2. Run: All playbooks in order
3. Read: [EXAMPLES.md](EXAMPLES.md) for use cases
4. Practice: Modify examples for your API
5. Reference: Keep [QUICK-REFERENCE.md](QUICK-REFERENCE.md) handy

### Path 3: Expert Deep Dive (2-3 hours)

1. Complete Path 2
2. Study: `advanced_filters.yml` in detail
3. Implement: Your own filtering logic
4. Experiment: Combine multiple filter techniques
5. Optimize: Performance and error handling

## Troubleshooting Quick Links

- **Empty results** → [README.md#troubleshooting](README.md#troubleshooting)
- **Wrong filter type** → [QUICK-REFERENCE.md#common-mistakes](QUICK-REFERENCE.md#common-mistakes)
- **Nested fields** → `advanced_filters.yml` Pattern 1
- **Complex conditions** → `advanced_filters.yml` Pattern 5
- **Performance** → [README.md#performance-tips](README.md#performance-tips)

## Quick Command Reference

```bash
# Run single example
ansible-playbook simple_filter.yml

# Run with different target
ansible-playbook simple_filter.yml -e "target_bucket_name=my-bucket"

# Run practical example with custom app
ansible-playbook practical_example.yml \
  -e "application_name=myapp" \
  -e "app_environment=production"

# Run all tests
./test_examples.sh

# Run specific test
./test_examples.sh simple

# Verbose output
ansible-playbook simple_filter.yml -v
```

## Related Ansible Examples

- **Example 8** - Validate IP in subnets (filtering network data)
- **Example 5** - Block rescue retry (error handling)
- **Example 6** - Parallel execution (scaling API calls)
- **Example 11** - Parallel inventory updates (async patterns)

## External Resources

- [Ansible Filters Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html)
- [Jinja2 Filters](https://jinja.palletsprojects.com/en/3.1.x/templates/#builtin-filters)
- [JMESPath Tutorial](https://jmespath.org/tutorial.html)
- [URI Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)

---

**Need Help?**

- Start with: [README.md](README.md)
- Quick syntax: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- Use cases: [EXAMPLES.md](EXAMPLES.md)
- Test it: `./test_examples.sh`

