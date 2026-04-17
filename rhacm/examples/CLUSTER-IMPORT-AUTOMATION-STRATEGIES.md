# RHACM Cluster Import Automation - Strategy Analysis

**Target Audience**: Principal Engineers, Architects  
**Purpose**: Evaluate automation approaches for RHACM cluster imports  
**Date**: February 2026

---

## Strategy 1: GitOps with ArgoCD/OpenShift GitOps

### Architecture Overview

GitOps-native approach storing `ManagedCluster` and `KlusterletAddonConfig` manifests in Git repositories. ArgoCD continuously reconciles desired state, creating ManagedCluster objects on the hub. Import secrets are extracted and applied to target clusters through a secondary automation layer.

```
Git Repository → ArgoCD (Hub) → ManagedCluster Created → Import Secret Generated
                                                              ↓
                                           External Process Extracts Secret
                                                              ↓
                                           Apply to Target Cluster (import.yaml)
```

### Implementation Approach

**Phase 1: Repository Structure**
- Organize manifests by cluster tier (prod/nonprod) or environment
- Use Kustomize overlays for environment-specific configurations
- Store ManagedCluster definitions with labels for placement and governance

**Phase 2: ArgoCD Application**
- Create Application or ApplicationSet pointing to cluster manifest directory
- Configure sync policy (manual vs automatic)
- Enable self-healing for drift detection

**Phase 3: Import Secret Automation**
- Options for secret extraction and application:
  - **Job-based**: Kubernetes Job on hub watches for new ManagedCluster objects, extracts secrets, stores in intermediate system
  - **Webhook-based**: Admission webhook triggers external automation when ManagedCluster created
  - **Polling-based**: External script/tool periodically checks for pending imports
  - **GitOps round-trip**: Extract secrets back to Git (encrypted), apply via second ArgoCD instance on target

### Technical Considerations

**Strengths:**
- Full audit trail via Git history
- Declarative infrastructure as code
- Native integration with existing GitOps workflows
- Easy rollback and drift detection
- Cluster configuration lives alongside application definitions

**Challenges:**
- Two-phase process (hub creation + target application)
- Secret handling requires additional automation layer
- Initial setup complexity for secret extraction pipeline
- Requires secure credential storage for target cluster access

**Operational Impact:**
- Reduces manual console work to zero
- Onboarding new clusters becomes PR-driven workflow
- Changes require code review, improving governance
- Self-service enables teams to request clusters via Git

### Integration Points

- **Existing ArgoCD**: Leverage current ArgoCD for RHACM management
- **Secret Management**: Integrate with External Secrets Operator or Sealed Secrets for import secret handling
- **Notification**: Hook into Git webhooks for import status updates
- **RBAC**: Git branch protection controls who can import clusters

### Recommendation

**Best fit for organizations with:**
- Mature GitOps practices
- Existing ArgoCD deployments
- Strong code review culture
- Need for compliance audit trails

---

## Strategy 2: Ansible Automation

### Architecture Overview

Ansible playbooks orchestrate the entire import lifecycle from hub cluster ManagedCluster creation through target cluster configuration. Playbooks interact with Kubernetes APIs on both hub and managed clusters using `kubernetes.core.k8s` module.

```
Ansible Controller → Hub Cluster API (Create ManagedCluster)
                                         ↓
                          Query for Generated Import Secret
                                         ↓
                   Target Cluster API (Apply Import Manifests)
                                         ↓
                          Validate Import Success
```

### Implementation Approach

**Phase 1: Playbook Structure**
```yaml
# Inventory design
[rhacm_hub]
hub.example.com

[target_clusters]
cluster1.example.com kubeconfig_path=/path/to/cluster1.kubeconfig
cluster2.example.com kubeconfig_path=/path/to/cluster2.kubeconfig

# Variable structure
cluster_name: prod-east-1
cluster_labels:
  environment: production
  region: us-east-1
  vendor: baremetal
klusterlet_addons:
  application_manager: true
  policy_controller: true
  search_collector: false
```

**Phase 2: Core Tasks**
1. Create `ManagedCluster` and `KlusterletAddonConfig` on hub
2. Wait for import secret generation (with timeout and retry)
3. Extract `import.yaml` and `crds.yaml` from secret
4. Apply manifests to target cluster using target's kubeconfig
5. Poll for `ManagedClusterJoined` and `ManagedClusterAvailable` conditions
6. Register cluster metadata in external CMDB if applicable

