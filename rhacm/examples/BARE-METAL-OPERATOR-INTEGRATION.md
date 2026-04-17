# RHACM Bare Metal Operator Integration

**Target Audience**: Platform Engineers, Cluster Administrators  
**Purpose**: Understand RHACM's integration with Metal³ and bare metal provisioning  
**Last Updated**: February 13, 2026

---

## Overview

Red Hat Advanced Cluster Management (RHACM) integrates with the **Metal³ (Metal Cubed)** project to enable declarative, Kubernetes-native provisioning and lifecycle management of OpenShift clusters on bare metal infrastructure. This integration bridges the gap between physical hardware and cloud-native cluster management.

### What is Metal³?

Metal³ provides bare metal host management for Kubernetes through:
- **Baremetal Operator**: Core component managing bare metal host provisioning
- **Ironic Integration**: Uses OpenStack Ironic for BMC (Baseboard Management Controller) operations
- **Cluster API Provider**: Integration with Kubernetes Cluster API for cluster lifecycle management

**Key Benefit**: Treat bare metal servers as declarative Kubernetes resources, just like cloud VMs.

---

## Architecture Components

### Hub Cluster Components

RHACM hub cluster contains the control plane for bare metal cluster lifecycle:

```
┌─────────────────────────────────────────────────────┐
│              RHACM Hub Cluster                      │
├─────────────────────────────────────────────────────┤
│  • Multicluster Engine (MCE)                        │
│  • Infrastructure Operator                          │
│  • Assisted Service (on-premise or SaaS)            │
│  • Hub Inventory Controller                         │
│  • GitOps Operator (optional)                       │
└─────────────────────────────────────────────────────┘
           │                    │                    
           ▼                    ▼                    
    ┌──────────────┐    ┌──────────────┐
    │ BareMetalAsset│    │ ManagedCluster│
    │      CRD      │    │     CRD       │
    └──────────────┘    └──────────────┘
```

### Managed Cluster Components

When provisioned, bare metal clusters include:

```
┌─────────────────────────────────────────────────────┐
│         Bare Metal OpenShift Cluster                │
├─────────────────────────────────────────────────────┤
│  • Baremetal Operator (optional)                    │
│  • Klusterlet (RHACM agent)                         │
│  • BareMetalHost CRDs (if IPI)                      │
└─────────────────────────────────────────────────────┘
           │                    
           ▼                    
    ┌──────────────┐
    │  Physical    │
    │  Servers     │
    │  (BMC/IPMI)  │
    └──────────────┘
```

---

## Key Custom Resource Definitions (CRDs)

RHACM bare metal integration uses several CRDs to manage the complete lifecycle. Here are the five primary resources:

### 1. BareMetalAsset (Hub Cluster)

**Purpose**: Inventory record of physical/virtual servers on the hub cluster

**Managed By**: RHACM Hub Inventory Controller

**API**: `inventory.open-cluster-management.io/v1alpha1`

**Use Case**: Represents bare metal infrastructure in CMDB-like fashion

**Note**: `BareMetalAsset` is available in RHACM 2.3+ for bare metal inventory management. Not required for Assisted Installer deployments but useful for hardware inventory tracking.

```yaml
apiVersion: inventory.open-cluster-management.io/v1alpha1
kind: BareMetalAsset
metadata:
  name: server-rack1-01
  namespace: open-cluster-management
spec:
  bmc:
    address: redfish://10.20.30.40:8000/redfish/v1/Systems/1
    credentialsName: server-rack1-01-bmc-secret
  bootMACAddress: "52:54:00:aa:bb:01"
  hardwareProfile: "dell-r640"
  role: worker
  clusterDeployment:
    name: prod-cluster-01
    namespace: prod-cluster-01
```

**Key Fields**:
- `bmc.address`: BMC connection URL (Redfish, IPMI, iDRAC, iLO)
- `bootMACAddress`: Primary network interface MAC for PXE boot
- `hardwareProfile`: Hardware template (CPU, memory, disk profiles)
- `role`: Target role in cluster (master, worker)
- `clusterDeployment`: Link to target cluster deployment

### 2. BareMetalHost (Managed Cluster)

**Purpose**: Represents physical server in Metal³ operator

**Managed By**: Metal³ Baremetal Operator

**API**: `metal3.io/v1alpha1`

