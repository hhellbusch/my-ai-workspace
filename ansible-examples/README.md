# Ansible Best Practice Examples

This project contains runnable examples for the Ansible patterns we discussed.

## How to Run

For each example, navigate into the corresponding directory and run the playbook using the `ansible-playbook` command.

All playbooks are designed to run against `localhost` and require no external inventory.

### 1. Retry on Timeout

This example demonstrates how to retry a block of tasks if a subsequent task times out.

```bash
cd 1_retry_on_timeout
ansible-playbook playbook.yml
```

### 2. Log Ignored Errors

This example shows the modern `block/rescue` pattern for ignoring a task failure while logging the error details for debugging.

```bash
cd 2_log_ignored_errors
ansible-playbook playbook.yml
```

### 3. Conditional Block

This example shows how to conditionally execute a block of tasks by using `when` on an `include_tasks` statement.

```bash
cd 3_conditional_block
ansible-playbook main_playbook.yml
```

### 4. Validate Virtual Media Ejection

This example demonstrates how to eject virtual media from Dell iDRAC and validate that the ejection was successful. It shows multiple validation methods including return value checking, status querying with retries, and reusable validation tasks.

```bash
cd 4_validate_virtual_media_ejection
# See the README.md in that directory for detailed usage
ansible-playbook playbook.yml -e "idrac_ip=192.168.1.100" -e "idrac_user=root" -e "idrac_password=calvin"
```

### 5. Block/Rescue with Recovery and Retry ⭐

This example shows how to handle flaky tasks that sometimes fail, with automatic recovery and retry logic. Perfect for dealing with unreliable APIs, services that need warm-up time, or network operations.