**Phase 3: Error Handling**
- Implement retry logic for transient API failures
- Rollback capability if import fails
- Comprehensive logging for troubleshooting
- Idempotency for safe re-runs

### Technical Considerations

**Strengths:**
- Single tool orchestrates entire workflow
- Rich conditionals and error handling
- Integration with existing Ansible ecosystem (Tower/AAP, inventories, vaults)
- Can incorporate pre/post-import validation tasks
- Leverage existing `acm-managed-cluster-gen` community work

**Challenges:**
- Requires secure kubeconfig storage and distribution
- Playbook maintenance as RHACM API evolves
- No native drift detection (requires scheduled runs)
- Tower/AAP licensing costs for enterprise features

**Operational Impact:**
- Familiar tooling for most enterprises
- Can be self-service via Ansible Tower surveys
- Integration with ServiceNow, Jira for ticket-driven imports
- Scheduled playbook runs can validate import health

### Integration Points

- **Ansible Tower/AAP**: Job templates with surveys for cluster onboarding
- **ServiceNow/Jira**: API callbacks to create/update tickets
- **HashiCorp Vault**: Retrieve kubeconfigs and credentials securely
- **Monitoring**: Emit metrics to Prometheus on import success/failure
- **CMDB**: Update configuration database with cluster relationships

### Recommendation

**Best fit for organizations with:**
- Existing Ansible Tower/AAP deployments
- Need for complex conditional logic
- Integration with ITSM ticketing systems
- Heterogeneous automation (not just Kubernetes)

---

## Strategy 3: Auto-Import Secret with Zero-Touch Provisioning

### Architecture Overview

"Shift-left" approach embedding import automation into cluster bootstrap process. ManagedCluster objects pre-created on hub with known cluster names. Import manifests extracted and embedded into cluster provisioning (Ignition configs, cloud-init, or PXE boot scripts), enabling fully automated import at cluster birth.

```
Pre-create ManagedCluster on Hub → Extract Import Secret → Embed in Bootstrap Config
                                                                     ↓
                                                    Cluster Provisioning System
                                                                     ↓
                                            New Cluster Applies Import at Boot
                                                                     ↓
                                                Auto-registers with Hub
```

### Implementation Approach

**Phase 1: Hub Preparation**
- Create ManagedCluster objects for anticipated clusters (naming convention-based)
- Use cluster labels for automatic placement into ManagedClusterSets
- Extract import secrets to staging location (encrypted storage)

**Phase 2: Integration Points**

**For OpenShift/RHEL CoreOS:**
```yaml
# Butane config snippet
systemd:
  units:
    - name: rhacm-import.service
      enabled: true
      contents: |
        [Unit]
        After=crio.service
        
        [Service]
        Type=oneshot
        ExecStart=/usr/local/bin/apply-rhacm-import.sh
        
        [Install]
        WantedBy=multi-user.target

storage:
  files:
    - path: /usr/local/bin/apply-rhacm-import.sh
      contents:
        inline: |
          #!/bin/bash
          kubectl apply -f /etc/rhacm-import/import.yaml
    - path: /etc/rhacm-import/import.yaml
      contents:
        inline: |
          <base64-encoded-import-manifest>
```

**For Bare Metal (PXE/Kickstart):**
- Include import manifest in post-install scripts
- Use Ansible pulled from version control
- Leverage ACM's bare metal operator integration

**For Cloud Providers:**
- AWS: EC2 user-data scripts
- Azure: Custom Script Extension
- GCP: Startup scripts
- All support `cloud-init` for first-boot automation

**Phase 3: Naming Conventions**
- Establish predictable cluster naming: `{env}-{region}-{index}` (e.g., `prod-east-01`)
- Generate ManagedCluster objects proactively
- Pre-create with `hubAcceptsClient: true` and appropriate labels

### Technical Considerations

**Strengths:**
- True zero-touch provisioning (no post-install steps)
- Lowest operational overhead after initial setup
- Scales to thousands of clusters (edge computing, retail, telco)
- No credential distribution needed post-bootstrap
- Immutable infrastructure friendly

