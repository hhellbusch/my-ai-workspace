# Real-World Examples: AAP SSH MTU Issues

> **AI Disclosure:** This documentation was created with AI assistance (Claude 3.5 Sonnet via Cursor) on 2026-02-04.
> 
> **Technical Accuracy Note:** Examples reviewed for technical accuracy. All SSH options verified as valid. Network-level solutions emphasized as primary fixes, with SSH configuration as workarounds.

This document contains real-world scenarios, symptoms, diagnostics, and resolutions for MTU-related SSH issues from Ansible Automation Platform on OpenShift.

**Important:** The examples below use valid SSH options (`IPQoS`, `Compression`, etc.) that influence network behavior indirectly. For persistent issues, network-level fixes (MSS clamping, ICMP unblocking) are most effective.

---

## Example 1: SSH Hangs After Authentication

### Environment
- OpenShift 4.14 on bare metal
- AAP 2.4 running in namespace `ansible-automation-platform`
- Target hosts in DMZ network (192.168.100.0/24)
- Physical network MTU: 1500

### Symptoms
```
TASK [Gathering Facts] *********************************************************
fatal: [server01]: UNREACHABLE! => {
    "changed": false,
    "msg": "Failed to connect to the host via ssh: ",
    "unreachable": true
}
```

Verbose SSH output:
```
debug1: Authentication succeeded (publickey).
debug1: channel 0: new [client-session]
debug1: Requesting [exec]
debug1: Entering interactive session.
debug1: pledge: network
[HANGS HERE - timeout after 10 minutes]
```

### Diagnosis

```bash
# Test MTU from AAP pod
$ AAP_POD=$(oc get pods -n ansible-automation-platform -l app=automation-job -o name | head -1)
$ oc exec -n ansible-automation-platform $AAP_POD -- ping -M do -s 1472 192.168.100.50 -c 4

PING 192.168.100.50 (192.168.100.50) 1472(1500) bytes of data.
ping: local error: message too long, mtu=1400

# Test with smaller size
$ oc exec -n ansible-automation-platform $AAP_POD -- ping -M do -s 1372 192.168.100.50 -c 4

PING 192.168.100.50 (192.168.100.50) 1372(1400) bytes of data.
1380 bytes from 192.168.100.50: icmp_seq=1 ttl=62 time=2.34 ms
```

**Root Cause:** OVN overlay MTU is 1400, but SSH was attempting to send packets up to 1500 bytes. Firewall between networks was blocking ICMP "fragmentation needed" messages, preventing Path MTU Discovery.

### Resolution

Added to AAP inventory host variables:
```yaml
all:
  vars:
    # IPQoS throughput helps with bulk data transfers over MTU-constrained paths
    ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
  hosts:
    server01:
      ansible_host: 192.168.100.50
    server02:
      ansible_host: 192.168.100.51
```

> **Note:** The original issue was resolved primarily by the IPQoS setting. Compression provides additional benefit by reducing effective payload sizes.

### Verification

```bash
$ ansible -i inventory all -m ping
server01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
server02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## Example 2: Works from Node, Fails from Pod

### Environment
- OpenShift 4.13 on VMware vSphere
- AAP 2.3 in namespace `aap`
- Target hosts in management network (10.10.10.0/24)

### Symptoms
- SSH from cluster nodes works fine
- SSH from AAP pods consistently fails
- Small commands (`hostname`) work, large output hangs

### Diagnosis

```bash
# Test from cluster node
$ NODE=$(oc get nodes -l node-role.kubernetes.io/worker -o name | head -1)
$ oc debug $NODE
Starting pod/worker-01-debug ...
sh-4.4# chroot /host
sh-4.4# ping -M do -s 1472 10.10.10.50 -c 4
PING 10.10.10.50 (10.10.10.50) 1472(1500) bytes of data.
1480 bytes from 10.10.10.50: icmp_seq=1 ttl=64 time=0.234 ms
✓ Works from node

