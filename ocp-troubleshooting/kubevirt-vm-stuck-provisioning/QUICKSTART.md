# Quick Start - Fix VM Stuck in Provisioning

**Problem**: VM stuck with error about missing `kubevirt-velero-annotations-remover` service

**Quick Fix (1 minute)**:

```bash
# Find the problematic webhook
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | grep velero | awk '{print $1}')

# Remove it (this fixes VM provisioning immediately)
oc delete mutatingwebhookconfigurations $WEBHOOK_NAME
```

**Restart your VM**:

```bash
# Stop VM
oc patch vm <your-vm-name> -n <namespace> --type merge -p '{"spec":{"running":false}}'

# Start VM
oc patch vm <your-vm-name> -n <namespace> --type merge -p '{"spec":{"running":true}}'

# Watch it start
oc get vm <your-vm-name> -n <namespace> -w
```

**Done!** Your VM should now provision successfully.

---

## What This Does

- Removes the mutating webhook that's blocking VM creation
- VMs will work immediately
- ⚠️ OADP/Velero won't be able to backup VMs until you repair the plugin

## If You Need OADP/Velero

If you use OADP/Velero to backup VMs, you should properly fix the plugin instead:

See: [REPAIR-VELERO-PLUGIN.md](./REPAIR-VELERO-PLUGIN.md)

## Interactive Fix Script

For a guided fix with options:

```bash
chmod +x fix-velero-webhook.sh
./fix-velero-webhook.sh
```

## Full Documentation

- [README.md](./README.md) - Overview and options
- [INVESTIGATION-WORKFLOW.md](./INVESTIGATION-WORKFLOW.md) - Detailed troubleshooting
- [VERIFICATION.md](./VERIFICATION.md) - Post-fix verification
- [PREVENTION.md](./PREVENTION.md) - Avoid future issues

## Need Help?

Run diagnostics to gather information:

```bash
chmod +x diagnostic-commands.sh
./diagnostic-commands.sh > diagnostics-$(date +%Y%m%d-%H%M%S).txt
```

Share the output with your team or support.