```yaml
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: worker-0
  namespace: openshift-machine-api
  labels:
    infraenvs.agent-install.openshift.io: "prod-cluster-01"
spec:
  online: true
  bootMACAddress: "52:54:00:aa:bb:01"
  bmc:
    address: redfish://10.20.30.40:8000/redfish/v1/Systems/1
    credentialsName: worker-0-bmc-secret
    disableCertificateVerification: false
  rootDeviceHints:
    deviceName: "/dev/sda"
  # Optional: specify boot image
  image:
    url: "http://mirror.example.com/rhcos-4.14.iso"
    checksum: "sha256:abcd1234..."
  userData:
    name: worker-0-user-data
    namespace: openshift-machine-api
status:
  provisioning:
    state: provisioned  # States: registering, inspecting, available, provisioning, provisioned
    ID: "unique-server-id"
  hardware:
    cpu:
      arch: x86_64
      count: 48
      model: "Intel(R) Xeon(R) Gold 6252"
    storage:
      - name: /dev/sda
        sizeBytes: 960000000000
        model: "SAMSUNG MZ7LH960"
    nics:
      - name: eno1
        mac: "52:54:00:aa:bb:01"
        ip: "10.20.30.41"
```

**Key Fields**:
- `online`: Power state control (true = power on)
- `bmc`: BMC connection details
- `rootDeviceHints`: Disk selection criteria for OS installation
- `image`: CoreOS/RHCOS image to deploy
- `status.provisioning.state`: Current provisioning state

**Provisioning States**:
1. **registering**: Initial BMC connection validation
2. **inspecting**: Hardware inventory collection (introspection)
3. **available**: Ready for provisioning
4. **provisioning**: OS deployment in progress
5. **provisioned**: Successfully deployed, in use
6. **deprovisioning**: Being cleaned/released
7. **error**: Provisioning failure

### 3. ClusterDeployment

**Purpose**: Defines desired state of OpenShift cluster to be deployed

**Managed By**: RHACM / Hive Operator

**API**: `hive.openshift.io/v1`

```yaml
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: prod-cluster-01
  namespace: prod-cluster-01
spec:
  baseDomain: example.com
  clusterName: prod-cluster-01
  platform:
    agentBareMetal:
      agentSelector:
        matchLabels:
          cluster: prod-cluster-01
  provisioning:
    installConfigSecretRef:
      name: prod-cluster-01-install-config
    sshPrivateKeySecretRef:
      name: prod-cluster-01-ssh-key
    imageSetRef:
      name: openshift-v4.14
  pullSecretRef:
    name: prod-cluster-01-pull-secret
status:
  conditions:
    - type: ProvisionFailed
      status: "False"
    - type: Provisioned
      status: "True"
  installerImage: quay.io/openshift-release-dev/ocp-release:4.14.0
  cliImage: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```

### 4. AgentClusterInstall

**Purpose**: Agent-based installer configuration for cluster deployment

**Managed By**: Assisted Service / Infrastructure Operator

**API**: `extensions.hive.openshift.io/v1beta1`

```yaml
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: prod-cluster-01
  namespace: prod-cluster-01
spec:
  clusterDeploymentRef:
    name: prod-cluster-01
  imageSetRef:
    name: openshift-v4.14
  networking:
    clusterNetwork:
      - cidr: 10.128.0.0/14
        hostPrefix: 23
    serviceNetwork:
      - 172.30.0.0/16
    machineNetwork:
      - cidr: 10.20.30.0/24
  apiVIP: 10.20.30.10
  ingressVIP: 10.20.30.11
  provisionRequirements:
    controlPlaneAgents: 3
    workerAgents: 2
  sshPublicKey: "ssh-rsa AAAAB3NzaC1yc2E..."
status:
  conditions:
    - type: Completed
      status: "True"
      reason: InstallationCompleted
  debugInfo:
    state: installed
    stateInfo: "Cluster is installed"
```

**Key Fields**:
- `clusterDeploymentRef`: Links to ClusterDeployment
- `imageSetRef`: OpenShift version to install
- `networking`: Cluster network configuration
- `apiVIP`/`ingressVIP`: Virtual IPs for cluster access (required for bare metal)
- `provisionRequirements`: Minimum number of agents needed

### 5. InfraEnv (Infrastructure Environment)

**Purpose**: Defines the discovery ISO generation parameters and agent registration