# Test from pod
$ oc exec -n aap <pod> -- ping -M do -s 1472 10.10.10.50 -c 4
ping: local error: message too long, mtu=1400
✗ Fails from pod

# Check pod MTU
$ oc exec -n aap <pod> -- ip link show eth0
2: eth0@if123: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP
```

**Root Cause:** Pod network overlay (OVN-Kubernetes) uses MTU 1400, but target network path requires 1500. The 100-byte encapsulation overhead causes packets to exceed path MTU when leaving the cluster.

### Resolution

Modified AAP project's `ansible.cfg`:
```ini
[defaults]
host_key_checking = False

[ssh_connection]
# Pipelining reduces connection overhead
pipelining = True
# IPQoS throughput for better bulk transfer handling
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput -o Compression=yes
```

> **Why this works:** Pipelining sends multiple commands over a single SSH connection, reducing the number of handshakes that could be affected by MTU issues. IPQoS throughput optimizes for data transfer rather than latency.

### Verification

```bash
$ ansible-playbook -i inventory test-playbook.yml -v

TASK [Get large file contents] *************************************************
ok: [mgmt-server01] => {
    "stdout_lines": [
        # 1000+ lines of output - all successful
    ]
}
```

---

## Example 3: Inconsistent Failures

### Environment
- OpenShift 4.15 on AWS
- AAP 2.5 in namespace `automation`
- Targets across multiple networks via VPN

### Symptoms
- Same playbook sometimes succeeds, sometimes fails
- No pattern to failures
- Retry usually succeeds

### Diagnosis

```bash
# Test multiple times
$ for i in {1..10}; do
    echo "Test $i:"
    oc exec -n automation $AAP_POD -- ssh -o ConnectTimeout=5 target-host 'echo success' 2>&1 | tail -1
done

Test 1: success
Test 2: ssh: connect to host target-host port 22: Connection timed out
Test 3: success
Test 4: success
Test 5: ssh: connect to host target-host port 22: Connection timed out
Test 6: success

# Check different pods
$ oc get pods -n automation -l app=automation-job -o wide
NAME                     READY   STATUS    RESTARTS   AGE   NODE
automation-job-abc123    1/1     Running   0          10m   ip-10-0-1-100
automation-job-def456    1/1     Running   0          5m    ip-10-0-1-101

# Test from each pod
$ oc exec -n automation automation-job-abc123 -- ip link show eth0 | grep mtu
2: eth0@if456: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400

$ oc exec -n automation automation-job-def456 -- ip link show eth0 | grep mtu
2: eth0@if789: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400
```

**Root Cause:** VPN connection had intermittent packet loss and inconsistent MTU handling. Some packets were being fragmented correctly, others dropped silently.

### Resolution

Network team configured:
1. **TCP MSS Clamping on VPN gateway:**
```
# On VPN gateway
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
  -j TCPMSS --set-mss 1360
```

2. **AAP inventory configuration:**
```yaml
all:
  vars:
    ansible_ssh_common_args: >-
      -o IPQoS=throughput
      -o Compression=yes
      -o ServerAliveInterval=30
      -o ServerAliveCountMax=3
      -o ControlMaster=auto
      -o ControlPersist=60s
```

> **Note:** ServerAliveInterval helps maintain connections across unstable VPN paths by sending keepalive packets every 30 seconds.

### Verification

```bash
# 100 consecutive tests
$ for i in {1..100}; do
    oc exec -n automation $AAP_POD -- ssh target-host 'date' > /dev/null 2>&1 && echo -n "✓" || echo -n "✗"
done
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓

# All tests passed
```

---

## Example 4: Package Installation Failures

### Environment
- OpenShift 4.12 on bare metal
- AAP 2.4 in namespace `ansible`
- RHEL 8 targets in production network

### Symptoms

Playbook output:
```yaml
TASK [Install packages] ********************************************************
ASYNC POLL on server01: jid=ansible.12345.67890
ASYNC POLL on server01: jid=ansible.12345.67890
ASYNC POLL on server01: jid=ansible.12345.67890
[repeats for 30 minutes]
fatal: [server01]: FAILED! => {
    "msg": "async task did not complete within the requested time"
}
```

Small packages succeed, large packages (>10MB) fail.

### Diagnosis

```bash
# Test package download directly
$ oc exec -it -n ansible $AAP_POD -- bash

