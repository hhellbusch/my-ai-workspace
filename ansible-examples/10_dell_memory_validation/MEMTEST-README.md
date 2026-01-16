# Memory Testing Options for Red Hat CoreOS

Comprehensive guide for running memory tests on CoreOS nodes, with multiple approaches depending on your needs.

## Quick Comparison

| Method | Duration | Thoroughness | Requires Reboot | Best For |
|--------|----------|--------------|-----------------|----------|
| **memtester (toolbox)** | 5-30 min | Good | No | Quick validation, CI/CD |
| **stress-ng** | 5-15 min | Moderate | No | Stress testing, burn-in |
| **Python script** | 5-10 min | Basic | No | No dependencies, quick check |
| **BIOS Memory Test** | 30-120 min | Excellent | Yes | Thorough validation, new hardware |
| **Ignition-baked tests** | 5-30 min | Good | No (runs on first boot) | Automated deployment testing |

## Option 1: Quick Test with memtester (RECOMMENDED)

Best for: Quick validation after detecting issues

```bash
# Run the playbook
ansible-playbook -i inventory.yml quick_memtest.yml --tags memtester --ask-vault-pass

# Or manually on a node
ssh core@node
toolbox run dnf install -y memtester
toolbox run memtester 1024M 2
```

**What it tests:**
- Stuck address bits
- Random value patterns
- XOR comparison
- SUB comparison
- MUL comparison
- DIV comparison
- OR comparison
- AND comparison
- Sequential increment
- Solid bits
- Block sequential
- Checkerboard
- Bit spread
- Bit flip
- Walking ones/zeros

**Duration:** ~5-10 minutes per GB tested

**Pros:**
- No reboot required
- Userspace test (safe)
- Good coverage of common issues
- Can run while system is up

**Cons:**
- Not as thorough as BIOS test
- Can only test unallocated memory
- May miss hardware-level issues

## Option 2: Stress Testing with stress-ng

Best for: Burn-in testing, stress testing

```bash
# Run stress-ng test
ansible-playbook -i inventory.yml quick_memtest.yml --tags stress-ng --ask-vault-pass

# Or manually
toolbox run dnf install -y stress-ng
toolbox run stress-ng --vm 4 --vm-bytes 1G --vm-method all --verify --timeout 300s --metrics-brief
```

**What it tests:**
- Memory allocation/deallocation patterns
- Various memory access patterns
- Memory bandwidth
- Cache effects
- TLB effects

**Duration:** 5-15 minutes (configurable)

**Pros:**
- Multiple memory stress methods
- Catches thermal issues
- Good for burn-in
- Verification built-in

**Cons:**
- Stresses system (may affect workloads)
- Not as focused as memtester
- May cause temporary performance impact

## Option 3: Dell BIOS Memory Test (MOST THOROUGH)

Best for: New hardware validation, thorough testing

```bash
# Schedule BIOS memory test
ansible-playbook -i inventory.yml idrac_bios_memtest.yml --ask-vault-pass
```

**What it happens:**
1. Enables BIOS MemTest setting via iDRAC
2. Creates BIOS configuration job
3. Reboots server
4. POST runs comprehensive memory test
5. Results logged to SEL
6. Server boots normally

**Duration:** 30-120 minutes (depends on memory size)
- 128GB: ~30 minutes
- 512GB: ~60 minutes
- 1TB+: ~120+ minutes

**Pros:**
- Most thorough testing
- Hardware-level validation
- Catches issues memtester might miss
- Dell-certified testing

**Cons:**
- Requires reboot
- Long duration
- Takes server offline
- Increases boot time

## Option 4: Python Memory Test (NO DEPENDENCIES)

Best for: Quick check without installing tools

```bash
# Included in quick_memtest.yml
ansible-playbook -i inventory.yml quick_memtest.yml --tags python --ask-vault-pass
```

**What it tests:**
- Memory allocation
- Pattern writing (0xAA, 0x55)
- Pattern verification
- Basic read/write functionality

**Duration:** 5-10 minutes

**Pros:**
- No additional tools needed
- Python3 already on CoreOS
- Quick and simple
- Safe to run

**Cons:**
- Limited test coverage
- Basic patterns only
- Not as thorough as dedicated tools