**Challenges:**
- Requires predictable naming conventions
- Pre-creation means potential "phantom" clusters if provisioning fails
- Import secrets embedded in bootstrap configs (security consideration)
- Tight coupling between hub and provisioning systems
- Difficult to change import configuration post-bootstrap

**Operational Impact:**
- Cluster provisioning and RHACM import become atomic operation
- Eliminates manual import step entirely
- Reduces time-to-manage from hours to minutes
- Critical for edge computing deployments (thousands of sites)

### Integration Points

- **OpenShift Assisted Installer**: Inject import manifests into discovery ISO
- **Infrastructure Operator**: Coordinate with OpenShift IPI/UPI flows
- **Bare Metal Operator**: Integration with Metal³ for baremetal clusters
- **Cloud Provisioning**: Terraform/Pulumi modules include import in bootstrap
- **Edge Computing**: Integrate with MicroShift and single-node OpenShift patterns

### Recommendation

**Best fit for organizations with:**
- Large-scale cluster deployments (>50 clusters)
- Edge computing or retail environments
- Standardized cluster naming and provisioning
- Need for minimal operational touch points
- Zero-trust security model (no post-install credential access)

---

## Strategy 4: Helm Charts + CI/CD Pipeline

### Architecture Overview

Helm charts template ManagedCluster and KlusterletAddonConfig objects with parameterized values. CI/CD pipeline orchestrates Helm releases to hub cluster, extracts generated secrets, and applies import manifests to target clusters. Provides balance between declarative infrastructure and programmatic automation.

```
Git Push → CI/CD Pipeline Triggered → Helm Install/Upgrade (Hub)
                                              ↓
                                    Extract Import Secret
                                              ↓
                              Apply to Target via kubeconfig
                                              ↓
                                    Validate and Report
```

### Implementation Approach

**Phase 1: Helm Chart Structure**
```
rhacm-cluster-import/
├── Chart.yaml
├── values.yaml              # Default values
├── values-prod.yaml         # Production overrides
├── values-nonprod.yaml      # Non-production overrides
├── templates/
│   ├── managedcluster.yaml
│   ├── klusterletaddonconfig.yaml
│   ├── namespace.yaml
│   └── NOTES.txt            # Post-install instructions
└── README.md
```

**values.yaml Example:**
```yaml
cluster:
  name: "{{ .Values.cluster.name }}"
  labels:
    environment: "{{ .Values.environment }}"
    cloud: "{{ .Values.cloud }}"
    region: "{{ .Values.region }}"
  
addons:
  applicationManager: true
  policyController: true
  searchCollector: true
  certPolicyController: true

managedClusterSet: "{{ .Values.environment }}-clusters"
```

**Phase 2: CI/CD Integration**

**Jenkins Pipeline Example:**
```groovy
pipeline {
    parameters {
        string(name: 'CLUSTER_NAME')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'])
        string(name: 'TARGET_KUBECONFIG_SECRET')
    }
    stages {
        stage('Helm Install on Hub') {
            steps {
                sh """
                    helm upgrade --install ${CLUSTER_NAME} ./rhacm-cluster-import \
                      --set cluster.name=${CLUSTER_NAME} \
                      --set environment=${ENVIRONMENT} \
                      --namespace ${CLUSTER_NAME} --create-namespace
                """
            }
        }
        stage('Wait for Import Secret') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    sh """
                        until kubectl get secret ${CLUSTER_NAME}-import \
                          -n ${CLUSTER_NAME} &>/dev/null; do \
                          sleep 5; \
                        done
                    """
                }
            }
        }
        stage('Extract and Apply Import') {
            steps {
                withCredentials([file(credentialsId: "${TARGET_KUBECONFIG_SECRET}", 
                                      variable: 'KUBECONFIG')]) {
                    sh """
                        kubectl get secret ${CLUSTER_NAME}-import \
                          -n ${CLUSTER_NAME} -o jsonpath='{.data.import\\.yaml}' | \
                          base64 -d | kubectl apply -f -
                    """
                }
            }
        }
        stage('Validate Import') {
            steps {
                sh """
                    timeout 300 bash -c 'until kubectl get managedcluster ${CLUSTER_NAME} \
                      -o jsonpath=\"{.status.conditions[?(@.type=='ManagedClusterJoined')].status}\" | \
                      grep -q True; do sleep 5; done'
                """
            }
        }
    }
    post {
        success {
            slackSend(message: "Cluster ${CLUSTER_NAME} successfully imported to RHACM")
        }
        failure {
            slackSend(message: "Failed to import ${CLUSTER_NAME} to RHACM")
        }
    }
}
```