**Managed By**: Assisted Service

**API**: `agent-install.openshift.io/v1beta1`

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: InfraEnv
metadata:
  name: prod-cluster-01
  namespace: prod-cluster-01
spec:
  clusterRef:
    name: prod-cluster-01
    namespace: prod-cluster-01
  pullSecretRef:
    name: prod-cluster-01-pull-secret
  sshAuthorizedKey: "ssh-rsa AAAAB3NzaC1yc2E..."
  agentLabelSelector:
    matchLabels:
      cluster: prod-cluster-01
  nmStateConfigLabelSelector:
    matchLabels:
      cluster: prod-cluster-01
  # Optional: add additional NTP sources
  additionalNTPSources:
    - time.example.com
  # Optional: proxy configuration
  proxy:
    httpProxy: http://proxy.example.com:8080
    httpsProxy: http://proxy.example.com:8080
    noProxy: .cluster.local,.svc,localhost,127.0.0.1
status:
  conditions:
    - type: ImageCreated
      status: "True"
      reason: ImageCreated
  isoDownloadURL: "https://assisted-service.example.com/api/assisted-install/v2/infra-envs/abc123/downloads/image"
  createdTime: "2026-02-13T10:00:00Z"
```

**Key Fields**:
- `clusterRef`: Links to ClusterDeployment for automatic association
- `pullSecretRef`: Pull secret for downloading RHCOS image
- `sshAuthorizedKey`: SSH key for debugging booted agents
- `agentLabelSelector`: Match agents to this infrastructure environment
- `nmStateConfigLabelSelector`: Match network configs to apply
- `status.isoDownloadURL`: Generated ISO download link

**Important**: The InfraEnv must be created before agents can boot and register. The Assisted Service watches InfraEnv resources and generates discovery ISOs containing embedded registration tokens.

---

## Integration Workflows

### Workflow 1: Declarative Bare Metal Cluster Provisioning

**Goal**: Deploy a new OpenShift cluster on bare metal hardware using GitOps

**Steps**:

```
1. Create BareMetalAsset inventory (Hub)
   └─> External CMDB sync or manual creation
   
2. Create ClusterDeployment + AgentClusterInstall (Hub)
   └─> Defines desired cluster state
   
3. Assisted Service generates discovery ISO
   └─> ISO includes agent and cluster registration info
   
4. Boot bare metal servers from ISO
   └─> Agents report hardware inventory to hub
   
5. AgentClusterInstall validates requirements
   └─> Checks CPU, memory, disk, network
   
6. Assisted Service orchestrates installation
   └─> Deploys OpenShift on validated hosts
   
7. BareMetalHost CRDs created in cluster
   └─> Metal³ operator manages hardware lifecycle
   
8. ManagedCluster auto-created and imported
   └─> Cluster joins RHACM for management
```

**Key Automation**: When `ClusterDeployment` and `AgentClusterInstall` are created, RHACM automatically:
- Generates import manifests
- Can auto-import cluster upon successful installation (if configured)
- Links `BareMetalAsset` to actual deployed hosts

### Workflow 2: IPI (Installer-Provisioned Infrastructure) Bare Metal

**Goal**: Deploy OpenShift where installer manages all infrastructure

**Architecture**:
```
RHACM Hub
    ↓
ClusterDeployment (defines cluster)
    ↓
Installer Pod (creates BareMetalHost CRDs)
    ↓
Metal³ Baremetal Operator (provisions servers via Ironic)
    ↓
Physical Servers (via BMC)
```

**Key Feature**: Metal³ operator uses OpenStack Ironic to:
- Power cycle servers via BMC/IPMI/Redfish
- Boot servers from network/virtual media
- Monitor provisioning progress
- Perform hardware introspection

### Workflow 3: Hub Inventory Controller Reconciliation

**Purpose**: Sync `BareMetalAsset` (hub) with `BareMetalHost` (managed cluster)

```python
# Pseudocode for reconciliation logic
def reconcile_inventory():
    hub_assets = get_all_baremetalassets()
    
    for asset in hub_assets:
        cluster = asset.spec.clusterDeployment.name
        
        # Check if cluster is deployed and managed
        if is_cluster_deployed(cluster) and is_managed(cluster):
            # Query BareMetalHost in managed cluster
            managed_host = get_baremetalhost(cluster, asset.name)
            
            # Sync status back to hub asset
            if managed_host:
                asset.status.hardware = managed_host.status.hardware
                asset.status.provisioning = managed_host.status.provisioning
                asset.status.lastUpdated = now()
            
            update_hub_asset(asset)