## Option 5: Ignition Config with Baked-in Testing

Best for: Automated testing during deployment

```bash
# Generate Ignition config
ansible-playbook -i inventory.yml coreos_memtest_ignition.yml

# Use the generated config when installing CoreOS
coreos-installer install /dev/sda --ignition-file ignition_configs/memtest.ign

# After install, check results
ansible node -m shell -a "/usr/local/bin/get-memtest-results.sh" -b
```

**What it does:**
1. Installs memtester and stress-ng at first boot
2. Automatically runs tests
3. Saves results to `/var/log/memtest-results.txt`
4. Marks completion in `/var/lib/memtest-complete`

**Duration:** Adds 10-20 minutes to first boot

**Pros:**
- Fully automated
- Tests every new deployment
- Results logged for auditing
- No manual intervention

**Cons:**
- Requires custom Ignition config
- Increases first boot time
- Requires rpm-ostree layering

## Recommended Workflow for Your Scenario

Based on your situation (found memory discrepancy via dmidecode/iDRAC):

### Step 1: Quick Validation (5 minutes)

```bash
# Quick test on suspected node
ansible-playbook -i inventory.yml quick_memtest.yml \
  --limit suspected-node \
  --tags memtester \
  --ask-vault-pass
```

### Step 2: If Issues Found - Stress Test (10 minutes)

```bash
# More thorough stress test
ansible-playbook -i inventory.yml quick_memtest.yml \
  --limit suspected-node \
  --tags stress-ng \
  --ask-vault-pass
```

### Step 3: If Still Suspicious - BIOS Test (60+ minutes)

```bash
# Schedule comprehensive BIOS test
ansible-playbook -i inventory.yml idrac_bios_memtest.yml \
  --limit suspected-node \
  --ask-vault-pass
```

### Step 4: For New Deployments - Use Ignition

```bash
# Generate test config
ansible-playbook -i inventory.yml coreos_memtest_ignition.yml

# Use for all new installs
# Tests run automatically on first boot
```

## Integration with Existing Test Process

Since you mentioned you "install an image of CoreOS to run other tests":

### Option A: Add to Existing Ignition

Merge the memory test service into your existing Ignition config:

```yaml
systemd:
  units:
    # Your existing units...
    - name: memory-test.service
      enabled: true
      contents: |
        [Unit]
        Description=Memory Test
        After=network-online.target
        Before=your-other-tests.service
        
        [Service]
        Type=oneshot
        ExecStart=/usr/local/bin/run-memory-tests.sh
```

### Option B: Add as Test Stage

Add memory testing as a stage in your test pipeline:

```bash
# 1. Install CoreOS
coreos-installer install ...

# 2. Boot and run memory tests (Ansible)
ansible-playbook memory_tests.yml

# 3. Run your other tests
ansible-playbook other_tests.yml
```

### Option C: Run in Parallel with Other Tests

If your other tests aren't memory-intensive:

```yaml
- name: Run all tests in parallel
  hosts: test_nodes
  tasks:
    - name: Start memory test
      shell: /usr/local/bin/run-memory-tests.sh
      async: 1800
      poll: 0
      register: memtest_job
    
    - name: Run other tests
      include_tasks: other_tests.yml
    
    - name: Wait for memory test
      async_status:
        jid: "{{ memtest_job.ansible_job_id }}"
      register: memtest_result
      until: memtest_result.finished
      retries: 60
      delay: 30
```

## Interpreting Results

### memtester Output

```
# GOOD
Loop 1/2:
  Stuck Address       : ok
  Random Value        : ok
  Compare XOR         : ok
  ...all tests...     : ok

# BAD  
Loop 1/2:
  Stuck Address       : ok
  Random Value        : FAILURE: 0xdeadbeef != 0xcafebabe at offset 0x12345678
```

If you see FAILURE, that specific memory address is bad.

### stress-ng Output

```
# GOOD
stress-ng: info:  [12345] successful run completed in 300.00s
stress-ng: info:  [12345] stressor       bogo ops real time  usr time  sys time
stress-ng: info:  [12345] vm                 1234    300.00s    45.67s   254.33s

# BAD
stress-ng: error: [12345] stress-ng vm verification failed
```