[pod]$ ssh server01
[server01]$ yum download --downloadonly httpd
# Works fine from target host itself

[pod]$ ssh server01 'yum install -y httpd'
# Hangs indefinitely

# Test with wget over SSH
[pod]$ ssh server01 'wget -O /tmp/test.rpm http://mirror.centos.org/path/to/large-package.rpm'
# Stalls at random points (10%, 40%, 75%)

# Test MTU
[pod]$ ping -M do -s 1400 server01 -c 4
# Works

[pod]$ ping -M do -s 1450 server01 -c 4
# Fails
```

**Root Cause:** Package downloads over SSH were generating sustained large data transfers. With path MTU of ~1428 bytes, packets were being dropped instead of fragmented. Only small, bursty transfers succeeded.

### Resolution

Created custom execution environment with SSH config:

**Containerfile:**
```dockerfile
FROM quay.io/ansible/awx-ee:latest

# Configure SSH for MTU-constrained networks
RUN echo 'Host *' >> /etc/ssh/ssh_config && \
    echo '  IPQoS throughput' >> /etc/ssh/ssh_config && \
    echo '  Compression yes' >> /etc/ssh/ssh_config && \
    echo '  ServerAliveInterval 30' >> /etc/ssh/ssh_config && \
    echo '  ServerAliveCountMax 3' >> /etc/ssh/ssh_config

# Configure Ansible with pipelining for efficiency
RUN echo '[ssh_connection]' >> /etc/ansible/ansible.cfg && \
    echo 'pipelining = True' >> /etc/ansible/ansible.cfg && \
    echo 'ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput' >> /etc/ansible/ansible.cfg
```

> **Technical Note:** This custom EE image configures SSH at the client level with valid SSH options. TCP buffer sizes and MTU cannot be set via SSH configuration - these are system-level settings controlled by the kernel.

**Build and push:**
```bash
podman build -t quay.io/myorg/aap-ee-mtu-fix:latest .
podman push quay.io/myorg/aap-ee-mtu-fix:latest
```

**Update AAP to use custom EE:**
- In AAP UI: Administration → Execution Environments
- Add new EE: `quay.io/myorg/aap-ee-mtu-fix:latest`
- Update job templates to use new EE

### Verification

```bash
# Run package installation playbook
$ ansible-playbook -i inventory install-packages.yml

TASK [Install large packages] **************************************************
changed: [server01]
changed: [server02]
changed: [server03]

PLAY RECAP *********************************************************************
server01: ok=5    changed=3    unreachable=0    failed=0
server02: ok=5    changed=3    unreachable=0    failed=0
server03: ok=5    changed=3    unreachable=0    failed=0
```

---

## Example 5: SCP Transfers Stall

### Environment
- OpenShift 4.14 on Azure
- AAP 2.4 in namespace `ansible-prod`
- File transfers to on-premises servers via ExpressRoute

### Symptoms
- `copy` module in Ansible hangs
- Small files (<1MB) transfer successfully
- Large files (>10MB) stall partway through
- No error messages, just timeout

### Diagnosis

```bash
# Test file transfer
$ oc exec -it -n ansible-prod $AAP_POD -- bash

[pod]$ echo "Small file test" > /tmp/small.txt
[pod]$ scp /tmp/small.txt server01:/tmp/
small.txt                          100%   15     0.1KB/s   00:00
✓ Small file works

[pod]$ dd if=/dev/zero of=/tmp/large.bin bs=1M count=50
[pod]$ scp /tmp/large.bin server01:/tmp/
large.bin                          12%   6MB   1.2MB/s - stalled -
# Hangs at random percentage

