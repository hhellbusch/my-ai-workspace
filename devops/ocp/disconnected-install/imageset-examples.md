# ImageSetConfiguration examples (oc-mirror v2)

Reference `ImageSetConfiguration` files for disconnected mirroring.
Substitute your OCP minor (`v4.18`), z-stream (`4.18.14`), channel (`stable-4.18`), and mirror FQDN.

Use with:

```bash
oc mirror -c <file>.yaml \
  --workspace file://$(pwd)/mirror-workspace \
  docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX} \
  --dest-skip-tls=false \
  --image-timeout=2h \
  --retry-times=5 \
  --v2
```

Add `--dest-skip-tls=true` only for lab until the mirror CA is trusted everywhere.

---

## Platform only (first mirror run)

Prove Quay storage wiring and release payload before operators.

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
storageConfig:
  registry:
    imageURL: mirror.example.com/ocp4/metadata:latest
    skipTLS: false
mirror:
  platform:
    architectures:
      - amd64
    channels:
      - name: stable-4.18
        minVersion: "4.18.14"
        maxVersion: "4.18.14"
        shortestPath: true
        type: ocp
    graph: false
  operators: []
  additionalImages: []
```

**Success:** all release images mirrored (count varies by version); `/quay` or `--quayStorage` mount grows; `/` stays flat.

---

## Operators only (incremental)

Run after platform succeeds.
Use a **fresh workspace** after registry rebuilds or catalog failures.

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
storageConfig:
  registry:
    imageURL: mirror.example.com/ocp4/metadata:latest
    skipTLS: false
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
      packages:
        - name: kubevirt-hyperconverged

    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.18
      packages:
        - name: portworx-certified
```

Verify package names before mirroring:

```bash
oc mirror list operators \
  --catalog=registry.redhat.io/redhat/certified-operator-index:v4.18 \
  | grep -i portworx
```

---

## Combined (full re-mirror)

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
storageConfig:
  registry:
    imageURL: mirror.example.com/ocp4/metadata:latest
    skipTLS: false
mirror:
  platform:
    architectures:
      - amd64
    channels:
      - name: stable-4.18
        minVersion: "4.18.14"
        maxVersion: "4.18.14"
        shortestPath: true
        type: ocp
    graph: false
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
      packages:
        - name: kubevirt-hyperconverged
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.18
      packages:
        - name: portworx-certified
  additionalImages:
    - name: registry.redhat.io/ubi9/ubi:latest
```

Set `graph: true` only when standing up OpenShift Update Service (OSUS) in the disconnected zone.

---

## Operator catalog map (common packages)

| Operator | Catalog | Package name (verify with `oc mirror list`) |
|----------|---------|-----------------------------------------------|
| OpenShift Virtualization | `redhat-operator-index:v4.18` | `kubevirt-hyperconverged` |
| Portworx | `certified-operator-index:v4.18` | `portworx-certified` |
| ACM | `redhat-operator-index:v4.18` | `advanced-cluster-management` |
| OpenShift GitOps | `redhat-operator-index:v4.18` | `openshift-gitops-operator` |

Catalog tag is always **`v4.18`** (with `v`), matching the OCP minor.

---

## Avoid

| Pattern | Why |
|---------|-----|
| `targetCatalog` / `targetTag` on operator entries | Known to break certified catalog staging in oc-mirror v2 |
| Bare catalog with no `packages:` | Mirrors or decomposes unpredictably |
| Portworx on `redhat-operator-index` | Wrong catalog — use `certified-operator-index` |
| Reusing workspace after Quay rebuild | Stale `localhost:55000` cache → `manifest unknown` |
| `graph: true` on first troubleshooting run | Extra moving parts — enable when OSUS is in scope |
