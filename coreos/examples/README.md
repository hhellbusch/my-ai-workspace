# CoreOS Examples

This directory contains examples and patterns for working with RHEL CoreOS and Fedora CoreOS.

## Examples

### iso-eject-after-install
Automatically eject installation media (ISO/CD-ROM) after CoreOS completes installation. Includes multiple approaches for different environments (physical hardware, VMware, Redfish/BMC, etc.).

**Use cases:**
- Prevent boot loops on physical hardware
- Automated datacenter provisioning
- Clean post-installation workflows
- Remote server deployments

**Quick start:** See [iso-eject-after-install/QUICK-START.md](iso-eject-after-install/QUICK-START.md)

## About CoreOS

CoreOS (Container-Optimized Linux) is a minimal operating system designed for running containerized workloads. It features:

- **Automatic updates:** Rolling updates with rollback capability
- **Immutable infrastructure:** OS is read-only, configuration via Ignition
- **Container-focused:** Optimized for containers and Kubernetes
- **Minimal attack surface:** Only essential components included

## CoreOS Variants

- **RHEL CoreOS (RHCOS):** Used in OpenShift, enterprise support
- **Fedora CoreOS (FCOS):** Community version, latest features
- **Flatcar Container Linux:** CoreOS fork, alternative option

## Working with Ignition

Ignition is the provisioning utility for CoreOS. It runs on first boot and:

1. Partitions disks
2. Formats filesystems
3. Creates users and groups
4. Writes files
5. Configures systemd units
6. Sets up networking

### Butane (formerly FCCT)

Butane converts human-readable YAML into Ignition JSON:

```bash
# Convert Butane YAML to Ignition JSON
butane --pretty --strict config.bu -o config.ign
```

## Common Patterns

### User Configuration
```yaml
variant: fcos
version: 1.4.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAA...
```

### Systemd Service
```yaml
systemd:
  units:
    - name: hello.service
      enabled: true
      contents: |
        [Unit]
        Description=Hello Service
        After=network-online.target
        
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/echo "Hello CoreOS"
        
        [Install]
        WantedBy=multi-user.target
```

### File Creation
```yaml
storage:
  files:
    - path: /etc/myconfig.conf
      mode: 0644
      contents:
        inline: |
          key=value
          enabled=true
```

## Resources

- [CoreOS Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
- [Ignition Specification](https://coreos.github.io/ignition/)
- [Butane Configuration](https://coreos.github.io/butane/)
- [OpenShift CoreOS](https://docs.openshift.com/container-platform/latest/architecture/architecture-rhcos.html)

## Tools

Install common CoreOS tools:

```bash
# Fedora/RHEL
sudo dnf install butane coreos-installer

# Manual installation
curl -LO https://github.com/coreos/butane/releases/latest/download/butane-x86_64-unknown-linux-gnu
chmod +x butane-x86_64-unknown-linux-gnu
sudo mv butane-x86_64-unknown-linux-gnu /usr/local/bin/butane
```

## Contributing Examples

When adding new examples:

1. Create a descriptive directory name
2. Include a comprehensive README.md
3. Provide working Butane (.bu) files
4. Add comparison/decision guides if multiple approaches
5. Include troubleshooting section
6. Test in both FCOS and RHCOS if applicable

