# Visual Comparison: Repetitive vs Clean

## 🔴 Repetitive Approach (best_practice_playbook.yml)

```
playbook.yml (130 lines)
┌─────────────────────────────────────────┐
│ Setup                                   │
├─────────────────────────────────────────┤
│                                         │
│ Attempt 1:                              │
│   block:                                │
│     - execute operation                 │
│   rescue:                               │
│     - log error                         │
│     - clear cache                       │
│     - restart service                   │
│     - wait                              │
│   when: not succeeded                   │
│                                         │
│ Attempt 2:                              │
│   block:                                │
│     - execute operation        ← DUPLICATE
│   rescue:                               │
│     - log error                ← DUPLICATE
│     - clear cache              ← DUPLICATE
│     - restart service          ← DUPLICATE
│     - wait                     ← DUPLICATE
│   when: not succeeded                   │
│                                         │
│ Attempt 3:                              │
│   block:                                │
│     - execute operation        ← DUPLICATE
│   rescue:                               │
│     - log error                ← DUPLICATE
│     - clear cache              ← DUPLICATE
│     - restart service          ← DUPLICATE
│     - wait                     ← DUPLICATE
│   when: not succeeded                   │
│                                         │
├─────────────────────────────────────────┤
│ Cleanup                                 │
└─────────────────────────────────────────┘

Problems:
❌ Code duplicated 3 times
❌ Change in 3 places
❌ 130 lines total
```

## 🟢 Clean Approach (clean_playbook.yml + attempt_operation.yml)

```
clean_playbook.yml (40 lines)          attempt_operation.yml (70 lines)
┌─────────────────────────────┐        ┌─────────────────────────────┐
│ Setup                       │        │                             │
├─────────────────────────────┤        │ block:                      │
│                             │        │   - show attempt_number     │
│ include_tasks:              │───────>│   - execute operation       │
│   attempt_operation.yml     │  ┌────>│                             │
│ loop: [1,2,3]               │  │     │ rescue:                     │
│ loop_control:               │  │     │   - log error               │
│   loop_var: attempt_number  │  │     │   - fail if last attempt    │
│ when: not succeeded         │  │     │   - clear cache             │
│                             │  │     │   - restart service         │
│                ↑            │  │     │   - wait                    │
│                └────────────┼──┘     │                             │
│         Loops automatically │        │ set_fact:                   │
│         until success       │        │   operation_succeeded       │
│         (attempt_number     │        │                             │
│          passed via loop)   │        │                             │
│                             │        └─────────────────────────────┘
├─────────────────────────────┤                   ↑
│ Cleanup                     │                   │
└─────────────────────────────┘          Define once, use 3 times
                                         (no manual counter!)
Benefits:
✅ Code defined once
✅ Change in 1 place
✅ No manual counter management
✅ Loop variable passed automatically
✅ 110 lines total (vs 170 = 35% reduction)
✅ Scales easily to 10+ attempts
```

## Code Volume Comparison

```
Repetitive Pattern:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 170 lines
│        block/rescue #1        │        #2        │        #3        │

Clean Pattern:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 110 lines
│  main: 40  │     reusable: 70    │
```

## Scalability Comparison

### Want 5 attempts instead of 3?

**Repetitive Approach:**
```yaml
# Copy/paste 2 more block/rescue sections (50+ more lines)
# Update all 5 attempt numbers
# Test all 5 sections work identically
```

**Clean Approach:**
```yaml
# Change one line:
max_attempts: 5
# Done! ✨
```

### Want 10 attempts?

**Repetitive Approach:**
- 📝 Copy/paste 7 more times
- 🎯 ~400 lines of code
- 🐛 High chance of copy/paste errors

**Clean Approach:**
- 📝 Change `max_attempts: 10`
- 🎯 Still 110 lines of code
- 🐛 No additional error risk

## Maintenance Comparison

### Scenario: Add a new recovery step

**Repetitive Approach:**
```diff
# Update in 3 places:

Attempt 1:
  rescue:
    - clear cache
    - restart service
+   - check disk space     # Add here

Attempt 2:
  rescue:
    - clear cache
    - restart service
+   - check disk space     # Add here

Attempt 3:
  rescue:
    - clear cache
    - restart service
+   - check disk space     # Add here
```

**Clean Approach:**
```diff
# Update in 1 place:

attempt_operation.yml:
  rescue:
    - clear cache
    - restart service
+   - check disk space     # Add once, applies to all attempts
```

## Real-World Impact

| Scenario | Repetitive | Clean | Advantage |
|----------|-----------|-------|-----------|
| **Add recovery step** | Edit 3 places | Edit 1 place | 🟢 3x faster |
| **Fix a bug** | Fix in 3 places | Fix in 1 place | 🟢 3x safer |
| **Change retry count** | Copy/paste code | Change variable | 🟢 10x easier |
| **Reuse in other playbook** | Copy 130 lines | Include 1 file | 🟢 Instant |
| **Code review** | Review 130 lines | Review 85 lines | 🟢 35% faster |

## The Bottom Line

```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│  Repetitive = Good for learning                           │
│  Clean = Good for production                              │
│                                                           │
│  Use repetitive when:                                     │
│    • Learning the pattern                                 │
│    • Only 2-3 attempts needed                            │
│    • Want everything in one file                          │
│                                                           │
│  Use clean when:                                          │
│    • Building production playbooks          ⭐            │
│    • Need 4+ attempts                                     │
│    • Want maintainable code                               │
│    • Following DRY principles                             │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

## Migration Path

```
Step 1: Learn with repetitive        Step 2: Refactor to clean
        (simple_example.yml)                  (clean_playbook.yml)
        
┌─────────────────┐                  ┌─────────────────┐
│  Everything     │    Extract       │  Main playbook  │
│  in one file    │  ──────────────> │  +              │
│                 │    block/rescue  │  Separate file  │
│  Easy to read   │                  │                 │
└─────────────────┘                  └─────────────────┘
     Learning                         Production-ready
```

