# Sysbench benchmark image (UBI 9 micro, hardened)

**Registry:** [quay.io/rh_hhellbusch/sysbench](https://quay.io/repository/rh_hhellbusch/sysbench)

## Security model

The original EPEL-based image pulled in packages Quay/Trivy flagged (e.g. `mariadb-connector-c`, `curl-minimal`). The current Dockerfile:

| Issue (old image) | Fix |
|-------------------|-----|
| MariaDB client CVEs from EPEL `sysbench` RPM | Build sysbench from source with `--without-mysql` |
| `curl-minimal` CVEs in runtime | **UBI micro** runtime — no shell, no curl, no package manager |
| Large attack surface | Only `sysbench` + glibc runtime libs |
| Root container | `USER 65532:65532` |
| Privileged pod | Jobs use `restricted`-compatible `securityContext` |

**Scope:** CPU and memory benchmarks only. Database (`oltp_*`) tests are not supported in this image.

## Build and push

From this directory:

```bash
podman login quay.io

podman build -t quay.io/rh_hhellbusch/sysbench:1.0.20 .

podman push quay.io/rh_hhellbusch/sysbench:1.0.20

# Optional: also tag latest after you verify Quay scan is clean
podman tag quay.io/rh_hhellbusch/sysbench:1.0.20 quay.io/rh_hhellbusch/sysbench:latest
podman push quay.io/rh_hhellbusch/sysbench:latest
```

Pin by digest in Jobs after push:

```bash
podman inspect quay.io/rh_hhellbusch/sysbench:1.0.20 --format '{{.Digest}}'
```

### Verify locally (optional)

```bash
podman run --rm quay.io/rh_hhellbusch/sysbench:1.0.20 cpu --threads=2 --time=3 run

# Scan with Trivy (export image first)
podman save quay.io/rh_hhellbusch/sysbench:1.0.20 -o /tmp/sysbench.tar
podman run --rm -v /tmp:/tmp docker.io/aquasec/trivy:latest \
  image --scanners vuln --input /tmp/sysbench.tar
```

Re-trigger Quay security scanning after push from the repository **Security** tab.

## Pull on OpenShift

If the repo is **private**, create a pull secret in the `benchmark` namespace:

```bash
oc create secret docker-registry quay-rh-hhellbusch \
  --docker-server=quay.io \
  --docker-username=... \
  --docker-password=... \
  -n benchmark

oc secrets link default quay-rh-hhellbusch --for=pull -n benchmark
```

## Run benchmarks

```bash
oc apply -f sysbench-jobs.yaml
oc logs -n benchmark job/sysbench-cpu -f
oc logs -n benchmark job/sysbench-memory -f
```

Re-run: delete completed Jobs first (`oc delete job -n benchmark sysbench-cpu sysbench-memory`).

Jobs use `readOnlyRootFilesystem`, drop all capabilities, and mount `emptyDir` at `/tmp`.
