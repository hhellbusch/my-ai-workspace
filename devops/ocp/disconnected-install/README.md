# Disconnected OpenShift Install (Quay + oc-mirror)

Stand up OpenShift in environments without reliable outbound internet: Quay mirror registry, `oc-mirror` content sync, and cluster image redirect via `ImageDigestMirrorSet`.

**Target release:** OpenShift **4.18.14** (`stable-4.18`)

## Contents

| Document | Purpose |
|----------|---------|
| **[working-guide.md](working-guide.md)** | Start here — phased execution, worksheet, commands, checklists |
| **[BRIEF.md](BRIEF.md)** | Scope, success criteria, architecture, open decisions |

## Stack at a glance

```
oc-mirror (connected or air-gap) → Quay mirror registry → OCP install + IDMS → disconnected OperatorHub
```

## Related in this repo

- [Disconnected appendix (learning path)](../../learning-path/vmware-admins/README.md#appendix-disconnected-and-air-gapped-environments) — conceptual overview across fleet phases
- [CIM hub mirror setup](../../rhacm/notes/cim-hub-setup.md) — assisted install / ACM provisioning
- [Image registry auth troubleshooting](../troubleshooting/image-registry-auth/README.md) — TLS and pull-secret patterns

## Official docs

- [OCP 4.18 disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/)
- [oc-mirror plugin (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-images-for-a-disconnected-installation)
- [mirror-registry](https://docs.redhat.com/en/documentation/red_hat_quay/latest/html/red_hat_quay_installation_and_configuration_on_openshift_with_mirror_registry/)
