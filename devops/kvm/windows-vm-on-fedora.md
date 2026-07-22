# Windows VM on Fedora — CLI Setup Guide

Windows 10 or 11 guest on QEMU/KVM via libvirt, created entirely from the command line.
Tested on Fedora 44; paths and package names may differ slightly on other releases.

> **Audience:** Someone standing up a Windows VM on a Fedora workstation for dev, testing, or homelab use.
> **Purpose:** Repeatable CLI workflow — packages, `virt-install`, VirtIO driver paths, and the errors that actually show up.

---

## Placeholders

| Variable | Description | Example |
|----------|-------------|---------|
| `VM_NAME` | libvirt domain name | `win11` |
| `WIN_ISO` | Windows install ISO on the host | `/var/lib/libvirt/images/Win11.iso` |
| `VIRTIO_ISO` | virtio-win driver ISO on the host | `/var/lib/libvirt/images/virtio-win.iso` |
| `DISK_SIZE` | Virtual disk size (GB) | `64` |
| `RAM_MB` | Guest RAM (MiB) | `8192` |
| `VCPUS` | vCPU count | `4` |

---

## Part 1 — Host preparation

### 1.1 Install packages

```bash
sudo dnf install -y \
  qemu-kvm \
  libvirt \
  libvirt-daemon-config-network \
  virt-install \
  virt-viewer \
  edk2-ovmf \
  swtpm

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt,kvm "$USER"
```

Log out and back in (or `newgrp libvirt`) so group membership applies.

Verify KVM:

```bash
grep -E '(vmx|svm)' /proc/cpuinfo | head -1
ls -l /dev/kvm
```

### 1.2 Default NAT network

```bash
virsh --connect qemu:///system net-list --all
```

If `default` is missing:

```bash
sudo virsh net-define /usr/share/libvirt/networks/default.xml
sudo virsh net-start default
sudo virsh net-autostart default
```

If `default` already exists but is inactive, start it with `virsh net-start default`.

### 1.3 libvirt connection

System VMs live under `qemu:///system`.
Always pass `--connect qemu:///system` to `virsh` and `virt-viewer`, or set it once:

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
```

Without this, `virsh list --all` may appear empty even when the VM is running.

### 1.4 virtio-win drivers

`virtio-win` is **not** in Fedora's default repos.
The driver ISO comes from the [virtio-win project](https://github.com/virtio-win/virtio-win-pkg-scripts).

**Option A — download the ISO (simplest):**

```bash
sudo mkdir -p /var/lib/libvirt/images
sudo curl -L -o /var/lib/libvirt/images/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
sudo chmod 644 /var/lib/libvirt/images/virtio-win.iso
```

**Option B — add the virtio-win dnf repo:**

```bash
sudo curl -L -o /etc/yum.repos.d/virtio-win.repo \
  https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo
