# Execution Pattern Comparison

## Visual Timeline Comparison

Assume you have 5 nodes and 3 tasks, each taking 1 minute.

### Serial Execution (Current)
```
Node1: [Task1] [Task2] [Task3]
Node2:                         [Task1] [Task2] [Task3]
Node3:                                                 [Task1] [Task2] [Task3]
Node4:                                                                         [Task1] [Task2] [Task3]
Node5:                                                                                                 [Task1] [Task2] [Task3]
Time:  0-----1-----2-----3-----4-----5-----6-----7-----8-----9----10----11----12----13----14----15 minutes
```
**Total Time: 15 minutes**

### Parallel with Forks (forks=5)
```
Node1: [Task1] [Task2] [Task3]
Node2: [Task1] [Task2] [Task3]
Node3: [Task1] [Task2] [Task3]
Node4: [Task1] [Task2] [Task3]
Node5: [Task1] [Task2] [Task3]
Time:  0-----1-----2-----3 minutes
```
**Total Time: 3 minutes** (5x faster!)

### Parallel with Async
```
Node1: [Task1]
       [Task2]
       [Task3] (all running simultaneously)
Node2: [Task1]
       [Task2]
       [Task3] (all running simultaneously)
... (all nodes running all tasks simultaneously)
Time:  0-----1 minute
```
**Total Time: 1 minute** (15x faster!)

### Strategy: Free
```
Node1: [Task1] [Task2] [Task3] ← Fast host, finishes first
Node2: [Task1] [Task2]     [Task3] ← Medium speed
Node3: [Task1]    [Task2]        [Task3] ← Slow host
Node4: [Task1] [Task2] [Task3] ← Fast host
Node5: [Task1] [Task2]  [Task3] ← Medium speed
Time:  0-----1-----2-----3-----4 minutes
```
**Total Time: 4 minutes** (depends on slowest host)

## When to Use Each Approach

### Serial Execution
```yaml
serial: 1
```
**Use when:**
- Tasks must complete in specific order across all hosts
- You're doing rolling updates (can't have all hosts down)
- Tasks modify shared resources

**Example:** Rolling restart where only one service at a time can be down

---

### Parallel Forks
```yaml
# In playbook (default behavior) or ansible.cfg
forks = 20
```
**Use when:**
- Tasks are independent across hosts
- Quick tasks that don't need async overhead
- Default choice for most playbooks

**Example:** Gathering facts, running health checks, collecting logs

---

### Async Execution
```yaml
- name: Long running task
  command: /long/running/command
  async: 3600
  poll: 0
  register: job
```
**Use when:**
- Tasks take a long time (minutes to hours)
- Multiple independent tasks per host
- Want maximum parallelism

**Example:** System updates, database backups, large file transfers

---

### Strategy: Free
```yaml
strategy: free
```
**Use when:**
- Hosts have very different performance characteristics
- Don't need synchronized task completion
- Want absolute maximum speed

**Example:** Opportunistic updates where fast hosts shouldn't wait

## Performance Calculations

For **N hosts** and **T tasks** taking **M minutes each**:

| Method | Time Complexity | Example (5 hosts, 3 tasks, 1 min each) |
|--------|----------------|----------------------------------------|
| Serial | `N × T × M` | 5 × 3 × 1 = **15 minutes** |
| Forks | `T × M` (if forks ≥ N) | 3 × 1 = **3 minutes** |
| Async | `max(M)` | max(1,1,1) = **1 minute** |
| Free | `T × M` (slowest host) | ~**3-4 minutes** |

## Code Complexity

| Method | Setup Complexity | Debugging Ease | Maintenance |
|--------|-----------------|----------------|-------------|
| Serial | ⭐ Very Easy | ⭐⭐⭐ Easy | Low |
| Forks | ⭐ Very Easy | ⭐⭐⭐ Easy | Low |
| Async | ⭐⭐⭐ Moderate | ⭐⭐ Moderate | Medium |
| Free | ⭐ Very Easy | ⭐ Difficult | Low |

## Recommendations

1. **Start with Forks**: For most use cases, just remove `serial: 1` and increase forks
   ```yaml
   # ansible.cfg
   [defaults]
   forks = 20
   ```

2. **Use Async for Long Tasks**: If individual tasks take >5 minutes
   ```yaml
   async: 3600
   poll: 0
   ```

3. **Avoid Strategy: Free unless necessary**: Hard to debug and output is chaotic

4. **Combine Approaches**: Use async for long tasks within a forks-based playbook
   ```yaml
   # Quick checks with forks
   - name: Health check
     command: systemctl status myservice
   
   # Long update with async
   - name: Update system
     yum: name=* state=latest
     async: 3600
     poll: 0
   ```

## Testing Your Changes

Always test parallelism changes:

```bash
# Time your current serial playbook
time ansible-playbook -i inventory.yml serial_execution.yml

# Time with forks
time ansible-playbook -i inventory.yml parallel_forks.yml --forks 10

# Time with async
time ansible-playbook -i inventory.yml parallel_async.yml

# Compare results
```