### BIOS Test Results

Check SEL logs:

```bash
# Via playbook
ansible-playbook -i inventory.yml memory_audit.yml --limit test-node

# Via curl
curl -k -u root:password \
  "https://idrac-ip/redfish/v1/Managers/iDRAC.Embedded.1/LogServices/Sel/Entries" | \
  jq '.Members[] | select(.Message | contains("Memory"))'
```

Look for:
- "Memory test passed" ✓
- "Memory device disabled" ✗
- "Memory configuration error" ✗

## Troubleshooting

### memtester: Cannot allocate memory

**Cause:** Not enough free memory

**Solution:**
```bash
# Check available memory
free -g

# Test smaller amount
toolbox run memtester 512M 1

# Or reduce test size in playbook
-e "memtest_iterations=1"
```

### stress-ng: Package not found

**Cause:** Not in toolbox

**Solution:**
```bash
# Install in toolbox
toolbox run dnf install -y stress-ng

# Or let playbook handle it
ansible-playbook quick_memtest.yml --tags stress-ng,setup
```

### BIOS test doesn't run

**Cause:** MemTest setting not applied

**Solution:**
```bash
# Check BIOS job status
curl -k -u root:password \
  "https://idrac-ip/redfish/v1/Managers/iDRAC.Embedded.1/Jobs" | \
  jq '.Members[] | select(.Name | contains("BIOS"))'

# Manually reboot if needed
ipmitool -I lanplus -H idrac-ip -U root -P password chassis power cycle
```

### Tests complete but no errors, yet discrepancy remains

**This is your current situation!**

Possible causes:
1. DIMM is detected but reduced capacity (e.g., 64GB DIMM running as 32GB)
2. Memory remapping by firmware (bad sections hidden)
3. DIMM in wrong population order (some slots don't work in certain configs)
4. BIOS setting reducing capacity (interleaving, mirroring, sparing)

**Next steps:**
1. Check iDRAC for DIMM-specific health status
2. Review BIOS memory settings (interleaving, operating mode)
3. Check SEL for historical errors
4. Physical inspection of DIMM slot LEDs

## Performance Impact

### While Running Tests

| Test | CPU Impact | Memory Impact | I/O Impact | Production Safe? |
|------|------------|---------------|------------|------------------|
| memtester | Low | High (allocates test memory) | None | ⚠️ Use caution |
| stress-ng | High | Very High | None | ❌ Not recommended |
| Python | Low | Moderate | None | ⚠️ Use caution |
| BIOS | N/A | N/A | N/A | ❌ Server offline |

**Recommendation:** Run on nodes before adding to production cluster, or during maintenance windows.

## Files in This Example

```
10_dell_memory_validation/
├── quick_memtest.yml              # Main testing playbook (multiple methods)
├── idrac_bios_memtest.yml         # BIOS test via iDRAC
├── coreos_memtest_ignition.yml    # Generate Ignition with tests
├── MEMTEST-README.md              # This file
└── ignition_configs/              # Generated configs (created at runtime)
```

## Additional Resources

- memtester: https://pyropus.ca/software/memtester/
- stress-ng: https://kernel.ubuntu.com/~cking/stress-ng/
- Dell BIOS Settings: Dell OpenManage documentation
- CoreOS Ignition: https://coreos.github.io/ignition/
- EDAC: Linux kernel documentation

## Questions?

Common questions:

**Q: How long should I run memtester?**
A: 2-3 iterations of 1GB is usually sufficient for quick validation. For thorough testing, run overnight with more iterations.

**Q: Can I run tests on all nodes at once?**
A: Yes, but be aware of network/iDRAC load. Consider running in batches:
```bash
ansible-playbook quick_memtest.yml --forks 5
```

**Q: What if BIOS test takes too long?**
A: You can disable it after starting and results will be in SEL. Or use memtester for quicker validation.

**Q: How do I automate this for all new deployments?**
A: Use the Ignition config approach. Tests run automatically on first boot and results are logged.

---

**Created:** 2025-12-17  
**For:** Dell PowerEdge with Red Hat CoreOS  
**Part of:** ansible-examples/10_dell_memory_validation/