```

**Benefit**: Hub cluster maintains single source of truth for all bare metal infrastructure across all managed clusters.

---

## Provisioning Methods

### Method 1: Assisted Installer with Discovery ISO

**Best For**: New cluster deployments, remote sites, edge computing

**Process**:
1. Create `ClusterDeployment`, `AgentClusterInstall`, and `InfraEnv` on hub
2. Assisted Service generates discovery ISO with embedded agent
3. Boot bare metal servers from ISO (USB, virtual media, PXE)
4. Agents discover hardware and report to hub (become `Agent` resources)
5. Once validated, installation proceeds automatically
6. Cluster auto-imports into RHACM (optional)

**Required CRDs**: `ClusterDeployment`, `AgentClusterInstall`, `InfraEnv` (defines ISO generation parameters)

**Example: Create InfraEnv and Download Discovery ISO**:
```bash
#!/bin/bash
# get-discovery-iso.sh

CLUSTER_NAME="prod-cluster-01"
NAMESPACE="$CLUSTER_NAME"

# InfraEnv should already be created via GitOps or kubectl apply
# This script waits for the ISO to be generated

# Wait for InfraEnv to be ready (contains ISO URL)
echo "Waiting for discovery ISO generation..."
kubectl wait --for=condition=ImageCreated \
  infraenv/${CLUSTER_NAME} -n ${NAMESPACE} --timeout=300s

# Get ISO download URL
ISO_URL=$(kubectl get infraenv ${CLUSTER_NAME} -n ${NAMESPACE} \
  -o jsonpath='{.status.isoDownloadURL}')

echo "Discovery ISO available at: $ISO_URL"

# Download ISO
curl -o ${CLUSTER_NAME}-discovery.iso "$ISO_URL"

echo "ISO downloaded: ${CLUSTER_NAME}-discovery.iso"
echo "Boot your bare metal servers from this ISO to begin discovery."
```

**What Happens When Hosts Boot from ISO**:
1. Agent starts and connects to Assisted Service (URL embedded in ISO)
2. Agent becomes an `Agent` resource on hub cluster
3. Agent reports hardware inventory (CPU, memory, disks, NICs)
4. Agent waits for cluster assignment (via `agentLabelSelector`)
5. Once assigned and validated, installation proceeds

**Network Configuration**: Use `NMStateConfig` for static IP configuration. This CRD allows you to define network settings that will be applied to hosts during discovery:

```yaml
apiVersion: agent-install.openshift.io/v1beta1
kind: NMStateConfig
metadata:
  name: prod-cluster-01-worker-0
  namespace: prod-cluster-01
  labels:
    infraenvs.agent-install.openshift.io: prod-cluster-01
spec:
  config:
    interfaces:
      - name: eno1
        type: ethernet
        state: up
        ipv4:
          enabled: true
          address:
            - ip: 10.20.30.41
              prefix-length: 24
          dhcp: false
    routes:
      config:
        - destination: 0.0.0.0/0
          next-hop-address: 10.20.30.1
          next-hop-interface: eno1
  interfaces:
    - name: eno1
      macAddress: "52:54:00:aa:bb:01"
```

### Method 2: IPI with Metal³ and Ironic

**Best For**: Data center deployments, standardized hardware, PXE infrastructure

**Requirements**:
- Provisioner node (bootstrap node) with RHEL/RHCOS
- PXE/DHCP infrastructure
- HTTP server for hosting images
- BMC/IPMI access to all servers

**Process**:
1. Provisioner node boots and runs local Ironic service
2. Creates `BareMetalHost` CRDs for control plane nodes
3. Metal³ operator uses Ironic to:
   - Inspect hardware (introspection)
   - Deploy RHCOS image via PXE
   - Configure nodes as control plane
4. Control plane brings up Machine API
5. Machine API creates `BareMetalHost` for workers
6. Workers provisioned via same Metal³/Ironic flow

**Key Difference from Assisted Installer**: 
- IPI requires provisioner node and local infrastructure
- Assisted Installer is SaaS-based, no provisioner needed

### Method 3: UPI (User-Provisioned Infrastructure)

**Best For**: Air-gapped environments, existing provisioning systems, maximum control

**Process**:
1. Manually provision and boot all nodes (control plane + workers)
2. Nodes run CoreOS with ignition configs
3. Deploy cluster via `openshift-install` command
4. Manually import cluster into RHACM using `ManagedCluster` CRD

**Metal³ Integration**: Minimal or none - cluster pre-exists before RHACM import

---

## Automatic Cluster Import

### How It Works

When a cluster is deployed via RHACM (using `ClusterDeployment`), the system can automatically import it as a `ManagedCluster`:

**Configuration**:
```yaml
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: prod-cluster-01
  namespace: prod-cluster-01
  annotations:
    # Enable automatic import after deployment
    hive.openshift.io/auto-import: "true"
