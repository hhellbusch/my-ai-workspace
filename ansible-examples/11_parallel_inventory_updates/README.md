# Parallel Inventory Source Updates

## Problem

When updating multiple inventory sources in Ansible Controller/Tower using a loop with `ansible.controller.inventory_source_update`, each update waits for the previous one to complete. This is **slow** and inefficient.

**Sequential approach (slow):**
```yaml
- name: Update inventories (SLOW)
  ansible.controller.inventory_source_update:
    inventory: "{{ item.inventory }}"
    name: "{{ item.source }}"
  loop: "{{ inventory_sources }}"
```

If you have 5 inventories that each take 2 minutes to update:
- **Total time: 10 minutes** (2 min × 5 inventories)

## Solution: Async Execution

Use `async` with `poll: 0` to trigger all updates simultaneously, then wait for completion.

**Parallel approach (fast):**
```yaml
# Step 1: Start all updates at once
- name: Trigger updates
  ansible.controller.inventory_source_update:
    inventory: "{{ item.inventory }}"
    name: "{{ item.source }}"
  loop: "{{ inventory_sources }}"
  async: 600
  poll: 0
  register: jobs

# Step 2: Wait for all to complete
- name: Wait for completion
  async_status:
    jid: "{{ item.ansible_job_id }}"
  loop: "{{ jobs.results }}"
  until: async_poll_results.finished
  retries: 60
  delay: 10
```

With the same 5 inventories:
- **Total time: ~2 minutes** (time of the longest update)
- **Speed improvement: 5x faster!**

## Playbook Options

### 1. Simple Version (`parallel_inventory_update_simple.yml`)
- Clean, easy to understand
- Minimal code
- Good for straightforward use cases

**Usage:**
```bash
ansible-playbook parallel_inventory_update_simple.yml
```

### 2. Full Version (`parallel_inventory_update.yml`)
- More detailed variable structure
- Better organization for complex scenarios
- Configurable timeout and organization

**Usage:**
```bash
ansible-playbook parallel_inventory_update.yml \
  -e "controller_organization=MyOrg"
```

### 3. Production Version (`parallel_with_error_handling.yml`)
- Comprehensive error handling
- Detailed logging and reporting
- Success/failure tracking
- Performance metrics
- Suitable for production environments

**Usage:**
```bash
ansible-playbook parallel_with_error_handling.yml \
  -e "controller_organization=MyOrg" \
  -e "update_timeout=900" \
  -e "check_interval=20"
```

## Configuration

### Variables

All playbooks can be customized with variables:

```yaml
vars:
  # List your inventory sources
  inventory_sources:
    - { inventory: "Production", source: "aws_inventory" }
    - { inventory: "Production", source: "azure_inventory" }
    - { inventory: "Staging", source: "gcp_inventory" }
  
  # Controller settings
  controller_organization: "Default"
  
  # Timeout settings
  update_timeout: 600        # 10 minutes max per update
  check_interval: 15         # Check status every 15 seconds
  max_retries: 40            # How many times to check (40 × 15s = 10 min)
```

### Authentication

These playbooks require Ansible Controller/Tower credentials. Set them via:

**Environment variables:**
```bash
export CONTROLLER_HOST=https://controller.example.com
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=secret
export CONTROLLER_VERIFY_SSL=false  # Optional
```

**Or in playbook vars:**
```yaml
vars:
  controller_hostname: "controller.example.com"
  controller_username: "admin"
  controller_password: "{{ vault_controller_password }}"
  controller_verify_ssl: false
```

**Or using ansible.cfg:**
```ini
[defaults]
# ... other settings ...

[controller]
host = https://controller.example.com
username = admin
password = secret
verify_ssl = False
```

## How Async Works

### The Pattern

1. **Fire phase** (`async: X, poll: 0`):
   - Starts the task in the background
   - Returns immediately with a job ID
   - Does NOT wait for completion

2. **Wait phase** (`async_status` with `until`):
   - Checks job status periodically
   - Waits for all jobs to finish
   - Collects results

### Key Parameters

- `async: 600` - Maximum time (seconds) to allow the task to run
- `poll: 0` - Don't wait; return immediately after starting
- `retries: 60` - How many times to check for completion
- `delay: 10` - Seconds between status checks

**Total wait time = retries × delay** (60 × 10 = 600 seconds = 10 minutes)

