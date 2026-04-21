# 013 — Read File from SMB Share and Write to HashiCorp Vault

Fetches a file from a Windows/Samba SMB share and stores its contents as a
secret in HashiCorp Vault (KV v2). No root privileges or CIFS kernel module
required — the playbook uses the `smbclient` CLI tool running on the Ansible
controller.

---

## Use Cases

- Rotate credentials stored on a legacy Windows file share into Vault
- Ingest certificate files, licence keys, or config blobs from shared storage
- Bridge a Windows-centric workflow into a Vault-backed secrets pipeline

---

## Prerequisites

### Controller packages

Both `smbclient` and `cifs-utils` are required. `cifs-utils` provides the
`mount.cifs` kernel helper — without it the kernel cannot handle the `cifs`
filesystem type and the error surfaces as a misleading "No route to host".

```bash
# RHEL / Fedora
sudo dnf install -y samba-client cifs-utils

# Debian / Ubuntu
sudo apt-get install -y smbclient cifs-utils
```

Verify:

```bash
smbclient --version
mount.cifs --version
```

### Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### Python dependency (pulled in automatically by the collection)

```bash
pip install hvac
```

### HashiCorp Vault

- A running Vault instance with KV v2 secrets engine enabled
- A token with **write** access to the target path

Enable KV v2 if needed:

```bash
vault secrets enable -path=secret kv-v2
```

Create a minimal write policy:

```hcl
# myapp-write.hcl
path "secret/data/myapp/*" {
  capabilities = ["create", "update"]
}
```

```bash
vault policy write myapp-write myapp-write.hcl
vault token create -policy=myapp-write -ttl=1h
```

---

## Quick Start

```bash
cd ansible/examples/013_smb_to_vault

# 1. Install collections
ansible-galaxy collection install -r requirements.yml

# 2. Create and encrypt your credentials file
cp vault.example.yml vault.yml
# Edit vault.yml with real values
ansible-vault encrypt vault.yml

# 3. Run the playbook
ansible-playbook playbook.yml \
  -e @vault.yml \
  -e smb_server=fileserver.example.com \
  -e smb_share=data \
  -e smb_remote_file="reports/config.txt" \
  -e hashi_vault_addr=https://vault.example.com:8200 \
  -e hashi_vault_kv_path=secret/myapp/config \
  --ask-vault-pass
```

---

## Variables Reference

| Variable | Default | Description |
|---|---|---|
| `smb_server` | `fileserver.example.com` | Hostname or IP of the SMB server |
| `smb_share` | `data` | Share name (the path after `//server/`) |
| `smb_domain` | `""` | Windows domain (empty = workgroup) |
| `smb_username` | `{{ vault_smb_username }}` | SMB account username |
| `smb_password` | `{{ vault_smb_password }}` | SMB account password |
| `smb_remote_file` | `reports/config.txt` | File path relative to share root |
| `smb_max_protocol` | `SMB3` | Max SMB protocol (`NT1`=SMB1, `SMB2`, `SMB3`) |
| `smb_local_temp` | `/tmp/.smb_fetch_<filename>` | Temporary staging path on the controller |
| `hashi_vault_addr` | `https://vault.example.com:8200` | Vault server URL |
| `hashi_vault_token` | `{{ vault_hashi_token }}` | Vault authentication token |
| `hashi_vault_validate_certs` | `true` | Verify TLS certificate |
| `hashi_vault_kv_path` | `secret/myapp/config` | KV v2 path (without `/data/` prefix) |
| `hashi_vault_key` | `file_content` | Key name written inside the Vault secret |

---

## Credential Security

All sensitive variables are marked `no_log: true`. Store credentials in an
Ansible Vault-encrypted file and never pass them as plain-text CLI arguments in
production.

```bash
# Good — credentials never appear in shell history or process list
ansible-playbook playbook.yml -e @vault.yml --ask-vault-pass

# Avoid — password visible in process list
ansible-playbook playbook.yml -e smb_password=mysecret   # ← BAD
```

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│  Ansible Controller                                                 │
│                                                                     │
│  1. smbclient //server/share -U user%pass -c "get file /tmp/file"  │
│          │                                                          │
│          ▼                                                          │
│  2. slurp /tmp/file → base64-encoded content                       │
│          │                                                          │
│          ▼                                                          │
│  3. vault_kv2_write path=secret/... data={key: content}            │
│          │                                                          │
│          ▼                                                          │
│  4. rm /tmp/file  (always, even on failure)                        │
└─────────────────────────────────────────────────────────────────────┘
```

The `block/rescue/always` pattern ensures the temporary file is always removed
even when an intermediate task fails.

---

## Structured File Variants

If the file is structured data (YAML, JSON, CSV) you can parse it before
writing to Vault so individual fields become separate Vault keys:

```yaml
# For a YAML file
- name: Parse YAML and write individual keys
  community.hashi_vault.vault_kv2_write:
    path: "{{ hashi_vault_kv_path }}"
    data: "{{ file_content | from_yaml }}"
    ...

# For a JSON file
- name: Parse JSON and write individual keys
  community.hashi_vault.vault_kv2_write:
    path: "{{ hashi_vault_kv_path }}"
    data: "{{ file_content | from_json }}"
    ...
```

---

## Alternative: CIFS Mount (requires root)

If you prefer to mount the share rather than use `smbclient`, install
`cifs-utils` and use `ansible.posix.mount`:

```yaml
- name: Mount SMB share
  ansible.posix.mount:
    path: /mnt/smb
    src: "//{{ smb_server }}/{{ smb_share }}"
    fstype: cifs
    opts: "username={{ smb_username }},password={{ smb_password }},vers=3.0"
    state: mounted
  become: true

- name: Slurp target file
  ansible.builtin.slurp:
    src: "/mnt/smb/{{ smb_remote_file }}"
  register: file_raw

- name: Unmount share
  ansible.posix.mount:
    path: /mnt/smb
    state: unmounted
  become: true
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `NT_STATUS_LOGON_FAILURE` | Wrong username or password | Double-check credentials; include domain with `DOMAIN\user` |
| `NT_STATUS_BAD_NETWORK_NAME` | Share name incorrect | Verify share name with `smbclient -L //server -U user%pass` |
| `NT_STATUS_OBJECT_NAME_NOT_FOUND` | File path wrong | Confirm path with `smbclient` interactive mode |
| `SMB1 disabled` | Server requires SMB2/3 | Set `smb_max_protocol: "SMB2"` or `"SMB3"` |
| Vault `403 Forbidden` | Token lacks write permission | Check token policy covers the KV path |
| `hvac` import error | Python library missing | `pip install hvac` |
| `No route to host` on mount | `cifs-utils` not installed | `dnf install -y cifs-utils` |

### List share contents interactively

```bash
smbclient //fileserver.example.com/data -U 'DOMAIN\svcaccount%password'
smb: \> ls
smb: \> cd reports
smb: \> ls
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