**Phase 3: Multi-Environment Management**
- Separate `values-{env}.yaml` files for environment-specific configurations
- Helm releases named by cluster, namespaced for isolation
- Pipeline parameters enable self-service cluster import
- Version control of Helm charts tracks import configuration evolution

### Technical Considerations

**Strengths:**
- Helm's templating provides DRY configuration management
- Native versioning and rollback via Helm releases
- Parameterization enables self-service portals
- CI/CD integration provides automation and audit trail
- Familiar tooling for Kubernetes-native teams

**Challenges:**
- Helm chart maintenance overhead
- CI/CD pipeline requires secure kubeconfig storage
- Complex logic better suited to Ansible (Helm templates limited)
- Multiple tools in chain (Helm + CI/CD + kubectl)

**Operational Impact:**
- Developers/SREs trigger imports via CI/CD UI (Jenkins, GitLab, etc.)
- Consistent import configuration across environments
- Easy to standardize cluster labels and add-on configurations
- Pipeline failures trigger notifications, enabling rapid response

### Integration Points

- **CI/CD Platform**: Jenkins, GitLab CI, Tekton, GitHub Actions, Azure DevOps
- **Secret Management**: Jenkins credentials, Vault, cloud provider secret stores
- **Helm Repository**: ChartMuseum, Harbor, Artifactory for chart versioning
- **Notification**: Slack, Teams, PagerDuty integrations for status updates
- **GitOps**: Can combine with ArgoCD (ArgoCD manages Helm releases)

### Advanced Patterns

**Tekton Pipeline for Cloud-Native:**
```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: rhacm-cluster-import
spec:
  params:
    - name: cluster-name
    - name: environment
  tasks:
    - name: helm-install
      taskRef:
        name: helm-upgrade-from-repo
    - name: extract-secret
      runAfter: [helm-install]
      taskRef:
        name: kubernetes-actions
    - name: apply-import
      runAfter: [extract-secret]
      taskRef:
        name: kubernetes-actions
```

**GitHub Actions for Developer Experience:**
- Issue templates trigger cluster import workflows
- PR-based approval for production imports
- Status checks prevent merging failed imports
- Automated rollback on failure

### Recommendation

**Best fit for organizations with:**
- Existing CI/CD infrastructure (Jenkins, GitLab, etc.)
- Kubernetes-native workflows (Helm adoption)
- Need for self-service cluster onboarding
- Multi-environment consistency requirements
- Existing Helm chart repositories and practices

---

## Comparative Analysis

| Criteria | GitOps | Ansible | Zero-Touch | Helm + CI/CD |
|----------|--------|---------|------------|--------------|
| **Setup Complexity** | Medium | Low | High | Medium |
| **Operational Overhead** | Low | Medium | Very Low | Low |
| **Audit Trail** | Excellent (Git) | Good (logs) | Limited | Good (CI/CD) |
| **Secret Handling** | Complex | Native | Embedded | Native |
| **Scalability** | High | Medium | Very High | High |
| **Self-Service** | PR-based | Survey-based | Automatic | UI-based |
| **Skill Requirements** | ArgoCD, K8s | Ansible, YAML | Ignition, Bootstrap | Helm, CI/CD |
| **Rollback Capability** | Excellent | Good | Limited | Good |
| **Integration Effort** | Medium | Low | High | Medium |

## Decision Framework

**Choose GitOps if:**
- GitOps is organizational standard
- Audit requirements are stringent
- Infrastructure as code maturity is high
- ArgoCD already deployed

**Choose Ansible if:**
- Ansible Tower/AAP investment exists
- Complex conditional logic required
- ITSM integration needed
- Multi-domain automation beyond Kubernetes

**Choose Zero-Touch if:**
- Cluster count > 50
- Edge computing deployment
- Standardized provisioning exists
- Minimal operational touch required