spec:
  # ... cluster spec ...
```

**Behind the Scenes**:
1. `ClusterDeployment` controller monitors installation progress
2. Once cluster reports `Provisioned` status, controller:
   - Creates `ManagedCluster` CRD
   - Creates import secret with klusterlet manifests
   - Applies import manifests to newly deployed cluster
3. Klusterlet agents connect back to hub
4. Cluster appears in RHACM console as managed

**Manual Import for UPI Clusters**:
If cluster was deployed outside RHACM (UPI), manually create:
```yaml
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: prod-cluster-01
spec:
  hubAcceptsClient: true
---
apiVersion: agent.open-cluster-management.io/v1
kind: KlusterletAddonConfig
metadata:
  name: prod-cluster-01
  namespace: prod-cluster-01
spec:
  clusterName: prod-cluster-01
  clusterNamespace: prod-cluster-01
  applicationManager:
    enabled: true
  policyController:
    enabled: true
  searchCollector:
    enabled: true
  certPolicyController:
    enabled: true
```

Then apply generated import manifests to target cluster.

---

## GitOps Integration

### Complete Declarative Workflow

Store all CRDs in Git and use ArgoCD/OpenShift GitOps to manage:

**Repository Structure**:
```
clusters/
├── prod-cluster-01/
│   ├── namespace.yaml
│   ├── baremetalassets/
│   │   ├── master-0.yaml
│   │   ├── master-1.yaml
│   │   ├── master-2.yaml
│   │   ├── worker-0.yaml
│   │   └── worker-1.yaml
│   ├── cluster-deployment.yaml
│   ├── agent-cluster-install.yaml
│   ├── infraenv.yaml
│   ├── nmstate-configs/
│   │   ├── master-0-nmstate.yaml
│   │   ├── worker-0-nmstate.yaml
│   │   └── ...
│   └── secrets/
│       ├── pull-secret.yaml (sealed)
│       ├── ssh-key.yaml (sealed)
│       └── bmc-secrets/ (sealed)
└── prod-cluster-02/
    └── ...
```

**ArgoCD Application**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-cluster-01-provisioning
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/cluster-configs.git
    targetRevision: main
    path: clusters/prod-cluster-01
  destination:
    server: https://kubernetes.default.svc
    namespace: prod-cluster-01
  syncPolicy:
    automated:
      prune: false  # Don't auto-delete clusters!
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Benefits**:
- Version control for entire cluster lifecycle
- Peer review for cluster deployments (PR-based)
- Drift detection and correction
- Disaster recovery (redeploy from Git)

---

## Hardware Profiles and Matching

### Hardware Profiles

Define reusable templates for different server types:

```yaml
apiVersion: metal3.io/v1alpha1
kind: HardwareProfile
metadata:
  name: dell-r640
spec:
  cpu:
    minimumCount: 16
    architecture: x86_64
  memory:
    minimumSizeGB: 64
  storage:
    minimumCount: 2
    minimumSizeGB: 240
  nics:
    minimumCount: 2
```

**Usage**: Reference in `BareMetalAsset` or `BareMetalHost` to ensure hardware meets requirements.

### Agent Selector Matching

For Assisted Installer deployments, use labels to bind agents to clusters:

```yaml
apiVersion: extensions.hive.openshift.io/v1beta1
kind: AgentClusterInstall
metadata:
  name: prod-cluster-01
spec:
  agentSelector:
    matchLabels:
      cluster: prod-cluster-01
      location: datacenter-east
      hardware-profile: dell-r640
