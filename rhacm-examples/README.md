# Red Hat Advanced Cluster Management (RHACM) Examples

This directory contains practical examples for working with Red Hat Advanced Cluster Management for Kubernetes (RHACM).

## What is RHACM?

Red Hat Advanced Cluster Management (RHACM) provides end-to-end management for Kubernetes clusters across multiple clouds and on-premises environments. It enables:

- **Multi-cluster Management**: Single pane of glass for multiple OpenShift/Kubernetes clusters
- **Application Lifecycle**: Deploy and manage applications across clusters
- **Policy-based Governance**: Enforce security and configuration policies
- **Observability**: Centralized monitoring and alerting

## ⚠️ RHACM 2.15+ Best Practices

**All examples in this repository follow RHACM 2.15+ best practices:**

✅ Use `Placement` API (not deprecated `PlacementRule`)  
✅ Use `ManagedClusterSet` for cluster organization  
✅ Use `ManagedClusterSetBinding` in policy namespaces  
✅ Use Hub secret references with `fromSecret` template function  
✅ Include tolerations for cluster resilience  

**See [RHACM-2.15-BEST-PRACTICES.md](./RHACM-2.15-BEST-PRACTICES.md) for complete migration guide and best practices.**

## Prerequisites

- RHACM Hub cluster installed and configured
- One or more managed clusters connected to the Hub
- `oc` CLI configured with Hub cluster access
- Appropriate RBAC permissions to create policies and placements

## Examples Directory Structure

```
rhacm-examples/
├── README.md                    # This file
└── secret-management/           # Secret management across managed clusters
    ├── 1_basic_secret_distribution/
    ├── 2_managed_service_accounts/
    ├── 3_external_secrets_operator/
    ├── 4_registry_credentials/
    ├── 5_database_secrets/
    └── 6_advanced_patterns/
```

## Quick Start

Each example directory contains:
- **README.md** - Detailed explanation and use case
- **YAML manifests** - Ready-to-apply configurations
- **Validation steps** - How to verify the example works

### Basic Workflow

1. Review the example's README
2. Customize the YAML files for your environment
3. Apply to your RHACM Hub cluster:
   ```bash
   oc apply -f <example-directory>/
   ```
4. Verify with the validation steps provided

## Security Considerations

- **Never commit real secrets** to version control
- Use **external secret stores** (Vault, AWS SM, etc.) for production
- Enable **etcd encryption** on all clusters
- Follow **least privilege** principle for RBAC
- Implement **secret rotation** policies
- Audit secret access regularly

## Architecture Patterns

### Pattern 1: Policy-Based Distribution
Push secrets from Hub to managed clusters using Policies. Good for:
- Registry pull secrets
- CA certificates
- Simple configuration secrets

### Pattern 2: ManagedServiceAccounts
Create ServiceAccounts on managed clusters with tokens stored on Hub. Good for:
- Automation tooling access
- CI/CD pipeline credentials
- Cross-cluster communication

### Pattern 3: External Secrets Operator (ESO)
Sync secrets from external stores to managed clusters. Good for:
- Production application secrets
- Sensitive credentials requiring audit trails
- Dynamic secret generation
- Multi-environment deployments

## Additional Resources

- [RHACM Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [RHACM Policy Collection](https://github.com/stolostron/policy-collection)
- [External Secrets Operator](https://external-secrets.io/)
- [Kubernetes Secrets Best Practices](https://kubernetes.io/docs/concepts/configuration/secret/)

## Contributing

Found an issue or have an improvement? Please:
1. Test your changes against a real RHACM environment
2. Document all prerequisites and assumptions
3. Include validation steps
4. Follow the existing structure and naming conventions

## Related Examples

- [Ansible Examples](../ansible-examples/) - Automation for cluster operations
- [Argo CD Examples](../argo-examples/) - GitOps application delivery
- [CoreOS Examples](../coreos-examples/) - CoreOS-specific configurations