sudo dnf install virtio-win
# ISO lands at /usr/share/virtio-win/virtio-win.iso
```

### 1.5 Put install media where QEMU can read it

QEMU runs as the `qemu` user.
It cannot traverse a typical home directory (`~/Downloads`, mode `700`).

Move ISOs to libvirt's image directory:

```bash
sudo cp ~/Downloads/Win11*.iso /var/lib/libvirt/images/
sudo chmod 644 /var/lib/libvirt/images/*.iso
```

If `virt-install` warns that the hypervisor cannot access a path under `/home/...`, this is the fix.

---

## Part 2 — Create the VM

Set variables:

```bash
VM_NAME="win11"
WIN_ISO="/var/lib/libvirt/images/Win11_25H2_English_x64_v2.iso"   # your filename
VIRTIO_ISO="/var/lib/libvirt/images/virtio-win.iso"
DISK_SIZE="64"
RAM_MB="8192"
VCPUS="4"
```

### 2.1 Windows 11

```bash
virt-install \
  --connect qemu:///system \
  --name "$VM_NAME" \
  --memory "$RAM_MB" \
  --vcpus "$VCPUS,sockets=1,cores=$VCPUS,threads=1" \
  --cpu host-passthrough \
  --os-variant win11 \
  --machine q35 \
  --boot uefi \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-tis \
  --disk size="${DISK_SIZE},format=qcow2,bus=virtio,cache=none" \
  --cdrom "$WIN_ISO" \
  --disk path="$VIRTIO_ISO",device=cdrom \
  --network network=default,model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --video qxl \
  --channel unix,target.type=virtio,name=org.qemu.guest_agent.0 \
  --channel spicevmc \
  --noautoconsole
```

### 2.2 Windows 10

Same as above, but drop the `--tpm` line and use `--os-variant win10`.

### 2.3 CPU topology (set at create time)

Use an explicit vCPU topology in `--vcpus` — do not pass a bare count:

```bash
--vcpus "$VCPUS,sockets=1,cores=$VCPUS,threads=1"
```

`virt-install` writes this into the domain XML as:

```xml
<cpu mode='host-passthrough'>
  <topology sockets='1' cores='4' threads='1'/>
</cpu>
```

**Why this matters:** with `host-passthrough` and no topology, QEMU exposes the host's real CPUID layout to the guest.
On **hybrid Intel CPUs** (Core Ultra and similar P/E-core designs), Windows may report **1 logical processor** even when `<vcpu>4</vcpu>` and `virsh vcpuinfo` show four VCPUs.
This is not a driver issue — Windows is misreading inherited host topology.

The topology line above gives Windows a simple 1-socket × N-core layout and avoids a post-install `virsh edit` (see §6.1 if you already created the VM without it).

### 2.4 Connect to the installer

```bash
virt-viewer --connect qemu:///system "$VM_NAME"
```

Remote access via SSH tunnel:

```bash
ssh -L 5900:127.0.0.1:5900 your-fedora-host
virt-viewer --connect qemu:///system "$VM_NAME"
```

---

## Part 3 — VirtIO drivers during install

The VM uses VirtIO for disk and network (`bus=virtio`, `model=virtio`).
Windows does not ship those drivers.
The second CD-ROM (`virtio-win.iso`) supplies them.

### 3.1 No disk visible at "Where do you want to install Windows?"

1. Click **Load driver** → **Browse**.
2. Open the virtio-win CD drive (often **E:**).
3. Navigate to **`viostor\w11\amd64`** (Win 11) or **`viostor\w10\amd64`** (Win 10).
4. Select **Red Hat VirtIO block driver**.
5. Click **Refresh** — the virtual disk should appear.

| virt-install disk bus | Driver folder | Driver name |
|-----------------------|---------------|-------------|
| `bus=virtio` (this guide) | `viostor\w11\amd64` | VirtIO **block** driver |
| `bus=scsi` + virtio-scsi | `vioscsi\w11\amd64` | VirtIO **SCSI** driver |

### 3.2 No network at "Let's connect you to a network" (Win 11 OOBE)

The virtio-win CD should still be attached from `virt-install`.

**Option A — install driver in OOBE:**

1. Click **Install driver** → **Browse**.
2. Open the virtio-win CD.
3. Navigate to **`NetKVM\w11\amd64`**.
4. Select **Red Hat VirtIO Ethernet Adapter**.

**Option B — skip network, install guest tools after setup:**

1. Press **Shift+F10** to open Command Prompt.
2. Run: `OOBE\BYPASSNRO`
3. After reboot: **I don't have internet** → **Continue with limited setup**.
4. On the desktop, open the virtio-win CD and run **`virtio-win-guest-tools.exe`**.

Option B installs network, display, balloon, and QEMU guest agent in one step.

### 3.3 OOBE update download stuck

Win 11 OOBE may hang at **"Step 1 of 3: Downloading"** (often stuck at ~97%) — common in VMs.

There is no background mode during OOBE; setup blocks until the step completes or you skip it.

**Recommended:** click **Update later**.
Updates are not disabled — Windows Update runs normally from the desktop after setup.

If you prefer not to click the link, press **Shift+F10** and try:

```cmd
net stop wuauserv
taskkill /F /IM SetupHost.exe
taskkill /F /IM TiWorker.exe
```

If still stuck, reboot from the host (`virsh reboot "$VM_NAME"`) and choose **Update later** when the step reappears.

### 3.4 Local account instead of Microsoft account

Recent Win 11 builds push Microsoft account sign-in during OOBE with no obvious skip button.

**Recommended — works on most recent builds (including 25H2):**

1. Press **Shift+F10** to open Command Prompt.
2. Run:

   ```cmd
   start ms-cxh:localonly
   ```

3. Close the cmd window — the local username/password screen should appear.

**Alternatives if that fails:**

- Click **Sign-in options** and look for **Offline account** or **Domain join instead** (Pro).
- Enter a fake email (e.g. `test@test`), click **Next** — some builds offer a local account after sign-in fails.
- Run `OOBE\BYPASSNRO` from **Shift+F10**, reboot, then **I don't have internet** → **Continue with limited setup** (especially useful on Win 11 Home).

After reaching the desktop, run **`virtio-win-guest-tools.exe`** if not already installed (see Part 4), then run Windows Update manually when ready.

---

## Part 4 — Guest tools, resize, and clipboard

Automatic window resize and host↔guest copy/paste require **Spice** (already set via `--graphics spice`) plus guest-side agents.
No extra host packages beyond `virt-viewer`.

### 4.1 Install guest tools in Windows

Open the virtio-win CD and run as Administrator:

```
virtio-win-guest-tools.exe
```

Accept defaults — this installs the Spice agent (vdagent), QEMU guest agent, network, display, and balloon drivers.
Reboot Windows when prompted.

### 4.2 VM channels (host side)

The `virt-install` command in §2.1 configures both communication channels:

| Channel | Purpose |
|---------|---------|
| `org.qemu.guest_agent.0` | QEMU guest agent (shutdown, freeze, etc.) |
| `com.redhat.spice.0` (`--channel spicevmc`) | Auto-resize and clipboard via Spice |

Verify on an existing VM:

```bash
virsh --connect qemu:///system dumpxml "$VM_NAME" | grep -A4 channel
```

If `com.redhat.spice.0` is missing, shut down and add via `virsh edit`:

```xml
<channel type='spicevmc'>
  <target type='virtio' name='com.redhat.spice.0'/>
</channel>
```

### 4.3 Connect with virt-viewer

Use Spice, not a generic VNC client:

```bash
virt-viewer --connect qemu:///system "$VM_NAME"
```

After guest tools are installed and the Spice channel is present:

- **Auto-resize:** resizing the virt-viewer window adjusts the guest resolution (and vice versa).
- **Clipboard:** copy/paste between host and guest should work bidirectionally.

In virt-viewer: **View → Resize window to match guest size** if the window doesn't auto-fit.
**Edit → Preferences** — confirm clipboard sharing is enabled if paste still fails.

### 4.4 Verify

In Windows, confirm the **Spice Agent** service (`vdservice`) is running after reboot.

Reconnect virt-viewer (close and reopen) if clipboard doesn't work on first try.

---

## Part 5 — Day-to-day management

```bash
virsh --connect qemu:///system list --all
virsh --connect qemu:///system start "$VM_NAME"
virsh --connect qemu:///system shutdown "$VM_NAME"
virsh --connect qemu:///system destroy "$VM_NAME"      # force power off
virsh --connect qemu:///system autostart "$VM_NAME"    # start on host boot
virt-viewer --connect qemu:///system "$VM_NAME"
virsh --connect qemu:///system dumpxml "$VM_NAME"
```

Eject the Windows install ISO after setup (adjust target if different — check `dumpxml`):

```bash
virsh --connect qemu:///system change-media "$VM_NAME" sda --eject --config
```

---

## Part 6 — Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Permission denied` opening ISO under `/home/...` | QEMU runs as `qemu`, not your user | Copy ISO to `/var/lib/libvirt/images/` |
| `failed to get domain 'win11'` | Wrong libvirt connection | Use `virsh --connect qemu:///system` |
| No disk in Windows installer | VirtIO block driver not loaded | Load `viostor\w11\amd64` from virtio-win CD |
| No network in Win 11 OOBE | VirtIO network driver not loaded | Load `NetKVM\w11\amd64`, or bypass with `OOBE\BYPASSNRO` then run guest tools |
| `IDE controllers are unsupported` attaching CD | Q35 has no IDE; `hdc` is wrong | Use `--targetbus sata` or `change-media` on an existing SATA CD slot |
| `virtio-win` not found in dnf | Not in default Fedora repos | Download ISO from fedorapeople (see §1.4) |
| Win 11 TPM error | Software TPM not configured | Ensure `swtpm` is installed and `--tpm` is present |
| OOBE update download stuck at ~97% | Hung Windows Update during setup | Click **Update later**; updates run from desktop (see §3.3) |
| No skip for Microsoft account | Default Win 11 OOBE behavior | **Shift+F10** → `start ms-cxh:localonly` (see §3.4) |
| Windows shows 1 CPU; host shows 4 | `host-passthrough` without guest topology (common on hybrid Intel) | Add topology at create (§2.3) or fix existing VM (§6.1) |
| No auto-resize or clipboard | Guest tools or Spice channel missing | Install `virtio-win-guest-tools.exe`; add `--channel spicevmc` (see §4) |

### 6.1 Windows sees one processor (existing VM)

**Symptoms:** Task Manager shows **Virtual processors: 1**; `virsh vcpuinfo` shows four VCPUs with most idle; `dumpxml` has `<vcpu>4</vcpu>` but `<cpu mode='host-passthrough' .../>` with no `<topology>`.

**Not a driver issue** — no VirtIO or chipset driver fixes CPU enumeration.

Shut down and edit:

```bash
virsh --connect qemu:///system shutdown "$VM_NAME"
virsh --connect qemu:///system edit "$VM_NAME"
```

Replace the self-closing `<cpu .../>` with (adjust core count to match `$VCPUS`):

```xml
<cpu mode='host-passthrough' check='none' migratable='on'>
  <topology sockets='1' cores='4' threads='1'/>
</cpu>
```

Cold boot from the host:

```bash
virsh --connect qemu:///system start "$VM_NAME"
```

Verify in Windows PowerShell:

```powershell
(Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
```

If still 1 after topology fix: check **msconfig** → Boot → Advanced options → uncheck **Number of processors**; or run `bcdedit /deletevalue numproc`.
If still stuck, try `host-model` instead of `host-passthrough` with the same topology block.

### Attach or swap a CD on a running Q35 VM

Inspect existing CD devices first:

```bash
virsh --connect qemu:///system dumpxml "$VM_NAME" | grep -A12 'device=.cdrom'
```

Insert into an existing empty slot:

```bash
virsh --connect qemu:///system change-media "$VM_NAME" sdb \
  "$VIRTIO_ISO" --insert --config --live
```

Add a new SATA CD-ROM (if no slot exists):

```bash
virsh --connect qemu:///system attach-disk "$VM_NAME" \
  "$VIRTIO_ISO" sdb --type cdrom --mode readonly --targetbus sata --config --live
```

Do **not** use `hdc` on Q35 — that targets legacy IDE.

---

## Part 7 — Transfer VM to another host

Move a VM from one Fedora machine to another (e.g. laptop → desktop).
Shut down cleanly before copying anything — never copy a running disk.

```bash
virsh --connect qemu:///system shutdown "$VM_NAME"
virsh --connect qemu:///system list --all   # confirm "shut off"
```

Check actual transfer size (qcow2 is sparse — allocated size is often much smaller than virtual size):

```bash
du -h /var/lib/libvirt/images/${VM_NAME}.qcow2
qemu-img info /var/lib/libvirt/images/${VM_NAME}.qcow2
```

Use `--sparse` with `rsync` or `cp --sparse=always` so empty disk space is not copied.

### 7.1 Option A — disk only (simplest)

Good for a fresh test VM where you don't need to preserve UEFI NVRAM or software TPM state.

**On source host:**

```bash
rsync -avh --sparse --progress \
  /var/lib/libvirt/images/${VM_NAME}.qcow2 \
  user@desktop:/var/lib/libvirt/images/
```

Via removable media:

```bash
sudo rsync -avh --sparse --progress \
  /var/lib/libvirt/images/${VM_NAME}.qcow2 /run/media/you/USB/
```

**On destination host:**

Install the virt stack (Part 1), then import the existing disk:

```bash
sudo chmod 644 /var/lib/libvirt/images/${VM_NAME}.qcow2

virt-install \
  --connect qemu:///system \
  --name "$VM_NAME" \
  --memory "$RAM_MB" \
  --vcpus "$VCPUS,sockets=1,cores=$VCPUS,threads=1" \
  --cpu host-passthrough \
  --os-variant win11 \
  --machine q35 \
  --boot uefi \
  --tpm backend.type=emulator,backend.version=2.0,model=tpm-tis \
  --disk path=/var/lib/libvirt/images/${VM_NAME}.qcow2,bus=virtio \
  --network network=default,model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --video qxl \
  --channel unix,target.type=virtio,name=org.qemu.guest_agent.0 \
  --channel spicevmc \
  --import \
  --noautoconsole
```

**Tradeoff:** fresh UEFI vars and TPM state.
Windows may treat the move as a hardware change (reactivation prompt; BitLocker recovery key if enabled).

### 7.2 Option B — full export (recommended for Win 11)

Preserves domain XML, UEFI NVRAM, and software TPM state.

**On source host:**

```bash
EXPORT_DIR=~/${VM_NAME}-export
mkdir -p "$EXPORT_DIR"

virsh --connect qemu:///system dumpxml "$VM_NAME" > "$EXPORT_DIR/${VM_NAME}.xml"

sudo cp --sparse=always \
  /var/lib/libvirt/images/${VM_NAME}.qcow2 "$EXPORT_DIR/"

# NVRAM path is in the XML (typically under /var/lib/libvirt/qemu/nvram/)
NVRAM=$(virsh --connect qemu:///system dumpxml "$VM_NAME" \
  | grep '<nvram' | sed -E "s/.*>([^<]+)<.*/\\1/")