```

Agents (booted from discovery ISO) report labels, and controller matches them to clusters based on selectors.

---

## Monitoring and Observability

### Cluster Deployment Status

Monitor deployment progress:

```bash
# Watch ClusterDeployment status
kubectl get clusterdeployment prod-cluster-01 -n prod-cluster-01 -w

# Check AgentClusterInstall progress
kubectl get agentclusterinstall prod-cluster-01 -n prod-cluster-01 -o yaml

# View conditions
kubectl get agentclusterinstall prod-cluster-01 -n prod-cluster-01 \
  -o jsonpath='{.status.conditions[*]}' | jq

# Check agent status
kubectl get agents -n prod-cluster-01
```

### BareMetalHost Health

```bash
# List all BareMetalHosts in cluster
oc get baremetalhosts -n openshift-machine-api

# Check specific host
oc get bmh worker-0 -n openshift-machine-api -o yaml

# View provisioning events
oc get events -n openshift-machine-api --field-selector involvedObject.name=worker-0
```

### RHACM Console

Navigate to: **Infrastructure → Clusters → prod-cluster-01**

View:
- Deployment progress
- Hardware inventory
- Network configuration
- Installation logs
- Import status

---

## Troubleshooting

### Common Issues

#### 1. BareMetalHost Stuck in "Registering"

**Symptom**: Host never progresses past initial BMC connection

**Causes**:
- Invalid BMC credentials
- Network connectivity to BMC
- Unsupported BMC protocol

**Debug**:
```bash
# Check BareMetalHost status
oc get bmh <name> -n openshift-machine-api -o yaml

# View baremetal-operator logs
oc logs -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state

# Test BMC connectivity manually
curl -k -u admin:password https://10.20.30.40:8000/redfish/v1/Systems/
```

**Fix**: Verify BMC credentials in secret, check firewall rules

#### 2. AgentClusterInstall Fails Validation

**Symptom**: Installation doesn't proceed, validation errors in status

**Common Validations**:
- Insufficient hosts (need 3 masters, N workers)
- Inadequate CPU/memory/disk on hosts
- Network connectivity issues
- DNS resolution failures
- NTP synchronization problems

**Debug**:
```bash
# Check validation details
kubectl get agentclusterinstall prod-cluster-01 -n prod-cluster-01 \
  -o jsonpath='{.status.conditions[?(@.type=="RequirementsMet")]}'

# View agent validation results
kubectl get agents -n prod-cluster-01 -o yaml | grep -A 20 validationsInfo
```

#### 3. Assisted Service Not Reachable

**Symptom**: Discovery ISO can't contact assisted service

**Causes**:
- Firewall blocking required ports (typically 80, 443, 8080, 8090, 6443)
- DNS resolution failure for assisted service
- Certificate validation issues
- Incorrect assisted-service URL in cluster configuration

**Debug**:
```bash
# Check assisted-service pod
oc get pods -n multicluster-engine | grep assisted-service

# View logs
oc logs -n multicluster-engine <assisted-service-pod>

# Test connectivity from agent host (adjust port based on your deployment)
curl -k https://assisted-service.apps.hub.example.com/api/assisted-install/v2/clusters
```

#### 4. ManagedCluster Not Auto-Imported

**Symptom**: Cluster deploys successfully but doesn't appear in RHACM

**Causes**:
- Missing `hive.openshift.io/auto-import: "true"` annotation
- Import secret not generated
- Network connectivity from cluster to hub

**Debug**:
```bash
# Check if ManagedCluster created
kubectl get managedcluster prod-cluster-01

# Check import secret exists
kubectl get secret prod-cluster-01-import -n prod-cluster-01

# View ManagedCluster conditions
kubectl get managedcluster prod-cluster-01 -o yaml | grep -A 10 conditions
```

**Manual Fix**:
```bash
# Extract and apply import manifests manually
kubectl get secret prod-cluster-01-import -n prod-cluster-01 \
  -o jsonpath='{.data.import\.yaml}' | base64 -d > import.yaml