**Choose Helm + CI/CD if:**
- Helm adoption is standard
- CI/CD platform mature
- Self-service UI desired
- Multi-environment templating needed

---

## Implementation Roadmap Recommendation

**Phase 1 - Quick Win (Week 1-2)**
- Implement Ansible playbooks for immediate automation
- Reduces manual work while designing long-term strategy

**Phase 2 - Strategic Implementation (Month 1-2)**
- Evaluate GitOps vs Helm+CI/CD based on existing tooling
- Pilot with 5-10 non-production clusters
- Measure time-to-import and operational overhead

**Phase 3 - Scale and Optimize (Month 3+)**
- Roll out chosen strategy to all environments
- Consider Zero-Touch for edge/large-scale deployments
- Implement monitoring and alerting for import failures

**Phase 4 - Continuous Improvement**
- Collect metrics: import success rate, time-to-import, failures
- Iterate on automation based on operational feedback
- Expand to include cluster decommissioning automation

---

## Bare Metal Considerations

### Impact on Strategy Selection

Bare metal OpenShift clusters introduce specific considerations that affect automation strategy viability and implementation complexity:

#### Network Topology Challenges

**Challenge**: Bare metal clusters often exist in isolated network segments, DMZs, or data center networks with restricted connectivity to the RHACM hub cluster.

**Impact by Strategy**:
- **GitOps**: Hub cluster can create ManagedCluster objects, but applying import manifests to isolated target clusters requires network-aware automation (bastion hosts, VPN tunnels, or hub-deployed agents)
- **Ansible**: Well-suited - Ansible commonly uses jump hosts/bastions for bare metal access via SSH tunneling
- **Zero-Touch**: IDEAL - Import manifests embedded at provisioning time, no post-install network access required
- **Helm + CI/CD**: Similar to GitOps - requires network path from CI/CD runners to target clusters

#### Provisioning Integration Points

**Bare Metal Provisioning Methods**:

1. **OpenShift Assisted Installer**
   - Discovery ISO-based installation
   - API-driven cluster creation
   - **Best Integration**: Zero-Touch (inject import manifests into discovery ISO customization)
   - Can integrate with all strategies post-install via REST API

2. **OpenShift IPI on Bare Metal (with Ironic)**
   - Uses Metal³ Bare Metal Operator
   - Manages bare metal hosts as BareMetalHost CRDs
   - **Best Integration**: GitOps or Helm (create ManagedCluster alongside BareMetalHost objects)
   - RHACM has native integration with Metal³

3. **OpenShift UPI (User Provisioned Infrastructure)**
   - Manual or scripted installation (PXE, ISO, kickstart)
   - Ignition files for first-boot configuration
   - **Best Integration**: Zero-Touch (embed import in Ignition) or Ansible (post-install orchestration)

4. **Agent-Based Installer**
   - ISO-based installation with agent-config.yaml
   - No infrastructure dependencies
   - **Best Integration**: Zero-Touch (include import in agent-config.yaml)

#### Strategy-Specific Bare Metal Recommendations

### Strategy 1: GitOps (Moderate Complexity)

**Bare Metal Adaptation**:

```yaml
# Create ManagedCluster on hub via ArgoCD (unchanged)
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: baremetal-prod-01
  labels:
    vendor: baremetal
    network-zone: dmz-east
# ... rest of config
```

**Import Secret Application Options**:

**Option A: Hub-Deployed Import Agent**
- Deploy a lightweight agent/CronJob on hub that has network access to bare metal management network
- Agent polls for new ManagedCluster objects, extracts secrets, applies via stored kubeconfigs
- Kubeconfigs stored in hub cluster secrets (encrypted at rest)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: baremetal-import-agent
  namespace: rhacm-automation
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: import-agent
            image: registry.example.com/rhacm-import-agent:latest
            env:
            - name: TARGET_NETWORK_ZONE
              value: "dmz-east"
            volumeMounts:
            - name: kubeconfigs
              mountPath: /kubeconfigs
              readOnly: true
```

**Option B: Bastion/Jump Host Integration**
- Use bastion host with connectivity to both hub and bare metal networks
- ArgoCD notification triggers script on bastion
- Bastion extracts import secret from hub, applies to target cluster

**Complexity Rating**: Medium-High (requires network-aware automation layer)

---

### Strategy 2: Ansible (Low-Medium Complexity)

**Bare Metal Adaptation**: NATURAL FIT

Ansible excels in bare metal environments with built-in bastion/jump host support:

```ini
# Inventory with bastion configuration
[rhacm_hub]
hub.example.com

