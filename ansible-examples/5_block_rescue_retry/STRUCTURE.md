# Block/Rescue/Retry Pattern - Quick Reference

## Structure Overview

```
block:                          rescue:                        Result:
┌─────────────────────┐        ┌─────────────────────┐        
│ Try flaky task      │  ──┬──>│ Log error           │        If task succeeds:
│                     │    │   │ Clear cache         │          → Continue to next task
│ - API call          │    │   │ Restart service     │        
│ - Service check     │    │   │ Wait for ready      │        If task fails:
│ - Network op        │    │   │                     │          → Run rescue block
└─────────────────────┘    │   └─────────────────────┘          → Then retry or fail
     Success ↓             │            ↓                      
             │             └──── Failure                       
             │                                                 
        Continue                Retry or Fail                 
```

## The Two Patterns

### Pattern 1: Simple Block/Rescue (single attempt)

```yaml
- name: Try operation with recovery
  block:
    - name: Flaky task
      # your task here
  
  rescue:
    - name: Recovery steps
      # fix the issue
    # Playbook continues after rescue
```

**Use when:** You want to handle the failure but don't need to retry

### Pattern 2: Block/Rescue with Retry (multiple attempts)

```yaml
- name: Attempt 1
  block: [task]
  rescue: [recovery]
  when: not succeeded

- name: Attempt 2
  block: [task]
  rescue: [recovery]
  when: not succeeded

- name: Attempt 3 (final)
  block: [task]
  rescue: [fail permanently]
  when: not succeeded
```

**Use when:** Task might succeed after recovery (common for flaky services)

## Real-World Example

```yaml
- name: Deploy to production with automatic recovery
  block:
    - name: Deploy application
      shell: ./deploy.sh
    
    - name: Verify health endpoint
      uri:
        url: http://localhost:8080/health
        status_code: 200
  
  rescue:
    - name: Rollback deployment
      shell: ./rollback.sh
    
    - name: Clear application cache
      file:
        path: /var/cache/myapp
        state: absent
    
    - name: Restart application server
      systemd:
        name: myapp
        state: restarted
    
    - name: Wait for service to be ready
      wait_for:
        port: 8080
        delay: 10
```

## Files in This Directory

| File | Purpose | When to Use |
|------|---------|-------------|
| `simple_example.yml` | Basic block/rescue | Learning the pattern |
| `clean_playbook.yml` | DRY retry logic (recommended) | Production use ⭐ |
| `best_practice_playbook.yml` | Explicit retry logic | Learning full flow |
| `attempt_operation.yml` | Reusable component | Used by clean_playbook |
| `flaky_task.yml` | Simulated flaky task | Testing/demos |
| `recovery_tasks.yml` | Recovery examples | Reference |

## Quick Start

```bash
# 1. Understand the basics
ansible-playbook simple_example.yml

# 2. See retry in action (recommended for production)
ansible-playbook clean_playbook.yml

# 3. See explicit unrolled version (educational)
ansible-playbook best_practice_playbook.yml

# 4. Adapt to your needs
# - Copy clean_playbook.yml and attempt_operation.yml
# - Replace flaky task with your operation
# - Replace recovery steps with your fixes
# - Adjust max_attempts as needed
```

## Common Recovery Actions

| Problem | Recovery Action |
|---------|----------------|
| API rate limit | `pause: seconds: 60` |
| Stale cache | `file: path=/var/cache state=absent` |
| Service crashed | `systemd: name=svc state=restarted` |
| Connection pool full | Clear connections, restart |
| Lock file exists | `file: path=/var/lock/app state=absent` |
| Out of memory | Restart service, clear temp files |
| Cold start timeout | Wait longer with `wait_for` |

## Comparison with Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| `block/rescue` ✅ | Clean, explicit, modern | Slightly more verbose |
| `ignore_errors: yes` | Simple | Hides problems, no recovery |
| `failed_when: false` | Simple | Same as ignore_errors |
| `until` loop | Automatic retry | Can't do recovery between attempts |

## Key Takeaway

**The power of block/rescue is the rescue block!**

Don't just retry blindly. Use the rescue block to:
1. **Log** what went wrong
2. **Fix** the underlying issue
3. **Prepare** the system for retry
4. **Fail gracefully** if recovery impossible

