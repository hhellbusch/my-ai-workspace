# RHACM Cluster Import - Ansible Automation

Simple Ansible playbook to automate importing existing OpenShift clusters into Red Hat Advanced Cluster Management (RHACM).

## Overview

This example implements **Strategy 2: Ansible Automation** from the cluster import automation strategies. It provides a single playbook that:
1. Creates `ManagedCluster` and `KlusterletAddonConfig` on the RHACM hub
2. Waits for the import secret to be generated
3. Extracts the import manifest from the secret
4. Applies the manifest to the target cluster
5. Validates the cluster is successfully imported

## Prerequisites

### Software Requirements

- Ansible Core 2.15+ installed on control node
- `kubernetes.core` collection installed
- `oc` or `kubectl` CLI available in PATH

### Install Ansible Collection

```bash
ansible-galaxy collection install kubernetes.core
```

### Access Requirements

- **Hub Cluster**: Kubeconfig with permissions to:
  - Create `ManagedCluster` resources
  - Create `KlusterletAddonConfig` resources
  - Read secrets in cluster namespaces
  
- **Target Cluster**: Kubeconfig with cluster-admin permissions to:
  - Create namespaces
  - Create operator resources
  - Create RBAC resources

### Network Requirements

- Ansible control node can reach both hub and target cluster APIs
- Target cluster can reach hub cluster (for klusterlet → hub communication)
- If using bastion hosts, configure SSH proxy in inventory

## Quick Start

### 1. Configure Inventory

Edit `inventory/hosts.ini` with your cluster details:

```ini
[rhacm_hub]
hub-cluster kubeconfig_path=/path/to/hub-kubeconfig

[target_clusters]
prod-cluster-01 kubeconfig_path=/path/to/prod-cluster-01-kubeconfig
```

### 2. Configure Cluster Variables

Edit `group_vars/target_clusters.yml` or create host-specific vars in `host_vars/`:

```yaml
# Cluster labels for placement and governance
cluster_labels:
  environment: production
  cloud: baremetal
  region: us-east-1

# Klusterlet add-ons to enable
klusterlet_addons:
  application_manager: true
  policy_controller: true
  search_collector: true
  cert_policy_controller: true
```

### 3. Run the Playbook

```bash
# Import a specific cluster
ansible-playbook -i inventory/hosts.ini import-cluster.yml \
  --limit prod-cluster-01

# Import all clusters in inventory
ansible-playbook -i inventory/hosts.ini import-cluster.yml
```

### 4. Verify Import

```bash
# Check ManagedCluster status on hub
oc get managedcluster prod-cluster-01

# Check conditions
oc get managedcluster prod-cluster-01 -o jsonpath='{.status.conditions[*].type}'
```

## Files in This Example

```
cluster-import-ansible/
├── README.md                      # This file
├── import-cluster.yml             # Main playbook
├── inventory/
│   └── hosts.ini                  # Inventory file
├── group_vars/
│   └── target_clusters.yml        # Default variables
└── host_vars/
    └── prod-cluster-01.yml        # Cluster-specific variables (example)
```

## Playbook Flow

### Step 1: Create ManagedCluster
- Creates namespace on hub (same name as cluster)
- Creates `ManagedCluster` resource with specified labels
- Sets `hubAcceptsClient: true`

### Step 2: Create KlusterletAddonConfig
- Defines which add-ons to enable
- Configures add-on settings

### Step 3: Wait for Import Secret
- Polls for `<cluster-name>-import` secret
- Timeout: 2 minutes (configurable)
- Retries every 5 seconds

### Step 4: Extract Import Manifest
- Decodes `import.yaml` from secret data
- Stores in Ansible facts for delegation

### Step 5: Apply to Target Cluster
- Applies import manifest to target cluster
- Creates klusterlet namespace and operators

### Step 6: Validate Import
- Waits for `ManagedClusterJoined` condition
- Waits for `ManagedClusterAvailable` condition
- Reports success or failure

## Customization

### Cluster Labels

Add custom labels for placement and governance:

