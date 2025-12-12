# RHEL CoreOS - Auto-Eject Installation Media

This directory contains examples for automatically ejecting installation media (ISO) after RHEL CoreOS completes its installation.

## Overview

When installing RHEL CoreOS from an ISO, you often want the media to eject automatically after installation to prevent the system from attempting to boot from the install media again. This is accomplished using Ignition to configure systemd services that run after the first successful boot.

## Examples Included

1. **basic-eject.ign** - Simple eject command for physical hardware
2. **vmware-eject.ign** - VMware-specific ejection using vmware-tools
3. **redfish-eject.ign** - Remote ejection via Redfish API (iLO, iDRAC, etc.)
4. **robust-eject.ign** - Comprehensive solution with multiple fallback methods
5. **delayed-eject.ign** - Eject with configurable delay and verification

## How It Works

1. Ignition configuration is embedded into the ISO or provided via kernel parameters
2. During first boot, Ignition provisions the system including systemd services
3. A oneshot systemd service runs after `multi-user.target` is reached
4. The service attempts to eject the installation media
5. A stamp file is created to prevent re-execution on subsequent boots

## Usage

### Convert YAML to Ignition JSON

These examples are provided in YAML format (Butane syntax). Convert them to Ignition JSON before use:

```bash
# Install butane (if not already installed)
# For Fedora/RHEL:
sudo dnf install butane

# For other systems, download from: https://github.com/coreos/butane/releases

# Convert YAML to Ignition JSON
butane --pretty --strict basic-eject.bu -o basic-eject.ign
```

### Embed in ISO

```bash
# Create custom CoreOS ISO with embedded Ignition
coreos-installer iso ignition embed rhcos.iso -i basic-eject.ign
```

### Provide via Kernel Parameter

```bash
# At boot prompt
ignition.config.url=http://example.com/config.ign
```

## Testing

Before deploying to production:

1. Test in a VM first
2. Verify the eject command works manually: `eject /dev/sr0`
3. Check systemd service status: `systemctl status eject-install-media.service`
4. Verify stamp file creation: `ls -l /var/lib/install-media-ejected`

## Troubleshooting

### Service didn't run
```bash
# Check service status
systemctl status eject-install-media.service

# Check journal logs
journalctl -u eject-install-media.service

# Manually trigger (for testing)
systemctl start eject-install-media.service
```

### CD-ROM not ejecting
```bash
# Check if media is mounted
mount | grep sr0

# Unmount if necessary
umount /dev/sr0

# Try force eject
eject -f /dev/sr0
```

## Important Notes

- **Device paths**: `/dev/sr0` is typically the first CD/DVD drive. Adjust if your system differs.
- **Virtual machines**: May require hypervisor-specific commands or tools.
- **One-time execution**: Uses condition flags to prevent running on every boot.
- **Timing**: Services wait for `multi-user.target` to ensure system is fully operational.

## References

- [CoreOS Ignition Documentation](https://coreos.github.io/ignition/)
- [Butane Configuration Specifications](https://coreos.github.io/butane/)
- [systemd Service Units](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

