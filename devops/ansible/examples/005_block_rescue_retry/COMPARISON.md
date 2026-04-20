# Implementation Comparison: Repetitive vs. DRY

## The Problem with Repetition

The `best_practice_playbook.yml` repeats the same block/rescue code 3 times:

```yaml
# Attempt 1
- name: Attempt 1
  block:
    - name: Execute flaky operation
      # ... task code ...
  rescue:
    - name: Recovery steps
      # ... recovery code ...
  when: not operation_succeeded

# Attempt 2 - EXACT SAME CODE
- name: Attempt 2
  block:
    - name: Execute flaky operation
      # ... DUPLICATE task code ...
  rescue:
    - name: Recovery steps
      # ... DUPLICATE recovery code ...
  when: not operation_succeeded

# Attempt 3 - EXACT SAME CODE AGAIN
- name: Attempt 3
  block:
    - name: Execute flaky operation
      # ... DUPLICATE task code ...
  rescue:
    - name: Recovery steps
      # ... DUPLICATE recovery code ...
  when: not operation_succeeded
```

**Problems:**
- ❌ Violates DRY (Don't Repeat Yourself)
- ❌ Hard to maintain (change in 3 places)
- ❌ Verbose for higher retry counts
- ❌ Error-prone when making changes

## The Clean Solution

The `clean_playbook.yml` uses `include_tasks` with a loop:

### Main Playbook (`clean_playbook.yml`)

```yaml
- name: Attempt operation with recovery (will retry up to {{ max_attempts }} times)
  ansible.builtin.include_tasks: attempt_operation.yml
  loop: "{{ range(1, max_attempts + 1) | list }}"
  loop_control:
    loop_var: attempt_number
  when: not operation_succeeded
```

**That's it!** Just 6 lines instead of 60+

**Note:** The `loop_control` passes the current attempt number to the included task, eliminating the need for manual counter management.

### Separate File (`attempt_operation.yml`)

```yaml
- name: Perform operation with automatic recovery on failure
  block:
    - name: Show current attempt
      debug:
        msg: "🔄 Attempt {{ attempt_number }}/{{ max_attempts }}"
    
    - name: Execute the flaky operation
      # Your task here (defined once)
  
  rescue:
    - name: Log failure
      debug:
        msg: "⚠️  Attempt {{ attempt_number }}/{{ max_attempts }} failed"
    
    - name: Check if this was the last attempt
      fail:
        msg: "❌ All {{ max_attempts }} attempts exhausted."
      when: attempt_number | int >= max_attempts
    
    - name: Recovery steps
      # Your recovery here (defined once)
```

**Benefits:**
- ✅ DRY - define logic once
- ✅ Easy to maintain - change in one place
- ✅ Scales easily to any number of retries
- ✅ Reusable across playbooks

## Side-by-Side Comparison

| Aspect | Repetitive (`best_practice_playbook.yml`) | Clean (`clean_playbook.yml`) |
|--------|------------------------------------------|------------------------------|
| **Lines of code** | ~170 lines | ~45 lines (75% reduction) |
| **Repetition** | Block/rescue x3 | Block/rescue x1 |
| **Counter management** | Manual with `set_fact` | Automatic via `loop_control` |
| **Maintenance** | Update 3 places | Update 1 place |
| **Readability** | Verbose but explicit | Concise and clear |
| **Scalability** | Add more attempts = more copy/paste | Change `max_attempts` variable |
| **Best for** | Learning, seeing full flow | Production use |

## When to Use Each

### Use Repetitive Pattern When:
- Learning/teaching the concept
- You want everything visible in one file
- Different logic needed per attempt
- Only 2-3 attempts needed

### Use Clean Pattern When:
- Production code
- Same logic for all attempts
- Need to scale (4+ attempts)
- DRY principles matter
- Reusing across multiple playbooks

## Real-World Example: Clean Pattern

**Main playbook:**
```yaml
- name: Deploy with automatic rollback and retry
  ansible.builtin.include_tasks: deploy_with_recovery.yml
  loop: "{{ range(1, 5 + 1) | list }}"  # 5 attempts
  when: not deploy_succeeded
```

**deploy_with_recovery.yml:**
```yaml
- name: Deploy application
  block:
    - name: Show attempt
      debug:
        msg: "Deployment attempt {{ attempt_number }}/5"
    
    - name: Deploy code
      shell: ./deploy.sh
    
    - name: Run migrations
      shell: ./migrate.sh
    
    - name: Verify health
      uri:
        url: http://localhost:8080/health
        status_code: 200
    
    - set_fact:
        deploy_succeeded: true
  
  rescue:
    - name: Check if final attempt
      fail:
        msg: "Deployment failed after 5 attempts"
      when: attempt_number | int >= 5
    
    - name: Rollback
      shell: ./rollback.sh
    
    - name: Clear cache
      file: path=/var/cache/app state=absent
    
    - name: Restart services
      systemd: name=myapp state=restarted
    
    - pause: seconds=10
```

**Result:** Clean, maintainable, reusable deployment with automatic recovery!

## Migration Guide

### From Repetitive to Clean:

1. **Extract the block/rescue** to a new file:
   ```bash
   # Create attempt_operation.yml with the block/rescue code
   ```

2. **Replace repeated blocks** with single include:
   ```yaml
   - include_tasks: attempt_operation.yml
     loop: "{{ range(1, max_attempts + 1) | list }}"
     loop_control:
       loop_var: attempt_number
     when: not operation_succeeded
   ```

3. **Update the included file** to use `attempt_number` instead of manual counter:
   ```yaml
   # Replace: {{ current_attempt }}
   # With:    {{ attempt_number }}
   ```

4. **Test** to ensure behavior is identical

5. **Adjust** `max_attempts` as needed

## The Bottom Line

**Both patterns work identically** - they produce the same results.

Choose based on your priorities:
- **Repetitive** = Explicit and educational
- **Clean** = Maintainable and scalable

For production code, **clean pattern is recommended**. 🎯