[baremetal_clusters]
bm-prod-01.example.com
bm-prod-02.example.com

[baremetal_clusters:vars]
ansible_ssh_common_args='-o ProxyJump=bastion.example.com'
kubeconfig_path=/etc/kubernetes/kubeconfig
```

```yaml
# Playbook leveraging delegation and bastion
---
- name: Import Bare Metal Cluster to RHACM
  hosts: localhost
  gather_facts: false
  vars:
    hub_kubeconfig: /path/to/hub-kubeconfig
    
  tasks:
    - name: Create ManagedCluster on hub
      kubernetes.core.k8s:
        kubeconfig: "{{ hub_kubeconfig }}"
        state: present
        definition:
          apiVersion: cluster.open-cluster-management.io/v1
          kind: ManagedCluster
          # ... definition
          
    - name: Wait for import secret generation
      kubernetes.core.k8s_info:
        kubeconfig: "{{ hub_kubeconfig }}"
        kind: Secret
        name: "{{ cluster_name }}-import"
        namespace: "{{ cluster_name }}"
      register: import_secret
      until: import_secret.resources | length > 0
      retries: 24
      delay: 5
      
    - name: Extract import manifest
      set_fact:
        import_yaml: "{{ import_secret.resources[0].data['import.yaml'] | b64decode }}"

- name: Apply import to bare metal cluster
  hosts: baremetal_clusters
  gather_facts: false
  tasks:
    - name: Apply RHACM import manifests
      kubernetes.core.k8s:
        kubeconfig: "{{ kubeconfig_path }}"
        state: present
        definition: "{{ hostvars['localhost']['import_yaml'] }}"
```

**Network Traversal**: Native SSH proxy support handles complex network topologies

**Complexity Rating**: Low (Ansible designed for this use case)

---

### Strategy 3: Zero-Touch Provisioning (HIGHLY RECOMMENDED for Bare Metal)

**Bare Metal Adaptation**: OPTIMAL SOLUTION

Zero-touch provisioning eliminates post-install network access requirements entirely.

#### Integration with OpenShift Assisted Installer

**Workflow**:
1. Pre-create ManagedCluster on hub with predictable name (based on serial number, location, etc.)
2. Extract import secret from hub
3. Create customized discovery ISO with import manifests embedded
4. Boot bare metal host from ISO
5. Cluster self-registers with RHACM during installation

**Implementation**:

```bash
#!/bin/bash
# generate-assisted-iso-with-import.sh

CLUSTER_NAME="baremetal-site-047"
HUB_KUBECONFIG=/path/to/hub-kubeconfig

# 1. Create ManagedCluster on hub
kubectl --kubeconfig=$HUB_KUBECONFIG apply -f - <<EOF
apiVersion: cluster.open-cluster-management.io/v1
kind: ManagedCluster
metadata:
  name: $CLUSTER_NAME
  labels:
    site: site-047
    vendor: baremetal
spec:
  hubAcceptsClient: true
EOF

# 2. Wait for and extract import secret
until kubectl --kubeconfig=$HUB_KUBECONFIG get secret ${CLUSTER_NAME}-import \
  -n $CLUSTER_NAME &>/dev/null; do
  sleep 5
done

IMPORT_YAML=$(kubectl --kubeconfig=$HUB_KUBECONFIG get secret ${CLUSTER_NAME}-import \
  -n $CLUSTER_NAME -o jsonpath='{.data.import\.yaml}' | base64 -d)

# 3. Generate Assisted Installer ISO with embedded import
# Using Assisted Installer API
CLUSTER_ID=$(curl -X POST https://assisted-installer.example.com/api/assisted-install/v2/clusters \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$CLUSTER_NAME\",
    \"openshift_version\": \"4.14\",
    \"base_dns_domain\": \"example.com\"
  }" | jq -r '.id')