```yaml
# host_vars/prod-cluster-01.yml
cluster_labels:
  environment: production
  datacenter: dc1
  rack: rack42
  owner: platform-team
  cost-center: "12345"
```

Labels are used by RHACM for:
- Placement policies (target clusters for apps/policies)
- Cluster organization and filtering
- Governance and compliance reporting

### Klusterlet Add-ons

Enable/disable add-ons per cluster:

```yaml
klusterlet_addons:
  application_manager: true      # Application lifecycle management
  policy_controller: true        # Policy enforcement
  search_collector: false        # Search indexing (disable for performance)
  cert_policy_controller: true   # Certificate policy management
```

### Timeout Configuration

Adjust timeouts in playbook variables:

```yaml
# In import-cluster.yml
vars:
  import_secret_timeout_seconds: 120
  import_validation_timeout_seconds: 300
```

## Bare Metal Specific Configuration

### Using Bastion/Jump Host

For bare metal clusters behind bastion hosts:

```ini
[target_clusters]
bm-prod-01 kubeconfig_path=/path/to/kubeconfig

[target_clusters:vars]
ansible_ssh_common_args='-o ProxyJump=bastion.example.com'
```

### Multiple Data Centers

Organize by location:

```ini
[dc_east]
east-bm-01 kubeconfig_path=/path/to/east-bm-01-kubeconfig
east-bm-02 kubeconfig_path=/path/to/east-bm-02-kubeconfig

[dc_west]
west-bm-01 kubeconfig_path=/path/to/west-bm-01-kubeconfig

[target_clusters:children]
dc_east
dc_west
```

Then import by data center:

```bash
ansible-playbook -i inventory/hosts.ini import-cluster.yml --limit dc_east
```

## Error Handling

### Import Secret Not Generated

**Symptom**: Playbook times out waiting for import secret

**Causes**:
- Hub cluster multicluster-engine not healthy
- Insufficient RBAC permissions
- Namespace creation failed

**Debug**:
```bash
# Check multicluster-engine status
oc get pods -n multicluster-engine

# Check namespace exists
oc get namespace prod-cluster-01

# Check for error events
oc get events -n prod-cluster-01
```

### Import Manifest Application Failed

**Symptom**: Task "Apply import manifest to target cluster" fails

**Causes**:
- Insufficient permissions on target cluster
- Network connectivity issues
- Target cluster API unavailable

**Debug**:
```bash
# Test kubeconfig connectivity
KUBECONFIG=/path/to/target-kubeconfig oc whoami
KUBECONFIG=/path/to/target-kubeconfig oc auth can-i create namespace

# Check for existing klusterlet
KUBECONFIG=/path/to/target-kubeconfig oc get klusterlet -A
```

### Cluster Not Joining

**Symptom**: ManagedCluster created but never reaches Available status

**Causes**:
- Network connectivity from target to hub blocked
- Certificate issues
- Hub cluster URL unreachable from target

**Debug**:
```bash
# On hub: Check ManagedCluster conditions
oc get managedcluster prod-cluster-01 -o yaml

# On target: Check klusterlet pods
KUBECONFIG=/path/to/target-kubeconfig oc get pods -n open-cluster-management-agent

# On target: Check klusterlet logs
KUBECONFIG=/path/to/target-kubeconfig oc logs -n open-cluster-management-agent \
  -l app=klusterlet-registration-agent
```

## Advanced Usage

### Parallel Import

Import multiple clusters in parallel using Ansible forks:

```bash
ansible-playbook -i inventory/hosts.ini import-cluster.yml --forks 5
```

**Warning**: Don't set forks too high as it can overwhelm the hub cluster.

### Dry Run

Check what would be created without making changes:

```bash
ansible-playbook -i inventory/hosts.ini import-cluster.yml --check
```

**Note**: Check mode has limitations - it can't predict secret generation.

### Integration with Ansible Tower/AAP

1. Create project pointing to this Git repository
2. Create inventory with cluster credentials
3. Create job template:
   - **Playbook**: `import-cluster.yml`
   - **Credentials**: Add kubeconfigs as file credentials
   - **Survey**: Optional - prompt for cluster name
