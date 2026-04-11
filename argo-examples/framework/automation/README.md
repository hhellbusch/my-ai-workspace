# Automation

Tooling for cluster onboarding and lifecycle management.

## Cluster Onboarding

Two entry points — choose based on your workflow:

### 1. GitHub Actions (Recommended)

Run the **Onboard New Cluster** workflow from the GitHub Actions UI:

```
Actions → Onboard New Cluster → Run workflow
```

Fill in the form fields (cluster name, environment, OCP version, etc.) and
the pipeline handles everything: config generation, Ansible integrations,
aggregation, commit, and PR creation.

### 2. Manual (Ansible CLI)

For environments without GitHub Actions, or when you need more control:

```bash
# Step 1: Copy template
cp -r clusters/_template clusters/my-new-cluster

# Step 2: Edit cluster.yaml and values.yaml
vim clusters/my-new-cluster/cluster.yaml
vim clusters/my-new-cluster/values.yaml

# Step 3: Run Ansible for external integrations
ansible-playbook automation/ansible/onboard-cluster.yaml \
  -e cluster_name=my-new-cluster \
  -e cluster_environment=production \
  -e cluster_server_url=https://api.my-new-cluster.example.com:6443 \
  -e cluster_ingress_domain=apps.my-new-cluster.example.com \
  -e cluster_region=us-east \
  -e cluster_ocp_version=4.15 \
  -e cluster_storage_class=ocs-storagecluster-ceph-rbd

# Step 4: Regenerate label aggregation
bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework

# Step 5: Commit and push
git add . && git commit -m "feat: onboard cluster my-new-cluster"
git push origin main
```

## Ansible Role: onboard-cluster

The `onboard-cluster` role handles external ecosystem integrations:

| Integration        | What It Does                                           | Gate Flag                         |
|--------------------|--------------------------------------------------------|-----------------------------------|
| **Vault**          | Creates secret path, stores metadata, copies globals   | `integrations.vault`              |
| **CMDB**           | Registers cluster as a configuration item              | `integrations.cmdb`               |
| **DNS**            | Creates DNS entries for ingress domain                 | `integrations.dns`                |
| **Monitoring**     | Registers with external monitoring (Datadog, etc.)     | `integrations.monitoring_external`|
| **Notifications**  | Sends Slack/PagerDuty notification                     | `integrations.notification_channels` |

Each integration is independently togglable and wrapped in rescue blocks
so a single failure doesn't block the entire onboarding.

## Jenkins / GitLab CI

The Ansible playbook is CI-agnostic. For Jenkins or GitLab:

```groovy
// Jenkinsfile example
stage('Onboard Cluster') {
  steps {
    sh '''
      ansible-playbook automation/ansible/onboard-cluster.yaml \
        -e cluster_name=${CLUSTER_NAME} \
        -e cluster_environment=${ENVIRONMENT} \
        ...
    '''
  }
}
```

```yaml
# .gitlab-ci.yml example
onboard-cluster:
  stage: provision
  script:
    - ansible-playbook automation/ansible/onboard-cluster.yaml
      -e "cluster_name=${CLUSTER_NAME}"
      -e "cluster_environment=${ENVIRONMENT}"
      ...
```