## Performance Comparison

### Real-World Example

Updating 8 inventory sources (AWS, Azure, GCP, VMware across prod/staging):

| Approach | Average Update Time | Total Time | Speed Gain |
|----------|---------------------|------------|------------|
| Sequential (loop) | 90 seconds each | 12 minutes | Baseline |
| Parallel (async) | 90 seconds each | 90 seconds | **8x faster** |

### When to Use

**Use async parallel execution when:**
- ✅ Updating 3+ inventory sources
- ✅ Each update takes > 30 seconds
- ✅ Updates are independent (don't depend on each other)
- ✅ You want faster CI/CD pipelines
- ✅ You're updating sources on a schedule

**Use sequential (regular loop) when:**
- ❌ Only 1-2 quick updates
- ❌ Updates depend on each other
- ❌ You need strict ordering
- ❌ Debugging specific update issues

## Troubleshooting

### Update Timeout

If updates are timing out:

1. Increase the timeout:
   ```yaml
   async: 1200  # 20 minutes instead of 10
   max_retries: 80
   ```

2. Check inventory source configuration:
   ```bash
   # Via Controller UI: Inventories → Sources → Edit
   # Or via awx/controller CLI
   awx inventory_sources list --name "your_source"
   ```

### Authentication Issues

```bash
# Test connectivity
ansible-playbook test_controller_connection.yml

# Or manually
curl -k -u admin:password https://controller.example.com/api/v2/ping/
```

### Some Updates Fail

The production version (`parallel_with_error_handling.yml`) handles this:
- Logs which updates failed
- Continues with successful updates
- Reports summary at the end

### Status Checks

Monitor updates in real-time:

```bash
# Watch the playbook output
ansible-playbook parallel_with_error_handling.yml -v

# Or check Controller UI
# Jobs → Inventory Updates → Running
```

## Best Practices

1. **Set appropriate timeouts**: Match your slowest inventory source
2. **Use error handling**: Production version includes comprehensive error handling
3. **Monitor first run**: Watch the first parallel run to ensure all sources update correctly
4. **Adjust check interval**: Longer intervals (20-30s) reduce API calls to Controller
5. **Use vault for credentials**: Never hardcode passwords
6. **Log results**: Production version provides detailed summaries

## Integration Examples

### Tower/Controller Workflow

Create a workflow job template that:
1. Runs this playbook to update all inventories in parallel
2. Waits for completion
3. Triggers dependent job templates

### CI/CD Pipeline

```yaml
# .github/workflows/update-inventories.yml
- name: Update Ansible inventories
  run: |
    ansible-playbook parallel_inventory_update_simple.yml
```

### Scheduled Updates

```bash
# Cron job for nightly inventory updates
0 2 * * * cd /opt/ansible && ansible-playbook parallel_with_error_handling.yml >> /var/log/inventory-updates.log 2>&1
```

## Requirements

- Ansible 2.9+ (for `async` support)
- `ansible.controller` collection (formerly `awx.awx`)
- Ansible Controller/Tower/AWX with API access
- Valid credentials with inventory update permissions

### Install Collection

```bash
ansible-galaxy collection install ansible.controller
```

## See Also

- [Ansible Async Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_async.html)
- [ansible.controller.inventory_source_update module](https://docs.ansible.com/ansible/latest/collections/ansible/controller/inventory_source_update_module.html)
- Related example: `../6_parallel_execution_via_bastion/` - General async patterns

## Quick Start

1. Edit `parallel_inventory_update_simple.yml`
2. Update the `inventory_sources` list with your inventory names
3. Set Controller credentials (environment vars or ansible.cfg)
4. Run it:
   ```bash
   ansible-playbook parallel_inventory_update_simple.yml
   ```
5. Compare timing with your current sequential approach!

## Questions?

Common questions answered:

**Q: Will this overload my Controller?**  
A: No, it's the same load as sequential updates, just compressed in time. Controller handles concurrent inventory updates well.

**Q: What if one update fails?**  
A: The production version continues with others and reports which failed. You can choose whether to fail the playbook or not.

**Q: Can I use this in a Tower/Controller job template?**  
A: Yes! Create a job template that runs this playbook. It works the same way.

**Q: How much faster is it really?**  
A: If you have N inventories that each take T seconds, sequential takes N×T, async takes ~T. So with 5 inventories, roughly 5x faster.


