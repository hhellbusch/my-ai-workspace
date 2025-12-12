# Quick Start Guide

Get started with auto-ejecting installation media in under 5 minutes.

## Prerequisites

- RHEL CoreOS ISO
- `butane` tool installed (for converting YAML to Ignition JSON)
- `coreos-installer` tool (optional, for embedding Ignition)

## Step 1: Install Tools

### On Fedora/RHEL:
```bash
sudo dnf install butane coreos-installer
```

### On other systems:
```bash
# Download butane
curl -LO https://github.com/coreos/butane/releases/latest/download/butane-x86_64-unknown-linux-gnu
chmod +x butane-x86_64-unknown-linux-gnu
sudo mv butane-x86_64-unknown-linux-gnu /usr/local/bin/butane

# Download coreos-installer
curl -LO https://github.com/coreos/coreos-installer/releases/latest/download/coreos-installer
chmod +x coreos-installer
sudo mv coreos-installer /usr/local/bin/
```

## Step 2: Choose Your Configuration

Pick the configuration file that matches your environment:

| File | Use Case |
|------|----------|
| `basic-eject.bu` | Physical hardware, simple setup |
| `vmware-eject.bu` | VMware VMs |
| `redfish-eject.bu` | Servers with BMC (iLO, iDRAC) |
| `robust-eject.bu` | Production use with fallbacks |
| `delayed-eject.bu` | Need time to verify installation |

For this guide, we'll use `basic-eject.bu`.

## Step 3: Customize (Optional)

Edit the `.bu` file if needed:

```bash
vi basic-eject.bu
```

Common customizations:
- Change device path from `/dev/sr0` to something else
- Modify service conditions
- Add additional ExecStart commands

## Step 4: Convert to Ignition

```bash
butane --pretty --strict basic-eject.bu -o basic-eject.ign
```

You should now have `basic-eject.ign` (JSON format).

## Step 5: Add to Your Existing Ignition Config (Optional)

If you already have an Ignition config, you'll need to merge them. Here's a simple example:

```bash
# If you have a Butane file, add the systemd section to it
# Then convert the combined file
butane --pretty --strict your-combined-config.bu -o final-config.ign
```

## Step 6: Use the Configuration

### Option A: Embed in ISO (Recommended)

```bash
# This modifies the ISO to include your Ignition config
sudo coreos-installer iso ignition embed \
  /path/to/rhcos.iso \
  --ignition-file basic-eject.ign
```

Now boot from this ISO, and media will auto-eject after installation.

### Option B: Serve via HTTP

```bash
# Host the Ignition file on a web server
python3 -m http.server 8000
```

Then at the CoreOS boot prompt:
```
ignition.config.url=http://your-server:8000/basic-eject.ign
```

### Option C: Kernel Parameter (URL)

Upload `basic-eject.ign` to a web server, then boot with:
```
coreos.inst.ignition_url=http://your-server/basic-eject.ign
```

## Step 7: Boot and Install

1. Boot from the ISO
2. Let CoreOS complete installation
3. System will reboot
4. After first boot reaches multi-user target, media ejects automatically

## Step 8: Verify

After the system boots, check that it worked:

```bash
# SSH into the system

# Check service status
systemctl status eject-install-media.service

# View logs
journalctl -u eject-install-media.service

# Verify stamp file was created
ls -l /var/lib/install-media-ejected
```

Expected output:
```
● eject-install-media.service - Eject installation media after first boot
     Loaded: loaded
     Active: active (exited) since Mon 2025-12-01 10:30:45 UTC
```

## Troubleshooting

### Service didn't run
```bash
# Check journal for errors
journalctl -xe

# Try running manually
sudo systemctl start eject-install-media.service
```

### Media didn't eject
```bash
# Check if mounted
mount | grep sr0

# Check device exists
ls -l /dev/sr0

# Try manual eject
sudo eject /dev/sr0

# Check if it's a different device
ls -l /dev/sr* /dev/cdrom /dev/dvd
```

### Wrong device path

If your CD-ROM isn't `/dev/sr0`, find it:
```bash
lsblk | grep rom
```

Then modify the `.bu` file and reconvert.

## Complete Example: Physical Server

Here's a complete workflow:

```bash
# 1. Create directory for your configs
mkdir ~/coreos-configs
cd ~/coreos-configs

# 2. Copy the basic eject config
cp /path/to/basic-eject.bu my-config.bu

# 3. Add your other Ignition settings (SSH keys, hostname, etc.)
cat >> my-config.bu << 'EOF'
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2E... your-key-here
storage:
  files:
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: my-coreos-host
EOF

# 4. Convert to Ignition
butane --pretty --strict my-config.bu -o my-config.ign

# 5. Embed in ISO
sudo coreos-installer iso ignition embed rhcos-4.14.0-x86_64-live.iso \
  --ignition-file my-config.ign \
  --output rhcos-custom.iso

# 6. Write to USB or boot in your environment
sudo dd if=rhcos-custom.iso of=/dev/sdX bs=4M status=progress
```

## Next Steps

- Read `COMPARISON.md` to understand different approaches
- Check `README.md` for detailed documentation
- Review the other `.bu` files for different scenarios
- Test in a VM before production use

## Tips

1. **Always test first:** Use a VM to test before deploying to hardware
2. **Keep backups:** Save your `.bu` and `.ign` files
3. **Version control:** Track your Ignition configs in git
4. **Logging:** Enable console output for easier troubleshooting
5. **Combine configs:** Merge ejection config with your other Ignition settings

## Additional Resources

- [CoreOS Ignition Documentation](https://coreos.github.io/ignition/)
- [Butane Specification](https://coreos.github.io/butane/)
- [RHEL CoreOS Documentation](https://docs.openshift.com/container-platform/latest/installing/install_config/installing-customizing.html)

