# Debug Toolbox Container - Index

## Quick Start

**Need to troubleshoot network or connectivity from a pod perspective?**

1. **Create privileged toolbox container:**
   ```bash
   oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true
   ```

2. **Install diagnostic tools:**
   ```bash
   dnf install -y mtr traceroute tcpdump nmap-ncat bind-utils
   ```

3. **Run your diagnostics:**
   - MTU testing: `mtr -s 1472 <target-ip>`
   - DNS testing: `nslookup <hostname>`
   - Port testing: `nc -zv <target-ip> <port>`

4. **Clean up when done:**
   ```bash
   exit
   oc delete pod toolbox
   ```

## Files in This Guide

### [README.md](./README.md)
**Comprehensive guide** for using ephemeral debug containers with Red Hat UBI toolbox.

**Use when:**
- You need to understand when and why to use privileged containers
- You want detailed explanations of diagnostic techniques
- You need real-world troubleshooting examples
- You're learning systematic network diagnostics

**Contains:**
- When to use debug toolbox containers
- Privileged vs standard containers
- Complete installation and usage instructions
- Common troubleshooting tasks (MTU, DNS, packet capture)
- Security considerations and best practices
- 4 detailed real-world examples

### [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
**Quick command reference** with copy-paste ready commands.

**Use when:**
- You already know what you need to do
- You need quick syntax reminders
- You want one-liners for common tasks
- You're in a hurry

**Contains:**
- Container creation commands
- Package installation commands
- Common diagnostic one-liners
- File copy operations
- Troubleshooting quick fixes

## Use Cases

### When to Use Debug Toolbox

| Need | Use Toolbox? | Alternative |
|------|--------------|-------------|
| Test network from pod network | ✅ Yes | - |
| Install diagnostic tools temporarily | ✅ Yes | - |
| MTU testing from cluster | ✅ Yes | `oc debug node` for host-level |
| DNS resolution from pod perspective | ✅ Yes | `oc exec` into app pod if safe |
| Packet capture from pod network | ✅ Yes (privileged) | `oc debug node` for host-level |
| Test connectivity without modifying apps | ✅ Yes | - |
| Node-level diagnostics | ❌ No | Use `oc debug node/<node-name>` |
| Debug specific application | ❌ Maybe | Use `oc debug deployment/<name>` |

## Common Workflows

### Workflow 1: MTU Troubleshooting
```
┌─────────────────────────────────────────┐
│ SSH/connectivity issues from pods?     │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 1. Create privileged toolbox            │
│    oc run -it toolbox ... --privileged  │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 2. Install mtr                           │
│    dnf install -y mtr                    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 3. Test different MTU sizes              │
│    mtr -s 1472 <ip>  # 1500 MTU         │
│    mtr -s 1372 <ip>  # 1400 MTU         │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 4. If 1400 works but 1500 doesn't:      │
│    MTU mismatch confirmed                │
│    See: ../aap-ssh-mtu-issues/           │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 5. Clean up                              │
│    exit; oc delete pod toolbox           │
└─────────────────────────────────────────┘
```

### Workflow 2: DNS Investigation
```
┌─────────────────────────────────────────┐
│ Application can't resolve hostnames?    │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 1. Create toolbox in same namespace     │
│    oc run -it toolbox -n <ns> ...       │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 2. Install DNS tools                     │
│    dnf install -y bind-utils             │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 3. Test resolution                       │
│    nslookup <hostname>                   │
│    dig <hostname>                        │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 4. Check DNS config                      │
│    cat /etc/resolv.conf                  │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 5. Test specific DNS servers             │
│    dig @<dns-ip> <hostname>              │
└─────────────────────────────────────────┘
```

### Workflow 3: Packet Capture
```
┌─────────────────────────────────────────┐
│ Need to see actual network traffic?     │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 1. Create privileged toolbox             │
│    oc run -it toolbox ... --privileged   │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 2. Install tcpdump                       │
│    dnf install -y tcpdump                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 3. Start capture                         │
│    tcpdump -i any -w /tmp/cap.pcap      │
│              'host <target-ip>'          │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 4. Reproduce issue, then Ctrl+C         │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│ 5. Copy file and analyze                 │
│    oc cp toolbox:/tmp/cap.pcap ./        │
│    wireshark cap.pcap                    │
└─────────────────────────────────────────┘
```

## Quick Decision Tree