# On target cluster
oc apply -f import.yaml
```

---

## Best Practices

### 1. Inventory Management

✅ **DO**:
- Maintain accurate `BareMetalAsset` inventory on hub
- Use consistent naming conventions (location-rack-position)
- Tag assets with labels (site, datacenter, owner)
- Keep BMC credentials in separate sealed secrets

❌ **DON'T**:
- Hardcode credentials in manifests
- Reuse MAC addresses across assets
- Skip hardware validation before deployment

### 2. Network Planning

✅ **DO**:
- Use separate VLANs for provisioning, management, application traffic
- Implement static IPs for control plane (API/Ingress VIPs)
- Configure NTP for time synchronization
- Plan DNS entries before deployment

❌ **DON'T**:
- Rely on DHCP for production clusters
- Use overlapping IP ranges
- Skip firewall rule planning

### 3. GitOps Workflow

✅ **DO**:
- Store all cluster definitions in Git
- Use ArgoCD for automated reconciliation
- Implement PR-based approval for production clusters
- Use Sealed Secrets or External Secrets Operator for credentials

❌ **DON'T**:
- Apply manifests directly with `kubectl apply`
- Commit secrets to Git in plain text
- Skip code review for cluster changes

### 4. Cluster Lifecycle

✅ **DO**:
- Monitor deployment progress actively
- Set up alerts for failed validations
- Test disaster recovery procedures
- Document decommissioning process

❌ **DON'T**:
- Leave failed deployments unattended
- Delete `ClusterDeployment` without cluster cleanup
- Skip backup of etcd and configuration

---

## Integration with Other RHACM Features

### Policy-Based Governance

Once clusters are imported, apply policies:

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: bare-metal-node-maintenance
  namespace: default
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
    - objectDefinition:
        apiVersion: policy.open-cluster-management.io/v1
        kind: ConfigurationPolicy
        metadata:
          name: ensure-metal3-operator
        spec:
          remediationAction: enforce
          severity: high
          object-templates:
            - complianceType: musthave
              objectDefinition:
                apiVersion: operators.coreos.com/v1alpha1
                kind: Subscription
                metadata:
                  name: cluster-baremetal-operator
                  namespace: openshift-machine-api
```

### Application Deployment

Deploy applications to bare metal clusters:

```yaml
apiVersion: app.k8s.io/v1beta1
kind: Application
metadata:
  name: production-app
  namespace: production-apps
spec:
  componentKinds:
    - group: apps.open-cluster-management.io
      kind: Subscription
  selector:
    matchLabels:
      environment: production
      platform: baremetal
```

### Observability

Enable monitoring for bare metal clusters:

```yaml
apiVersion: observability.open-cluster-management.io/v1beta2
kind: MultiClusterObservability
metadata:
  name: observability
spec:
  observabilityAddonSpec:
    enableMetrics: true
    interval: 30
  storageConfig:
    metricObjectStorage:
      name: thanos-object-storage
      key: thanos.yaml
```

Monitor Metal³-specific metrics:
- Host provisioning duration
- BMC connection failures
- Introspection completion rate
- Deprovisioning success rate

---

## Advanced Topics

### Multi-Cluster Hardware Pools

Share bare metal servers across multiple clusters:

```yaml
apiVersion: inventory.open-cluster-management.io/v1alpha1
kind: BareMetalAssetPool
metadata:
  name: shared-worker-pool
  namespace: open-cluster-management
spec:
  assets:
    - name: server-rack2-01
    - name: server-rack2-02
    - name: server-rack2-03
  allocationPolicy: dynamic
  maxClustersPerAsset: 1  # Hosted control planes can share
```

### Hosted Control Planes on Bare Metal

Run control planes as pods on hub cluster, workers on bare metal:

```yaml
apiVersion: hypershift.openshift.io/v1beta1
kind: HostedCluster
metadata:
  name: hosted-bm-cluster
  namespace: clusters
spec:
  release:
    image: quay.io/openshift-release-dev/ocp-release:4.14.0-x86_64
  platform:
    type: Agent
    agent:
      agentNamespace: hosted-bm-cluster-nodes
  services:
    - service: APIServer
      servicePublishingStrategy:
        type: LoadBalancer
    - service: OAuthServer
      servicePublishingStrategy:
        type: Route
    - service: Konnectivity
      servicePublishingStrategy:
        type: Route
    - service: Ignition
      servicePublishingStrategy:
        type: Route
```

**Benefit**: Lower infrastructure requirements, faster cluster provisioning

### Zero-Touch Provisioning (ZTP) at Scale

For edge computing scenarios with hundreds/thousands of sites:

