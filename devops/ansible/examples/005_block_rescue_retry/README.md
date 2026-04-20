# Block/Rescue with Recovery and Retry

This example demonstrates how to handle flaky tasks that sometimes fail, with automatic recovery and retry logic.

## The Pattern

When dealing with flaky operations (APIs, network calls, services that need warm-up), you want to:

1. **Try** the operation in a `block`
2. **Catch** failures in a `rescue` block
3. **Recover** by fixing the underlying issue (restart service, clear cache, etc.)
4. **Retry** the operation
5. **Give up** gracefully after maximum attempts

## Files in This Example

### 1. `simple_example.yml` - Start Here! 🎯

The simplest pattern showing block/rescue with recovery steps. Perfect for understanding the basics.

```bash
ansible-playbook simple_example.yml
```

**Shows:**
- Basic block/rescue structure
- Recovery steps when task fails
- How to continue execution after handled failures

### 2. `clean_playbook.yml` ⭐ - **Recommended for Production**

The cleanest, most maintainable implementation using DRY principles. Uses `include_tasks` with a loop to avoid repetition.

```bash
ansible-playbook clean_playbook.yml
```

**Shows:**
- DRY (Don't Repeat Yourself) approach
- Reusable block/rescue in separate file
- Easy to scale (change `max_attempts`)
- Production-ready pattern

**Files:**
- `clean_playbook.yml` - Main playbook (concise!)
- `attempt_operation.yml` - Reusable block/rescue logic

**Key Features:**
- Uses `loop_control` to pass `attempt_number` to the included task
- No manual counter management needed
- Loop automatically exits when `operation_succeeded` becomes true

### 3. `best_practice_playbook.yml` - Educational Version

Complete pattern showing retry logic explicitly. Good for learning but repetitive.

```bash
ansible-playbook best_practice_playbook.yml
```

**Shows:**
- Multiple retry attempts (explicitly written out)
- Recovery between attempts
- Tracking success/failure state
- Full flow visible in one file

**Note:** This version repeats code 3 times for clarity. See `COMPARISON.md` for pros/cons vs clean approach.

**Expected Output:**
```
🔄 Attempt 1/3
⚠️  Attempt 1 failed. Starting recovery...
🔧 Clearing cache...
🔄 Restarting service...

🔄 Attempt 2/3
⚠️  Attempt 2 failed. Starting recovery...
🔧 Clearing cache...
🔄 Restarting service...

🔄 Attempt 3/3 (final attempt)
✅ Operation succeeded!
```

### 4. Component Files (Reference)

These files show alternative patterns and detailed recovery examples:

- `flaky_task.yml` - Simulates intermittent failures
- `recovery_tasks.yml` - Detailed recovery step examples
- `playbook.yml` - Alternative implementation using recursive include
- `simple_playbook.yml` - Basic retry attempt (note: retries don't work on blocks)

## Basic Structure

```yaml
- name: Attempt operation with recovery
  block:
    # Your flaky task here
    - name: Call API
      uri:
        url: https://api.example.com
    
  rescue:
    # Recovery steps
    - name: Clear cache
      file: path=/var/cache/app state=absent
    
    - name: Restart service
      systemd: name=myservice state=restarted
    
    - name: Wait for readiness
      wait_for: port=8080 delay=5
```

## Real-World Scenarios

### 1. Flaky API with Rate Limiting

```yaml
- name: Attempt 1
  block:
    - name: Call rate-limited API
      uri:
        url: https://api.example.com/data
        headers:
          Authorization: "Bearer {{ token }}"
      register: api_response
  rescue:
    - name: Wait for rate limit reset
      pause:
        seconds: 60
  when: not api_succeeded

- name: Attempt 2
  block:
    - name: Retry API call
      uri:
        url: https://api.example.com/data
        headers:
          Authorization: "Bearer {{ token }}"
  rescue:
    - name: Give up
      fail:
        msg: "API still unavailable after retry"
  when: not api_succeeded
```

### 2. Database Connection Issues

```yaml
- name: Try database operation
  block:
    - name: Execute query
      postgresql_query:
        db: mydb
        query: "SELECT * FROM users WHERE active = true"
  rescue:
    - name: Clear connection pool
      shell: psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity"
    
    - name: Restart PostgreSQL
      systemd:
        name: postgresql
        state: restarted
    
    - name: Wait for database
      wait_for:
        port: 5432
        delay: 5
```

### 3. Service Needs Warm-up

```yaml
- name: Call service (may need warm-up)
  block:
    - name: Hit service endpoint
      uri:
        url: http://localhost:8080/process
        status_code: 200
  rescue:
    - name: Service might be cold-starting
      debug:
        msg: "Service not ready, waiting for warm-up..."
    
    - name: Wait for warm-up
      wait_for:
        port: 8080
        delay: 10
        timeout: 60
```

## Key Design Principles

1. **Block/Rescue > ignore_errors** - More maintainable and clearer intent
2. **Fix the root cause** - Don't just blindly retry the same failure
3. **Set maximum attempts** - Prevent infinite retry loops
4. **Add delays** - Give systems time to recover
5. **Log everything** - Essential for debugging intermittent issues
6. **Fail gracefully** - Provide clear error messages on final failure

## Pattern Variations

### Option A: Sequential Attempts (Used in best_practice_playbook.yml)
```yaml
- name: Attempt 1
  block: [task]
  rescue: [recovery]
  when: not succeeded

- name: Attempt 2
  block: [task]
  rescue: [recovery]
  when: not succeeded

- name: Attempt 3
  block: [task]
  rescue: [fail]
  when: not succeeded
```

**Pros:** Clear, explicit, easy to customize per-attempt
**Cons:** More verbose for many attempts

### Option B: Single Block, Manual Iteration
```yaml
# Put block/rescue in separate file
# Use include_tasks multiple times
```

**Pros:** More DRY (Don't Repeat Yourself)
**Cons:** Harder to customize individual attempts

## Ansible Limitations Note

⚠️ **Important:** You cannot use `loop`, `until`, or `retries` directly on a `block`. 
This is an Ansible limitation. The patterns in this example work around this by:
- Using sequential block/rescue statements
- Using `when` conditions to skip on success
- Using `include_tasks` for reusable block/rescue logic

## Testing the Examples

```bash
# Run the simple example first
ansible-playbook simple_example.yml

# Then try the full retry pattern
ansible-playbook best_practice_playbook.yml

# All examples run against localhost, no inventory needed
```

## Adapting to Your Use Case

1. Replace the simulated "flaky task" with your actual operation
2. Replace the recovery steps with your actual recovery logic
3. Adjust the number of attempts (currently 3)
4. Adjust the wait time between attempts
5. Customize error messages and logging

## When to Use This Pattern

✅ **Good for:**
- External API calls that sometimes timeout
- Services that need warm-up or restart
- Network operations with transient failures
- Operations that can be fixed by clearing cache/state

❌ **Not good for:**
- Tasks that will always fail (waste of time)
- Operations that are not idempotent
- Tasks where retry could cause data corruption