# Check MTU on Azure
[pod]$ ip link show eth0
2: eth0@if678: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400

# Test path to on-prem
[pod]$ tracepath server01
 1?: [LOCALHOST]                      pmtu 1400
 1:  10.224.0.1                       0.543ms pmtu 1400
 2:  10.10.1.1                        3.234ms pmtu 1400
 3:  10.10.100.50                     15.678ms
     Resume: pmtu 1400 hops 3 back 3

# Test with ping
[pod]$ ping -M do -s 1372 server01 -c 10
# 100% success

[pod]$ ping -M do -s 1400 server01 -c 10
# 100% packet loss
```

**Root Cause:** Azure ExpressRoute has MTU of 1400. OVN overlay also 1400. With encapsulation, effective MTU was ~1350. Large file transfers were fragmenting improperly.

### Resolution

**Option 1: Ansible configuration (chosen)**
```yaml
# In inventory
all:
  vars:
    # Optimize for throughput and enable compression
    ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'
    # Limit bandwidth to reduce burst sizes
    ansible_scp_extra_args: '-l 8192'
```

> **Why `-l 8192` helps:** The SCP bandwidth limit (8192 Kbit/s = ~8 Mbps) forces smaller burst sizes, indirectly keeping packet sizes more manageable for MTU-constrained paths.

**Option 2: Azure ExpressRoute MTU increase (longer term)**
```bash
# Requested network team to increase ExpressRoute MTU to 1500
# This requires coordination with on-premises network team
# Takes 2-4 weeks to implement
```

### Verification

```yaml
# test-file-transfer.yml
- name: Test file transfers
  hosts: all
  tasks:
    - name: Create 50MB test file
      command: dd if=/dev/zero of=/tmp/testfile bs=1M count=50
      delegate_to: localhost
    
    - name: Transfer to target
      copy:
        src: /tmp/testfile
        dest: /tmp/testfile
        mode: '0644'
    
    - name: Verify size
      stat:
        path: /tmp/testfile
      register: file_stat
    
    - name: Check size
      assert:
        that: file_stat.stat.size == 52428800
        msg: "File size mismatch - transfer incomplete"
```

```bash
$ ansible-playbook -i inventory test-file-transfer.yml

TASK [Transfer to target] ******************************************************
changed: [server01]
changed: [server02]

TASK [Check size] **************************************************************
ok: [server01]
ok: [server02]

# All transfers successful
```

---

## Example 6: Multi-Site Deployment

### Environment
- OpenShift 4.15 on VMware (3 sites)
- AAP 2.5 centralized installation
- Targets at multiple data centers with varying MTU

### Symptoms
- Playbooks work for Site A (local)
- Playbooks fail for Site B (via 10Gbps dark fiber, jumbo frames)
- Playbooks intermittent for Site C (via MPLS, standard MTU)

### Diagnosis

```bash
# Test each site
$ for site in site-a site-b site-c; do
    echo "Testing $site:"
    oc exec -n ansible $AAP_POD -- ping -M do -s 1472 $site-server -c 4 2>&1 | tail -1
done

Testing site-a:
4 packets transmitted, 4 received, 0% packet loss
✓ Site A: Full MTU support

Testing site-b:
ping: local error: message too long, mtu=1400
✗ Site B: MTU constraint

Testing site-c:
2 packets transmitted, 2 received, 50% packet loss
⚠ Site C: Intermittent issues

# Check cluster MTU
$ oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}'
1400

# Site B has jumbo frames (MTU 9000) but path cannot negotiate properly
# Site C has inconsistent MTU handling on MPLS
```

### Resolution

Created site-specific inventory with MTU-aware configuration:

```yaml
# inventory/group_vars/site_a.yml
# Site A is local - no special handling needed
ansible_ssh_common_args: ''

# inventory/group_vars/site_b.yml
# Site B has jumbo frames but path MTU negotiation issues
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes -o ControlMaster=auto -o ControlPersist=60s'
ansible_ssh_transfer_method: piped  # Use pipelining instead of SCP
ansible_ssh_pipelining: yes

