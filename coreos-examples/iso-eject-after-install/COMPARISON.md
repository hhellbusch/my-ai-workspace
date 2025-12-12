# Comparison of Ejection Methods

This document helps you choose the right ejection method for your use case.

## Quick Decision Matrix

| Scenario | Recommended File | Notes |
|----------|-----------------|-------|
| Physical server, simple setup | `basic-eject.bu` | Most straightforward |
| VMware virtual machine | `vmware-eject.bu` | Uses VMware tools |
| Remote management (iLO/iDRAC) | `redfish-eject.bu` | Requires network access |
| Production environment | `robust-eject.bu` | Multiple fallback methods |
| Testing/validation needed | `delayed-eject.bu` | Time to verify before eject |

## Detailed Comparison

### basic-eject.bu

**Pros:**
- Simple and straightforward
- Minimal overhead
- Works on most physical hardware
- Easy to understand and modify

**Cons:**
- No fallback mechanisms
- Single device path assumption (/dev/sr0)
- No logging or error handling

**Best for:**
- Physical servers
- Simple installations
- Known hardware configurations

### vmware-eject.bu

**Pros:**
- Native VMware integration
- Cleaner ejection in virtual environment
- Includes fallback to standard eject
- Works with VMware ESXi, Workstation, Fusion

**Cons:**
- Requires VMware tools
- VMware-specific
- May have delays waiting for tools

**Best for:**
- VMware environments
- Virtual machine deployments
- Automated VMware workflows

### redfish-eject.bu

**Pros:**
- Works from within the OS
- No physical access needed
- Vendor-agnostic (iLO, iDRAC, XCC, etc.)
- Useful for remote datacenters

**Cons:**
- Requires network connectivity
- Needs BMC credentials
- May need endpoint URL adjustments
- Security considerations (storing credentials)

**Best for:**
- Remote installations
- Datacenter environments
- Automated provisioning pipelines
- HPE, Dell, Lenovo servers with management controllers

### robust-eject.bu

**Pros:**
- Multiple fallback methods
- Comprehensive logging
- Handles edge cases
- Detailed error reporting
- Attempts multiple device paths
- Includes SCSI commands

**Cons:**
- More complex
- Longer script
- May take more time to complete

**Best for:**
- Production environments
- Mixed hardware environments
- When reliability is critical
- Automated deployments at scale

### delayed-eject.bu

**Pros:**
- Time to verify installation
- System health checks
- Configurable delay
- Can be cancelled
- Prevents premature ejection

**Cons:**
- Delayed feedback
- Requires monitoring
- More complex validation logic

**Best for:**
- Testing and validation
- Critical installations
- When verification is needed
- Training/demonstration purposes

## Customization Guide

### Changing the Delay

For `delayed-eject.bu`, modify the environment variable:

```ini
Environment="EJECT_DELAY=120"  # 2 minutes instead of 60 seconds
```

### Using Different Device Paths

If your CD-ROM is not `/dev/sr0`:

```bash
ExecStart=/usr/bin/eject /dev/sr1
```

Or modify the script to check your specific device.

### Adding Logging

For better troubleshooting:

```ini
[Service]
StandardOutput=journal+console
StandardError=journal+console
```

Then view logs:
```bash
journalctl -u eject-install-media.service
```

### Adjusting Retry Behavior

```ini
[Service]
Restart=on-failure
RestartSec=30
StartLimitBurst=5
```

## Security Considerations

### redfish-eject.bu

The Redfish example stores BMC credentials in plain text. For production:

1. **Use vault or secrets management:**
   ```bash
   # Fetch from HashiCorp Vault, AWS Secrets Manager, etc.
   ```

2. **Restrict file permissions:**
   ```yaml
   mode: 0600  # Only root can read
   ```

3. **Remove credentials after use:**
   ```bash
   ExecStartPost=/usr/bin/shred -u /etc/bmc-credentials.conf
   ```

4. **Use temporary credentials:**
   Create a BMC user specifically for ejection and delete after

## Performance Impact

All methods have minimal performance impact:

- **CPU**: Negligible (oneshot service)
- **Memory**: <1MB during execution
- **Disk I/O**: Minimal (stamp file creation only)
- **Network**: Only `redfish-eject.bu` uses network

## Testing Recommendations

1. **Start with basic:** Test `basic-eject.bu` first
2. **Lab environment:** Test in non-production first
3. **Manual verification:** Check eject works manually before automating
4. **Log review:** Always check journald logs after first boot

```bash
# Check if service ran
systemctl status eject-install-media.service

# View logs
journalctl -u eject-install-media.service -b

# Check stamp file
ls -l /var/lib/install-media-ejected
```

## Combining Methods

You can combine methods by creating multiple services with different dependencies:

```yaml
systemd:
  units:
    # Try Redfish first
    - name: eject-redfish.service
      enabled: true
      # ... Redfish config ...
    
    # Fallback to local eject if Redfish fails
    - name: eject-local.service
      enabled: true
      contents: |
        [Unit]
        After=eject-redfish.service
        ConditionPathExists=!/var/lib/install-media-ejected
        # ... local eject config ...
```