```yaml
apiVersion: ran.openshift.io/v1
kind: SiteConfig
metadata:
  name: edge-site-001
  namespace: ztp-edge
spec:
  baseDomain: edge.example.com
  clusterName: edge-site-001
  clusterImageSetNameRef: openshift-4.14
  pullSecretRef:
    name: pull-secret
  clusters:
    - clusterName: edge-site-001
      networkType: OVNKubernetes
      nodes:
        - hostName: edge-site-001-node-0
          role: master
          bmcAddress: redfish://10.50.0.10/redfish/v1/Systems/1
          bmcCredentialsName: edge-site-001-bmc
          bootMACAddress: "aa:bb:cc:dd:ee:01"
          bootMode: UEFI
          rootDeviceHints:
            deviceName: /dev/sda
```

**Scale**: RHACM with ZTP can manage 3500+ single-node OpenShift clusters

---

## Resources

### Official Documentation
- [RHACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Metal³ Project](https://metal3.io/)
- [Assisted Installer Documentation](https://docs.redhat.com/en/documentation/assisted_installer_for_openshift_container_platform/)
- [OpenShift IPI Bare Metal](https://docs.redhat.com/en/documentation/openshift_container_platform/4.14/html/installing/installing-on-bare-metal)

### Community Resources
- [RHACM Policy Collection](https://github.com/stolostron/policy-collection)
- [Metal³ GitHub](https://github.com/metal3-io)
- [ZTP GitOps Examples](https://github.com/openshift-kni/cnf-features-deploy)

### Blogs and Guides
- [Provisioning Bare Metal Clusters with RHACM GitOps](https://www.redhat.com/en/blog/provisioning-baremetal-openshift-clusters-using-rhacm-with-gitops-leveraging-on-premise-assisted-installer)
- [End-to-End Declarative Provisioning](https://www.redhat.com/en/blog/end-end-declarative-provisioning-bare-metal-red-hat-openshift-clusters)
- [Hosted Control Planes on Bare Metal](https://www.redhat.com/en/blog/how-to-build-bare-metal-hosted-clusters-on-red-hat-advanced-cluster-management-for-kubernetes)

---

## Summary

RHACM's bare metal operator integration provides:

✅ **Declarative Infrastructure**: Manage physical servers as Kubernetes resources  
✅ **Unified Lifecycle**: Provision, import, manage, decommission clusters from one hub  
✅ **GitOps Native**: Store entire infrastructure as code in Git  
✅ **Multi-Method Support**: Assisted Installer, IPI, UPI, Hosted Control Planes  
✅ **Scale**: From single clusters to thousands (edge/ZTP scenarios)  
✅ **Automation**: Automatic import, hardware discovery, validation  

**Key Takeaway**: The integration bridges traditional bare metal operations with cloud-native Kubernetes management, enabling true infrastructure-as-code for physical servers.

---

---

## Document Metadata

**Version**: 1.0  
**Last Updated**: February 13, 2026  
**Status**: Review Draft

### Validation Notes

- Validated against RHACM 2.5+ and OpenShift 4.14+
- BareMetalHost API: `metal3.io/v1alpha1` (current as of Feb 2026)
- ClusterDeployment API: `hive.openshift.io/v1`
- AgentClusterInstall API: `extensions.hive.openshift.io/v1beta1`
- BareMetalAsset API: `inventory.open-cluster-management.io/v1alpha1` (RHACM 2.3+)

### API Version Notes

The Metal³ BareMetalHost API remains at v1alpha1 as of 2026. While "alpha" typically implies instability, this API has been stable and production-ready since OpenShift 4.6. The v1alpha1 designation is maintained for backward compatibility across the Metal³ ecosystem.

### Known Limitations

- BareMetalAsset CRD availability depends on RHACM version (2.3+)
- Assisted Installer port configuration may vary by deployment method (SaaS vs on-premise)
- IPI bare metal requires provisioner node with specific network connectivity
- Air-gapped deployments require additional mirror registry configuration
- NMStateConfig syntax may vary between OpenShift versions

### Contributing

This document is part of a living knowledge base. Feedback and improvements welcome:
- Validate CRD examples against your specific RHACM/OpenShift versions
- Test workflows in lab environments before production use
- Adapt examples to your organization's network topology and security requirements
- Report inaccuracies or suggest improvements via Git issues/PRs

---

**AI Disclosure**: This document was created with AI assistance as part of DevOps automation research and documentation efforts.