```
Do you need to troubleshoot from pod network perspective?
│
├─ YES: Need network diagnostics
│   │
│   ├─ Can it run without special permissions?
│   │   ├─ YES: Basic ping, curl, wget
│   │   │   └─ Use: oc run -it toolbox ...
│   │   │
│   │   └─ NO: Need mtr, tcpdump, traceroute
│   │       └─ Use: oc run -it toolbox ... --privileged=true
│   │
│   └─ Specific use cases:
│       ├─ MTU testing → Privileged + mtr
│       ├─ DNS testing → Standard + bind-utils
│       ├─ Packet capture → Privileged + tcpdump
│       └─ Port testing → Standard + nc
│
└─ NO: Need node-level access
    └─ Use: oc debug node/<node-name>
```

## Essential Commands at a Glance

```bash
# Create privileged toolbox
oc run -it toolbox --image=registry.redhat.io/ubi10/toolbox:10.1 --privileged=true

# Install all common tools
dnf install -y mtr traceroute tcpdump nmap-ncat bind-utils iperf3

# Quick MTU test
ping -M do -s 1472 <target-ip> -c 4

# Quick DNS test
nslookup <hostname>

# Quick port test
nc -zv <target-ip> <port>

# Clean up
exit; oc delete pod toolbox
```

## Troubleshooting Quick Index

| Problem | Quick Check | Solution | Reference |
|---------|-------------|----------|-----------|
| Package install fails | Error mentions "unpacking rpm" | Use `--privileged=true` flag | [README.md](./README.md) - Troubleshooting |
| Container exits immediately | No `-it` flags used | Recreate with `-it` flags | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) |
| Can't create privileged pod | Check `oc auth can-i create pods/privileged` | Request permissions or use `oc debug node` | [README.md](./README.md) - Alternative |
| Network not accessible | Pod might not be Running | Check `oc get pod toolbox -o wide` | [README.md](./README.md) - Troubleshooting |
| Need to reconnect | Container already exists | Use `oc attach toolbox -it` | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) |

## File Sizes and Reading Times

- **QUICK-REFERENCE.md** - ~5 minutes read, use for quick lookups
- **README.md** - ~20 minutes read, comprehensive reference
- **INDEX.md** (this file) - ~3 minutes read, navigation guide

## Tips for Using Debug Toolbox

1. **Always use privileged mode for diagnostics** - Most useful tools require it
2. **Delete immediately after use** - Privileged containers are security-sensitive
3. **Use specific namespace** - Test from same network context as your application
4. **Save diagnostic output** - Copy files out before deleting container
5. **Install tools once** - Install all needed tools before starting diagnostics
6. **One container at a time** - Delete old toolbox before creating new one

## Real-World Examples

The [README.md](./README.md) includes detailed examples for:

1. **MTU Issue Troubleshooting** - Finding MTU mismatches causing SSH failures
2. **DNS Resolution Issues** - Testing DNS from application namespace
3. **Network Path Investigation** - Using mtr to find intermittent connectivity issues
4. **Packet Capture** - Capturing API traffic for debugging

## Security Considerations

⚠️ **Important:** Privileged containers have elevated permissions:
- Can access host resources
- Bypass security constraints
- Should only be used for troubleshooting
- Must be deleted immediately after use
- Should not be left running in production

See [README.md](./README.md) for complete security discussion.

## Related Documentation

This guide works well with:

- **[../aap-ssh-mtu-issues/](../aap-ssh-mtu-issues/)** - MTU troubleshooting using toolbox
- **[../coreos-networking-issues/](../coreos-networking-issues/)** - Node-level network issues
- **[../api-slowness-web-console/](../api-slowness-web-console/)** - API connectivity testing

## Available UBI Images

```bash
# Latest (RHEL 10-based) - Recommended
registry.redhat.io/ubi10/toolbox:10.1

# Previous stable (RHEL 9-based)
registry.redhat.io/ubi9/toolbox:9.4

# Legacy (RHEL 8-based)
registry.redhat.io/ubi8/toolbox:8.10
```

## Getting Additional Help

If you're still stuck:

1. **Check permissions:**
   ```bash
   oc auth can-i create pods
   oc auth can-i create pods/privileged
   ```

2. **Try alternative approach:**
   ```bash
   # Node-level debugging instead
   oc debug node/<node-name>
   chroot /host
   ```

3. **Verify pod status:**
   ```bash
   oc get pod toolbox -o yaml
   oc describe pod toolbox
   oc logs toolbox
   ```

## Contributing

Found an issue or have a suggestion? This is part of a personal knowledge base, but feedback is always appreciated.

---

**AI Disclosure:** This documentation was created with AI assistance to provide comprehensive guidance for OpenShift debug containers.
