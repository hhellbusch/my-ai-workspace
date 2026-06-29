# Disconnected OpenShift Install (Quay + oc-mirror)

Stand up OpenShift in environments without reliable outbound internet: Quay mirror registry, `oc-mirror` content sync, and cluster image redirect via `ImageDigestMirrorSet`.

**Example target:** OpenShift `4.18.14` on `stable-4.18` — substitute per environment.

## Contents

| Document | Purpose |
|----------|---------|
| **[working-guide.md](working-guide.md)** | Start here — phased execution, storage, mirror-registry, oc-mirror |
| **[imageset-examples.md](imageset-examples.md)** | Copy-paste ImageSetConfiguration (platform / operators / combined) |
| **[BRIEF.md](BRIEF.md)** | Scope, success criteria, architecture |

## Stack at a glance

```
oc-mirror (connected or air-gap) → Quay → validate → install + IDMS → disconnected OperatorHub
```

## Workflow after mirroring

1. **Validate** — release digest, catalog tags, archive `cluster-resources/`
2. **Install** (greenfield) — `install-config` + `manifests/` + mirrored release image
3. **OperatorHub** — disable defaults, apply catalogs, `Subscription` per operator
4. **Operate** — incremental oc-mirror for new operators / z-streams

See [working-guide.md](working-guide.md) Phase 2b onward. Existing clusters skip install — apply Phase 4 only.

## Related in this repo

- [Disconnected appendix (learning path)](../../learning-path/vmware-admins/README.md#appendix-disconnected-and-air-gapped-environments) — conceptual overview across fleet phases
- [CIM hub mirror setup](../../rhacm/notes/cim-hub-setup.md) — assisted install / ACM provisioning
- [Agent install preflight](../../rhacm/notes/agent-install-preflight.md) — gating ACM agent-based installs before install runs
- [Image registry auth troubleshooting](../troubleshooting/image-registry-auth/README.md) — TLS and pull-secret patterns

## Official docs

- [OCP 4.18 disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/)
- [oc-mirror plugin (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-images-for-a-disconnected-installation)
- [mirror-registry](https://docs.redhat.com/en/documentation/red_hat_quay/latest/html/red_hat_quay_installation_and_configuration_on_openshift_with_mirror_registry/)