sudo cp "$NVRAM" "$EXPORT_DIR/"

# Software TPM state (skip if directory doesn't exist)
sudo cp -a /var/lib/libvirt/swtpm/"$VM_NAME" "$EXPORT_DIR/swtpm/" 2>/dev/null || true

sudo chown -R "$USER:$USER" "$EXPORT_DIR"
```

Transfer the export directory:

```bash
rsync -avh --progress ~/${VM_NAME}-export/ user@desktop:~/${VM_NAME}-export/
```

**On destination host:**

```bash
EXPORT_DIR=~/${VM_NAME}-export

sudo mkdir -p /var/lib/libvirt/images /var/lib/libvirt/qemu/nvram
sudo cp --sparse=always "$EXPORT_DIR/${VM_NAME}.qcow2" /var/lib/libvirt/images/
sudo cp "$EXPORT_DIR/"*_VARS* /var/lib/libvirt/qemu/nvram/   # adjust to your NVRAM filename

sudo mkdir -p /var/lib/libvirt/swtpm
sudo cp -a "$EXPORT_DIR/swtpm/$VM_NAME" /var/lib/libvirt/swtpm/ 2>/dev/null || true

sudo chmod 644 /var/lib/libvirt/images/${VM_NAME}.qcow2
```

Define and start:

```bash
virsh --connect qemu:///system define "$EXPORT_DIR/${VM_NAME}.xml"
virsh --connect qemu:///system start "$VM_NAME"
virt-viewer --connect qemu:///system "$VM_NAME"
```

If `define` fails on path mismatches, edit absolute paths in the XML to match the destination:

```bash
virsh --connect qemu:///system edit "$VM_NAME"
```

Fix `<source file='...'/>` entries for disk, NVRAM, and TPM.

### 7.3 Which option to use

| Situation | Approach |
|-----------|----------|
| Test VM; don't care about TPM / boot state | Option A — disk only |
| Working Win 11 install to keep as-is | Option B — disk + XML + NVRAM + swtpm |

After import, Windows may prompt for reactivation (usually fine with the same license).
Run `virtio-win-guest-tools.exe` if network or display misbehave.
Set autostart on the new host if desired: `virsh autostart "$VM_NAME"`.

---

## Related reading

- [SNO on KVM lab](../ocp/examples/sno-kvm-lab/README.md) — OpenShift single-node cluster on KVM (bridged networking, heavier footprint)
- [virtio-win downloads](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/) — stable and latest driver builds

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