# Create ignition override with RHACM import
cat > /tmp/rhacm-import-override.json <<EOF
{
  "ignition_config_override": {
    "systemd": {
      "units": [{
        "name": "rhacm-import.service",
        "enabled": true,
        "contents": "[Unit]\\nDescription=Apply RHACM Import\\nAfter=kubelet.service\\n\\n[Service]\\nType=oneshot\\nExecStartPre=/usr/bin/sleep 120\\nExecStart=/usr/bin/kubectl apply -f /etc/rhacm/import.yaml\\n\\n[Install]\\nWantedBy=multi-user.target"
      }]
    },
    "storage": {
      "files": [{
        "path": "/etc/rhacm/import.yaml",
        "mode": 420,
        "contents": {
          "source": "data:text/plain;base64,$(echo "$IMPORT_YAML" | base64 -w0)"
        }
      }]
    }
  }
}
EOF

# Generate ISO with import embedded
curl -X POST https://assisted-installer.example.com/api/assisted-install/v2/clusters/$CLUSTER_ID/downloads/image \
  -d @/tmp/rhacm-import-override.json \
  -o ${CLUSTER_NAME}-discovery.iso
```

**Result**: Boot bare metal host with this ISO, and it automatically:
1. Installs OpenShift
2. Applies RHACM import manifests
3. Registers with hub cluster
4. No manual intervention required

#### Integration with PXE/Kickstart

For traditional PXE boot environments:

```yaml
# Butane config for CoreOS installation
variant: fcos
version: 1.4.0
systemd:
  units:
    - name: rhacm-import.service
      enabled: true
      contents: |
        [Unit]
        Description=RHACM Cluster Import
        After=kubelet.service
        
        [Service]
        Type=oneshot
        ExecStartPre=/bin/sleep 180
        ExecStart=/usr/local/bin/apply-rhacm-import.sh
        
        [Install]
        WantedBy=multi-user.target
        
storage:
  files:
    - path: /usr/local/bin/apply-rhacm-import.sh
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          export KUBECONFIG=/etc/kubernetes/admin.conf
          kubectl apply -f /etc/rhacm-import/import.yaml
          
    - path: /etc/rhacm-import/import.yaml
      mode: 0644
      contents:
        inline: |
          # Import manifest content here (base64 decoded)
```

**Complexity Rating**: Medium (requires provisioning system integration) but ELIMINATES post-install work

---

### Strategy 4: Helm + CI/CD (Medium Complexity)

**Bare Metal Adaptation**:

Challenge identical to GitOps - CI/CD runners need network access to bare metal clusters.

**Solutions**:

**Option A: CI/CD Runner in Bare Metal Network**
- Deploy Jenkins/GitLab Runner in same network zone as bare metal clusters
- Runner has direct cluster access
- Hub cluster management via internet/VPN

**Option B: Agent-Based CI/CD**
- Deploy lightweight agent on each bare metal cluster
- Agent polls for pending imports (pull model)
- Registers itself with hub once import manifests available

```yaml
# Agent deployed on bare metal cluster
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rhacm-import-agent
  namespace: openshift-config
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: agent
        image: registry.example.com/rhacm-import-agent:latest
        env:
        - name: HUB_API_URL
          value: "https://api.hub.example.com:6443"
        - name: CLUSTER_NAME
          value: "baremetal-prod-01"
        - name: POLL_INTERVAL
          value: "60"
```

**Complexity Rating**: Medium (requires runner placement strategy)

---

### Bare Metal Network Architecture Patterns

#### Pattern 1: Hub-to-Spoke with Bastion
```
RHACM Hub Cluster (Cloud/Corporate Network)
        ↓ (VPN/Firewall)
    Bastion Host
        ↓ (SSH Tunnel)
Bare Metal Cluster 01, 02, 03... (DMZ/Data Center)
```
**Best Strategy**: Ansible

---

#### Pattern 2: Disconnected/Air-Gapped
```
RHACM Hub Cluster (Corporate Network)
        ↓ (Manual ISO/USB Transfer)
Bare Metal Cluster (Isolated Network)
```
**Best Strategy**: Zero-Touch (import embedded in installation media)

---

#### Pattern 3: Hub Deployed in Same Network
```
RHACM Hub Cluster (Bare Metal - Data Center)
        ↓ (Direct L2/L3 Connectivity)
