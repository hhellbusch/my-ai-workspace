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