**Key concepts:**
- Using `block/rescue` to catch failures
- Executing recovery tasks (restart service, clear cache, etc.)
- Implementing retry logic with maximum attempts
- Graceful failure handling
- DRY (Don't Repeat Yourself) with `include_tasks`

```bash
cd 5_block_rescue_retry

# Start with the simple example
ansible-playbook simple_example.yml

# Then see the production-ready clean version
ansible-playbook clean_playbook.yml
```

### 6. Parallel Execution via Bastion (AAP/Execution Environment) ⭐

Transform serial Ansible playbooks into parallel powerhouses when running from **Ansible Automation Platform (AAP)** through a bastion host.

**The Problem:** Tasks execute one node at a time (slow!)  
**The Solution:** Execute tasks across all nodes simultaneously (5-100x faster!)

**Architecture:**
```
AAP Execution Environment → Bastion (SSH Proxy) → Target Nodes (parallel)
```

**Key concepts:**
- AAP-specific configuration (Job Templates, Credentials, Forks)
- Bastion/jump host with ProxyJump
- Simple parallelism with forks (5-20x faster)
- Maximum parallelism with async (10-100x faster)
- Execution Environment considerations
- Real-world production examples

```bash
cd 6_parallel_execution_via_bastion
```

**📚 Documentation Structure:**
```
6_parallel_execution_via_bastion/
├── README.md (overview)
├── INDEX.md (complete navigation)
├── inventory.yml (example config)
├── ansible.cfg (settings)
├── docs/ (detailed guides)
│   ├── AAP-README.md ⭐ START HERE
│   ├── AAP-SETUP-GUIDE.md
│   ├── EXECUTION-ENVIRONMENT.md
│   ├── QUICK-START.md
│   └── COMPARISON.md
└── playbooks/ (examples)
    ├── test_connectivity.yml ⭐ TEST FIRST
    ├── parallel_forks.yml (5-20x faster)
    ├── parallel_async.yml (10-100x faster)
    └── parallel_async_real_world.yml
```

**Quick Start for AAP:**
1. Read `docs/AAP-README.md`
2. Import `playbooks/test_connectivity.yml` to test bastion config
3. Remove `serial: 1` from your playbook
4. Set **Forks: 20** in AAP Job Template
5. Measure the speedup!

**For command-line testing:**
```bash
# Test connectivity
ansible-playbook -i inventory.yml playbooks/test_connectivity.yml

# Compare serial vs parallel
ansible-playbook -i inventory.yml playbooks/serial_execution.yml
ansible-playbook -i inventory.yml playbooks/parallel_forks.yml --forks 20

# Maximum speed with async
ansible-playbook -i inventory.yml playbooks/parallel_async.yml
```

### 7. Monitor ISO Boot and Installation via Redfish ⭐

This example demonstrates how to monitor server boot and installation from ISO via Redfish API (iDRAC, iLO, etc.) without relying on `sleep` or fixed timeouts.

**The Problem:** Using `sleep` wastes time and doesn't detect failures  
**The Solution:** Poll Redfish API for real-time system status and boot progress

**What it monitors:**
- System power state (On/Off/PoweringOn)
- Boot source (CD/ISO vs Hard Disk)
- Virtual media status (ISO mounted/ejected)
- System health and state
- Installation completion indicators

**Key concepts:**
- Intelligent polling instead of fixed delays
- Multi-indicator monitoring (power + media + boot source)
- Using both `community.general.redfish_info` module and direct API calls
- Wait for specific conditions with timeout
- Real-time status display during boot

```bash
cd 7_monitor_iso_boot
```

**📚 Two Approaches:**

**1. Using Redfish Module (Recommended):**
```bash
# Simple monitoring
ansible-playbook simple_monitor_module.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "iterations=60" \
  -e "interval=10"

# Wait for specific condition
ansible-playbook wait_for_condition_module.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "wait_condition=installation_complete"

# Advanced monitoring (system + virtual media)
ansible-playbook monitor_with_module.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin"
```

**2. Using Direct Redfish API:**
```bash
# Simple monitoring with URI module
ansible-playbook simple_monitor.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin"

# Complete workflow: mount ISO → boot → monitor → verify
ansible-playbook complete_iso_boot.yml \
  -e "idrac_ip=192.168.1.100" \
  -e "idrac_user=root" \
  -e "idrac_password=calvin" \
  -e "iso_url=http://server.example.com/rhcos.iso" \
  -e "expected_server_ip=192.168.1.50"
```

**Example Output:**
```
========================================================
Poll #12 - 2025-12-04 14:25:30
========================================================
SYSTEM:
  Power State:       On
  System Health:     OK
  System State:      Enabled
  Boot Source:       Cd
  Boot Enabled:      Once

VIRTUAL MEDIA (CD):
  Inserted:          true
  Image:             http://server.example.com/rhcos.iso
  Connected Via:     URI

INDICATORS:
  ✅ System powered on
  📀 ISO mounted
  💿 Booting from Cd
========================================================
```

**Prerequisites:**
```bash
# Required for module-based playbooks
ansible-galaxy collection install community.general
```

**See the [README.md](7_monitor_iso_boot/README.md) for:**
- Complete documentation
- Troubleshooting guide
- Redfish API reference
- Module vs Direct API comparison
```

### 8. Validate IP Addresses Against Subnets ⭐

This example demonstrates how to validate that IP addresses belong to specific subnets using Ansible. Perfect for network compliance, security audits, and pre-deployment validation.

**The Problem:** Need to ensure servers/services are only deployed on approved network segments  
**The Solution:** Validate IPs against a list of allowed subnets using `ansible.utils.ipaddr` filter

**Use Cases:**
- Pre-deployment validation (ensure IPs are in approved networks)
- Security audits (find IPs outside corporate ranges)
- Network compliance checks
- CMDB validation

**Key concepts:**
- Using `ansible.utils.ipaddr` filter for subnet matching
- Iterating over IP lists with validation
- Creating detailed validation reports
- Filtering valid vs invalid IPs for further processing
- Optional enforcement with assertions

```bash
cd 8_validate_ip_in_subnets
```

**Prerequisites:**
```bash
# Install the ansible.utils collection (required)
ansible-galaxy collection install ansible.utils

# Or use the requirements file
ansible-galaxy collection install -r requirements.yml

# Python netaddr library is also required
pip install netaddr
```

**Three Examples:**

**1. Simple Validation:**
```bash
ansible-playbook simple_playbook.yml
```
Basic IP validation against a list of subnets with pass/fail results.

**2. Complete Validation with Detailed Reporting:**
```bash
# Show detailed report
ansible-playbook complete_validation.yml

# Enable strict mode (fail on invalid IPs)
ansible-playbook complete_validation.yml -e "fail_on_invalid=true"
```
Comprehensive validation with:
- Which subnet(s) each IP matches
- Summary statistics (valid/invalid counts)
- Descriptive labels for IPs and subnets
- Optional enforcement

**3. Practical Example:**
```bash
ansible-playbook practical_example.yml
```
Real-world pattern showing:
- Loading data from variables/inventory
- Filtering IPs for deployment
- Creating approved/rejected lists
- Optional assertion for CI/CD pipelines

**Example Output:**
```
====================================
IP SUBNET VALIDATION SUMMARY
====================================
Total IPs checked: 6
Valid IPs: 4
Invalid IPs: 2

IP: 10.50.100.25
Description: App Server 1
Status: VALID ✓
Matching Subnets: Private Network Class A
---

IP: 8.8.8.8
Description: External DNS
Status: INVALID ✗
Matching Subnets: None
---
```

**Quick Filter Reference:**
```yaml
# Check if IP is in subnet
{{ '10.1.50.10' | ansible.utils.ipaddr('10.1.0.0/16') }}

# Check if IP matches any subnet in list
{{ subnets | map('ansible.utils.ipaddr', my_ip) | select() | list | length > 0 }}

# Filter list to only valid IPs
{{ all_ips | select('ansible.utils.ipaddr', my_subnet) | list }}
```

**Run All Tests:**
```bash
./test_examples.sh
```

**See the [README.md](8_validate_ip_in_subnets/README.md) for:**
- Detailed filter usage examples
- Loading data from inventory/API/files
- Security audit patterns
- Troubleshooting guide
- Best practices

### 9. Global Defaults Across Playbooks and Roles ⭐

This example demonstrates how to set default values globally for an Ansible playbook and make them available to all subsequent tasks and roles. Essential for maintaining consistency across multi-role deployments.

**The Problem:** Different roles need to share common configuration (app name, paths, feature flags, etc.)  
**The Solution:** Set variables at the playbook level that all roles inherit

**Four Methods for Setting Global Defaults:**
1. **Playbook vars** - Core application settings (high precedence)
2. **vars_files** - Environment-specific configurations (loaded dynamically)
3. **group_vars** - Infrastructure patterns and inventory-based defaults
4. **host_vars** - Per-host customization and overrides

**Key concepts:**
- Variable precedence and inheritance
- Derived variables (paths based on app name)
- Feature flags for conditional execution
- Environment-specific configuration loading
- Best practices for role defaults vs playbook vars

```bash
cd 9_global_defaults_across_roles
```

**Quick Start:**

**1. Simplest Pattern (5 seconds to understand):**
```bash
ansible-playbook simple_example.yml
```
Shows the basic pattern - any variable in playbook `vars:` is available to all roles.

**2. Complete Example (full pattern):**
```bash
# Run with default settings (production)
ansible-playbook -i inventory.yml main_playbook.yml --check

# Run with development settings
ansible-playbook -i inventory.yml main_playbook.yml -e "environment=development" --check

# Override any variable
ansible-playbook -i inventory.yml main_playbook.yml \
  -e "app_name=custom" \
  -e "memory_limit=4096M" \
  --check
```

**Example Pattern:**
```yaml
---
- name: Deploy application
  hosts: all
  vars:
    # Global defaults - available to ALL roles
    app_name: "myapp"
    app_version: "1.0.0"
    environment: "production"
    
    # Derived paths
    base_install_dir: "/opt/{{ app_name }}"
    log_dir: "/var/log/{{ app_name }}"
    config_dir: "/etc/{{ app_name }}"
    
    # Feature flags
    enable_monitoring: true
    enable_ssl: true
    
  vars_files:
    - "vars/{{ environment }}.yml"  # Load environment-specific
  
  roles:
    - webserver     # Uses all global vars
    - database      # Uses all global vars
    - monitoring    # Uses all global vars
```

**Real-World Benefits:**
- DRY (Don't Repeat Yourself) - define once, use everywhere
- Consistent paths and naming across all roles
- Easy environment switching (dev/staging/prod)
- Feature toggles for optional components
- Simplified testing with variable overrides

**What's Included:**
- 3 sample roles (webserver, database, monitoring) that use global vars
- Environment-specific configs (production.yml, development.yml)
- group_vars and host_vars examples
- Complete templates showing variable usage
- Extensive documentation

**Documentation Structure:**
```
9_global_defaults_across_roles/
├── README.md ⭐ Complete guide
├── QUICK-START.md ⭐ 5-minute tutorial
├── PRECEDENCE-GUIDE.md ⭐ Variable precedence explained
├── simple_example.yml ⭐ Start here
├── main_playbook.yml (full example)
├── inventory.yml
├── vars/ (environment configs)
│   ├── common.yml
│   ├── production.yml
│   └── development.yml
├── group_vars/ (infrastructure defaults)
│   ├── all.yml
│   ├── production.yml
│   └── development.yml
├── host_vars/ (per-host overrides)
└── roles/ (3 example roles)
    ├── webserver/
    ├── database/
    └── monitoring/
```

**Variable Precedence (lowest to highest):**
1. Role defaults (`roles/*/defaults/main.yml`) - Lowest
2. group_vars/all.yml
3. group_vars/group_name.yml
4. Playbook vars_files
5. Playbook vars
6. host_vars
7. Extra vars (`-e`) - Highest (always wins)

**Quick Reference:**
```yaml
# Set global defaults (pick one or combine):

# Method 1: In playbook
vars:
  my_var: "value"

# Method 2: In external file
vars_files:
  - "vars/{{ environment }}.yml"

# Method 3: In inventory
# group_vars/all.yml
my_var: "value"

# Method 4: Override from CLI
ansible-playbook playbook.yml -e "my_var=override"
```

**Common Use Cases:**
- Multi-role deployments with shared configuration
- Environment-specific deployments (dev/staging/prod)
- Feature flag management
- Path standardization across roles
- Compliance and security settings

**Best Practices Demonstrated:**
- ✅ Use `roles/*/defaults/main.yml` for role defaults (easily overridden)
- ✅ Use playbook `vars:` for core application settings
- ✅ Use `vars_files:` for environment-specific configs
- ✅ Provide fallbacks with `{{ var | default('fallback') }}`
- ✅ Document which variables are required vs optional
- ❌ Don't use `roles/*/vars/main.yml` for defaults (too high precedence)

**See the documentation for:**
- Complete variable precedence explanation
- Advanced patterns (computed vars, conditionals)
- Troubleshooting guide
- Multiple real-world examples

### 10. Dell Memory Validation (Memtest with iDRAC)

This example demonstrates automated memory testing on Dell servers using iDRAC. See the [README](10_dell_memory_validation/README.md) for details.

### 11. Parallel Inventory Source Updates (Controller/Tower/AWX) ⭐

This example demonstrates how to dramatically speed up Ansible Controller/Tower inventory source updates by running them in parallel instead of sequentially.

**The Problem:** Looping over `ansible.controller.inventory_source_update` is **slow** - each update waits for the previous one to complete  
**The Solution:** Use `async` with `poll: 0` to trigger all updates simultaneously

**Performance Gain:**
- **5 inventories @ 2 minutes each:**
  - Sequential: 10 minutes
  - Parallel: ~2 minutes (**5x faster!**)

**Key concepts:**
- Async execution with `async` and `poll: 0`
- Fire-and-forget pattern (start all, then wait)
- Using `async_status` to monitor completion
- Error handling for failed updates
- Production-ready patterns with logging and reporting

```bash
cd 11_parallel_inventory_updates
```

**Quick Start:**

**1. Test your Controller connection first:**
```bash
# Set credentials
export CONTROLLER_HOST=https://controller.example.com
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=secret

# Test connection
ansible-playbook test_controller_connection.yml
```

**2. Run the simple parallel update:**
```bash
# Edit the inventory_sources list in the playbook first
ansible-playbook parallel_inventory_update_simple.yml
```

**3. Compare sequential vs parallel (optional):**
```bash
# This will run both methods and show timing comparison
ansible-playbook comparison_sequential_vs_parallel.yml
```

**Three Playbook Options:**

**1. Simple Version (`parallel_inventory_update_simple.yml`)** ⭐ Start here
- Clean, minimal code
- Easy to understand
- Perfect for most use cases

```yaml
# Fire all updates at once
- name: Start all inventory updates
  ansible.controller.inventory_source_update:
    inventory: "{{ item.inventory }}"
    name: "{{ item.source }}"
  loop: "{{ inventory_sources }}"
  async: 600
  poll: 0
  register: jobs

# Wait for all to complete
- name: Wait for completion
  async_status:
    jid: "{{ item.ansible_job_id }}"
  loop: "{{ jobs.results }}"
  until: finished
  retries: 60
  delay: 10
```

**2. Production Version (`parallel_with_error_handling.yml`)** ⭐ For production
- Comprehensive error handling
- Detailed logging and reporting
- Success/failure tracking
- Performance metrics
- Continues even if some updates fail

**3. Comparison Version (`comparison_sequential_vs_parallel.yml`)**
- Runs both sequential and parallel methods
- Shows timing comparison
- Calculates speed improvement
- Great for demonstrating the benefits

**Example Output:**
```
╔════════════════════════════════════════════════════════════╗
║              PERFORMANCE COMPARISON RESULTS                ║
╠════════════════════════════════════════════════════════════╣
║ Sequential (old way):  600 seconds = 10.0 minutes         ║
║ Parallel (new way):    120 seconds = 2.0 minutes          ║
║                                                            ║
║ Time saved: 480 seconds (80% faster!)                     ║
║                                                            ║
║ Number of inventories: 5                                  ║
╚════════════════════════════════════════════════════════════╝
```

**How It Works:**

**Traditional (Slow) Approach:**
```yaml
- name: Update inventories sequentially
  ansible.controller.inventory_source_update:
    inventory: "{{ item.inventory }}"
    name: "{{ item.source }}"
  loop: "{{ inventory_sources }}"
  # Each update waits for previous to complete ❌
```

**Parallel (Fast) Approach:**
```yaml
# Step 1: Start all updates (don't wait)
- name: Trigger updates
  ansible.controller.inventory_source_update:
    inventory: "{{ item.inventory }}"
    name: "{{ item.source }}"
  loop: "{{ inventory_sources }}"
  async: 600  # Max time allowed
  poll: 0     # Don't wait ✅
  register: jobs

# Step 2: Wait for all to finish
- name: Wait for all
  async_status:
    jid: "{{ item.ansible_job_id }}"
  loop: "{{ jobs.results }}"
  until: finished
  retries: 60
  delay: 10
```

**Configuration:**

Edit the `inventory_sources` list in any playbook:
```yaml
vars:
  inventory_sources:
    - { inventory: "Production", source: "aws_inventory" }
    - { inventory: "Production", source: "azure_inventory" }
    - { inventory: "Staging", source: "gcp_inventory" }
  
  controller_organization: "Default"
  update_timeout: 600  # 10 minutes max per update
```

**Prerequisites:**
```bash
# Install the ansible.controller collection
ansible-galaxy collection install ansible.controller

# Or for older systems
ansible-galaxy collection install awx.awx
```

**Authentication Methods:**

**Option 1: Environment variables (recommended)**
```bash
export CONTROLLER_HOST=https://controller.example.com
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=secret
export CONTROLLER_VERIFY_SSL=false
```

**Option 2: ansible.cfg**
```ini
[controller]
host = https://controller.example.com
username = admin
password = secret
verify_ssl = False
```

**Option 3: Ansible Vault**
```yaml
vars:
  controller_password: "{{ vault_controller_password }}"
```

**When to Use:**

**Use parallel updates when:**
- ✅ Updating 3+ inventory sources
- ✅ Each update takes > 30 seconds
- ✅ Updates are independent
- ✅ You want faster CI/CD pipelines
- ✅ Running scheduled inventory refreshes

**Use sequential when:**
- ❌ Only 1-2 quick updates
- ❌ Updates depend on each other
- ❌ Need strict ordering

**What's Included:**
- `parallel_inventory_update_simple.yml` - Minimal, clean implementation
- `parallel_inventory_update.yml` - More detailed with structure
- `parallel_with_error_handling.yml` - Production-ready with error handling
- `comparison_sequential_vs_parallel.yml` - Side-by-side timing comparison
- `test_controller_connection.yml` - Verify credentials and connectivity
- `README.md` - Comprehensive documentation with troubleshooting

**Documentation Structure:**
```
11_parallel_inventory_updates/
├── README.md ⭐ Complete guide
├── parallel_inventory_update_simple.yml ⭐ Start here
├── parallel_inventory_update.yml (structured version)
├── parallel_with_error_handling.yml (production-ready)
├── comparison_sequential_vs_parallel.yml (benchmark tool)
└── test_controller_connection.yml (connectivity test)
```

**Troubleshooting:**

**Authentication errors:**
```bash
# Test connection first
ansible-playbook test_controller_connection.yml

# Or manually
curl -k -u admin:password https://controller.example.com/api/v2/ping/
```

**Timeout issues:**
```yaml
# Increase timeout in playbook
vars:
  update_timeout: 1200  # 20 minutes instead of 10
  max_retries: 80       # More retry attempts
```

**See the [README.md](11_parallel_inventory_updates/README.md) for:**
- Complete async patterns explained
- Real-world performance metrics
- Advanced error handling techniques
- Integration with CI/CD pipelines
- Tower/AWX workflow job templates
- Detailed troubleshooting guide

**Related Examples:**
- See `6_parallel_execution_via_bastion/` for general async patterns
- Both examples demonstrate the power of async execution in Ansible

### 12. Filter REST API Results (S3 Credentials) ⭐

This example demonstrates how to filter data returned from REST APIs using Ansible's powerful Jinja2 filters. While focused on S3 credentials, these patterns apply to any REST API response.

**The Problem:** APIs return large datasets, but you only need specific items  
**The Solution:** Use Ansible filters (`selectattr`, `rejectattr`, `json_query`) to extract exactly what you need

**Use Cases:**
- Filter S3/cloud credentials by bucket/resource name
- Extract specific resources from cloud provider APIs
- Pre-process API responses before further operations
- Security audits and compliance checks
- Multi-environment credential management

**Key concepts:**
- Using `selectattr` for exact and partial matches
- Chaining multiple filter conditions
- Filtering nested JSON structures
- Extracting field values with `map`
- Using `json_query` (JMESPath) for complex queries
- Error handling for empty results

```bash
cd 12_filter_rest_api_results
```

**Quick Start:**

**1. Simple Example (5 seconds to understand):**
```bash
ansible-playbook simple_filter.yml

# With different bucket
ansible-playbook simple_filter.yml -e "target_bucket_name=dev-data"
```

**2. See All Filter Patterns:**
```bash
ansible-playbook filter_patterns.yml
```

**3. Real-World Example:**
```bash
# With mock data (demo)
ansible-playbook practical_example.yml

# With different app/env
ansible-playbook practical_example.yml -e "application_name=webapp" -e "app_environment=staging"
```

**4. Advanced Patterns:**
```bash
ansible-playbook advanced_filters.yml
```

**Common Filtering Patterns:**

```yaml
# Exact match - specific bucket
{{ credentials | selectattr('bucket_name', 'equalto', 'my-bucket') | list }}

# Partial match - all production buckets
{{ credentials | selectattr('bucket_name', 'search', 'prod') | list }}

# Starts with - bucket name prefix
{{ credentials | selectattr('bucket_name', 'match', '^prod-') | list }}

# Multiple values - specific list
{{ credentials | selectattr('bucket_name', 'in', ['bucket1', 'bucket2']) | list }}

# Exclude - NOT dev buckets
{{ credentials | rejectattr('bucket_name', 'search', 'dev') | list }}

# Multiple conditions - production AND enabled
{{ credentials | selectattr('env', 'equalto', 'prod') | selectattr('enabled', 'equalto', true) | list }}

# First match only - single result
{{ credentials | selectattr('bucket_name', 'equalto', 'my-bucket') | first }}

# Extract field values - get bucket names
{{ credentials | map(attribute='bucket_name') | list }}
```

**Real-World Workflow:**

```yaml
# 1. Fetch from API
- name: Get S3 credentials
  ansible.builtin.uri:
    url: "https://api.example.com/s3-credentials"
    method: GET
    headers:
      Authorization: "Bearer {{ api_token }}"
    return_content: yes
  register: api_response

# 2. Filter by bucket name
- name: Filter for production app bucket
  ansible.builtin.set_fact:
    app_credentials: >-
      {{
        api_response.json.credentials |
        selectattr('bucket_name', 'equalto', 'prod-myapp-data') |
        first
      }}

# 3. Use credentials
- name: Deploy configuration
  ansible.builtin.template:
    src: s3_config.j2
    dest: /etc/myapp/s3_config.ini
  vars:
    access_key: "{{ app_credentials.access_key }}"
    secret_key: "{{ app_credentials.secret_key }}"
```

**What's Included:**
- `simple_filter.yml` ⭐ Basic filtering example
- `filter_patterns.yml` - All filter types demonstrated
- `practical_example.yml` - Complete real-world workflow
- `advanced_filters.yml` - Complex nested filtering
- Comprehensive documentation with examples

**Documentation Structure:**
```
12_filter_rest_api_results/
├── README.md ⭐ Complete guide
├── QUICK-REFERENCE.md ⭐ Filter syntax cheat sheet
├── EXAMPLES.md ⭐ Additional use cases
├── simple_filter.yml ⭐ Start here
├── filter_patterns.yml (all patterns)
├── practical_example.yml (real workflow)
├── advanced_filters.yml (complex scenarios)
└── test_examples.sh (run all examples)
```

**Filter Quick Reference:**

| Filter | Use Case | Syntax |
|--------|----------|--------|
| `selectattr('f', 'equalto', 'v')` | Exact match | `'prod'` matches "prod" only |
| `selectattr('f', 'search', 'v')` | Contains | `'prod'` matches "prod", "production" |
| `selectattr('f', 'match', '^v')` | Starts with | `'^prod'` matches "prod*" |
| `selectattr('f', 'in', list)` | Multiple | `['a','b']` matches "a" OR "b" |
| `rejectattr('f', 'equalto', 'v')` | Exclude | NOT matching value |
| `json_query('[?f==\`v\`]')` | Complex | JMESPath queries |

**Run All Tests:**
```bash
./test_examples.sh

# Or specific examples
./test_examples.sh simple patterns
```

**Prerequisites:**
None! All filters are built into Ansible. Optional:
```bash
# For json_query examples
pip install jmespath
```

**See the [README.md](12_filter_rest_api_results/README.md) for:**
- Complete filter reference
- API response structure handling
- Error handling patterns
- Performance optimization tips
- Multiple real-world use cases
- Debugging techniques

**Common Use Cases:**
- CI/CD pipeline credential injection
- Multi-environment deployments
- Credential rotation workflows
- Security auditing
- Cost management reporting
- Disaster recovery verification
```