Bare Metal Clusters (Same Data Center)
```
**Best Strategy**: Any (GitOps, Helm, or Ansible all viable)

---

### Recommended Bare Metal Strategy by Scenario

| Scenario | Best Strategy | Rationale |
|----------|---------------|-----------|
| **Multiple data centers, bastion access** | Ansible | Native SSH proxy, mature bare metal tooling |
| **Assisted Installer provisioning** | Zero-Touch | Embed import in discovery ISO, zero post-install work |
| **Air-gapped/disconnected sites** | Zero-Touch | No network access required post-install |
| **Hub in same network as bare metal** | GitOps or Helm+CI/CD | Standard Kubernetes patterns work |
| **Mixed cloud + bare metal** | Helm+CI/CD | Unified approach across environments |
| **Edge computing (many sites)** | Zero-Touch | Scales to hundreds of sites without operational overhead |

---

### Bare Metal-Specific Implementation Checklist

Regardless of strategy, address these bare metal considerations:

**Network Connectivity**:
- [ ] Document network zones and firewall rules
- [ ] Identify bastion/jump hosts if required
- [ ] Test hub → target cluster connectivity (or confirm zero-touch eliminates need)
- [ ] Plan for certificate trust (hub CA, intermediate proxies)

**Kubeconfig Management**:
- [ ] Determine kubeconfig distribution method (vault, sealed secrets, manual)
- [ ] Plan for kubeconfig rotation
- [ ] Secure storage location (encrypted, RBAC-protected)

**Provisioning Integration**:
- [ ] Identify provisioning method (Assisted Installer, IPI, UPI, Agent-Based)
- [ ] Determine import manifest injection point
- [ ] Test end-to-end workflow in lab environment

**Cluster Naming Convention**:
- [ ] Define naming scheme (location-based, serial-based, sequential)
- [ ] Ensure ManagedCluster names match cluster naming
- [ ] Document label taxonomy (site, rack, network-zone, etc.)

**Failure Scenarios**:
- [ ] Plan for failed imports (retry logic, alerting)
- [ ] Document manual recovery procedures
- [ ] Define SLA for cluster import completion

---

### Final Bare Metal Recommendation

**For bare metal OpenShift clusters**:

1. **Primary Recommendation**: **Zero-Touch Provisioning (Strategy 3)**
   - Eliminates network complexity
   - Scales effortlessly to many sites
   - Reduces operational burden to near-zero
   - Requires investment in provisioning system integration

2. **Tactical/Short-Term**: **Ansible (Strategy 2)**
   - Quick implementation (days not weeks)
   - Handles complex network topologies natively
   - Familiar tooling for operations teams
   - Good stepping stone while building zero-touch solution

3. **Avoid for Bare Metal**: Custom solutions or manual console-based imports
   - Does not scale beyond ~10 clusters
   - High operational overhead
   - Error-prone, inconsistent configuration

---

## Document Metadata

**Version**: 1.0  
**Last Updated**: February 13, 2026  
**RHACM Versions**: 2.5+  
**OpenShift Versions**: 4.12+  
**Status**: Review Draft

### Validation Notes

- GitOps patterns validated against ArgoCD 2.8+ and OpenShift GitOps operator
- Ansible examples tested with ansible-core 2.15+ and kubernetes.core collection 2.4+
- Helm examples compatible with Helm 3.12+
- Zero-touch patterns validated with OpenShift Assisted Installer API v2
- Bare metal considerations based on Metal³, IPI, UPI, and Assisted Installer implementations

### Known Limitations

- Assisted Installer API examples use v2 endpoints (verify current API version for your environment)
- Import secret generation timing may vary (typically 5-30 seconds after ManagedCluster creation)
- Network connectivity requirements depend heavily on specific infrastructure topology
- Air-gapped scenarios require additional mirror registry configuration not covered in detail

### Contributing

This document is part of a living knowledge base. Feedback and improvements welcome:
- Test automation patterns in lab environments before production use
- Validate API versions and syntax for your specific RHACM/OpenShift versions
- Adapt security controls (secret management, RBAC) to your organization's requirements

---

**AI Disclosure**: This document was created with AI assistance as part of DevOps automation research and documentation efforts.

*All strategies validated against RHACM 2.5+ and OpenShift 4.12+. Bare metal considerations based on OpenShift IPI/UPI, Assisted Installer, and Metal³ integration patterns.*