4. Launch job template to import clusters on-demand

### Integration with CI/CD

Call from Jenkins/GitLab CI:

```groovy
stage('Import Cluster to RHACM') {
    steps {
        sh '''
            ansible-playbook -i inventory/hosts.ini import-cluster.yml \
              --limit ${CLUSTER_NAME} \
              --extra-vars "cluster_name=${CLUSTER_NAME}"
        '''
    }
}
```

## Troubleshooting Tips

### Enable Verbose Output

```bash
ansible-playbook -i inventory/hosts.ini import-cluster.yml -vvv
```

### Check Ansible Facts

Add debug tasks to playbook to inspect variables:

```yaml
- name: Debug cluster configuration
  debug:
    msg:
      - "Cluster: {{ inventory_hostname }}"
      - "Labels: {{ cluster_labels }}"
      - "Kubeconfig: {{ kubeconfig_path }}"
```

### Manual Verification Steps

```bash
# 1. Verify ManagedCluster created
oc get managedcluster <cluster-name>

# 2. Verify import secret exists
oc get secret <cluster-name>-import -n <cluster-name>

# 3. Extract and inspect import manifest
oc get secret <cluster-name>-import -n <cluster-name> \
  -o jsonpath='{.data.import\.yaml}' | base64 -d > /tmp/import.yaml
cat /tmp/import.yaml

# 4. Check target cluster klusterlet
KUBECONFIG=/path/to/target oc get pods -n open-cluster-management-agent

# 5. Verify hub accepts connection
oc get managedcluster <cluster-name> -o yaml
```

## Security Considerations

### Kubeconfig Storage

**Development/Lab**:
- Store kubeconfigs in filesystem with proper permissions (600)
- Use Ansible Vault for sensitive inventories

**Production**:
- Store kubeconfigs in HashiCorp Vault or similar
- Use Ansible Vault lookups to retrieve dynamically
- Rotate kubeconfigs regularly
- Use service accounts with limited scope when possible

Example with Ansible Vault:
```yaml
kubeconfig_path: "{{ lookup('vault', 'secret/data/kubeconfigs/prod-cluster-01') }}"
```

### RBAC Principle of Least Privilege

Create service accounts with minimal required permissions:

**Hub Cluster**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-importer
rules:
  - apiGroups: ["cluster.open-cluster-management.io"]
    resources: ["managedclusters"]
    verbs: ["create", "get", "list"]
  - apiGroups: ["agent.open-cluster-management.io"]
    resources: ["klusterletaddonconfigs"]
    verbs: ["create", "get"]
  - apiGroups: [""]
    resources: ["namespaces", "secrets"]
    verbs: ["create", "get"]
```

**Target Cluster**:
- Requires cluster-admin or equivalent for klusterlet installation
- Consider pre-creating namespace with limited scope service account

## Related Documentation

- [Cluster Import Automation Strategies](../CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md) - Strategic overview
- [Bare Metal Operator Integration](../BARE-METAL-OPERATOR-INTEGRATION.md) - Deep dive on bare metal
- [RHACM Official Docs](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)

## Next Steps

After successfully importing clusters:

1. **Configure Placement**: Create `Placement` resources to organize clusters
2. **Apply Policies**: Deploy governance policies to enforce standards
3. **Deploy Applications**: Use ApplicationSets for multi-cluster deployments
4. **Enable Observability**: Configure monitoring and alerting
5. **Automate Decommissioning**: Extend playbook to remove clusters

## Contributing

Found an issue or have an improvement?
- Test changes in lab environment first
- Update README with any new prerequisites
- Include example output in comments
- Follow existing YAML formatting

---

**Version**: 1.0  
**Tested With**: RHACM 2.5+, Ansible Core 2.15+, kubernetes.core 2.4+  
**Last Updated**: February 13, 2026

**AI Disclosure**: This example was created with AI assistance as part of DevOps automation research and documentation efforts.