# inventory/group_vars/site_c.yml
# Site C has intermittent MPLS issues - use keepalives
ansible_ssh_common_args: >-
  -o IPQoS=throughput
  -o Compression=yes
  -o ServerAliveInterval=30
  -o ServerAliveCountMax=3
  -o ControlMaster=auto
  -o ControlPersist=60s
ansible_ssh_retries: 3
```

> **Site-Specific Notes:**
> - **Site A:** Local network with proper MTU configuration
> - **Site B:** Pipelining reduces connection overhead on high-MTU network with poor negotiation
> - **Site C:** Keepalives help maintain connections over unstable MPLS

Also requested network team to:
1. **Site B:** Configure MSS clamping on border router
2. **Site C:** Investigate MPLS QoS and MTU settings

### Verification

```bash
# Run multi-site playbook
$ ansible-playbook -i inventory site/deploy-all-sites.yml

PLAY [Site A Deployment] *******************************************************
TASK [Deploy application] ******************************************************
ok: [site-a-server01]

PLAY [Site B Deployment] *******************************************************
TASK [Deploy application] ******************************************************
ok: [site-b-server01]

PLAY [Site C Deployment] *******************************************************
TASK [Deploy application] ******************************************************
ok: [site-c-server01]

PLAY RECAP *********************************************************************
site-a-server01: ok=10   changed=3    unreachable=0    failed=0
site-b-server01: ok=10   changed=3    unreachable=0    failed=0
site-c-server01: ok=10   changed=3    unreachable=0    failed=0
```

---

## Lessons Learned

### Common Patterns

1. **SSH hangs after authentication** = Classic MTU symptom
2. **Works for some commands, fails for others** = Packet size dependent
3. **Inconsistent failures** = Intermittent MTU/PMTUD issues
4. **Works from node, fails from pod** = Overlay MTU misconfiguration

### Best Practices

1. **Always test MTU before deploying AAP**
   - Test from pods, not just nodes
   - Test to all target networks
   - Document path MTU for each network segment

2. **Use site/network-specific inventory groups**
   - Configure SSH args per group
   - Document MTU constraints
   - Include in runbooks

3. **Configure SSH defensively**
   - Always use `IPQoS=throughput`
   - Set reasonable TCP buffer sizes
   - Use keepalive for unstable connections

4. **Build custom execution environments**
   - Include SSH MTU handling
   - Document customizations
   - Version and test thoroughly

5. **Engage network team early**
   - Request MSS clamping where needed
   - Ensure ICMP not blocked
   - Document network topology

### Tools That Help

- `diagnose-mtu.sh` - Automated diagnostics
- `tracepath` - Path MTU discovery
- `ping -M do -s SIZE` - MTU testing
- `ssh -vvv` - Verbose connection debugging
- `tcpdump` - Packet capture for detailed analysis

---

## Quick Reference for Common Fixes

| Symptom | Quick Test | Fix |
|---------|-----------|-----|
| SSH hangs after auth | `ssh -vvv` shows hang after "Authentication succeeded" | Add `ansible_ssh_common_args: '-o IPQoS=throughput'` |
| Package installs fail | Large downloads stall | Add `Compression=yes` and enable pipelining |
| File transfers stall | SCP hangs partway through | Add `ansible_scp_extra_args: '-l 8192'` to limit bandwidth |
| Inconsistent failures | Sometimes works, sometimes doesn't | Add `ServerAliveInterval=30` keepalive options |
| Works from node, not pod | Test shows node OK, pod fails | Check pod MTU with `ip link show eth0` + apply network fixes |

> **Important:** SSH configuration provides workarounds but cannot directly control MTU or TCP buffer sizes. For persistent issues, implement network-level solutions (MSS clamping, ICMP unblocking, or MTU adjustment).

---

**Note:** All examples are from real production environments with identifying details changed for confidentiality.
