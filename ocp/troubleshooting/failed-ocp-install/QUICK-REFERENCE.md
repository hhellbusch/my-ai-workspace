# Failed OCP Install – Quick Reference

Fast commands for troubleshooters who already know the install phases. For full explanations and teaching content, see [README.md](README.md).

## Set kubeconfig (install host)

```bash
export KUBECONFIG=/path/to/install/dir/auth/kubeconfig
```

## 1. Where am I stuck?

```bash
# Install log – last errors
tail -100 .openshift_install.log

# Can I reach the API?
oc get nodes && oc get co
# If no: API not reachable → SSH to control plane or check bootstrap
# If yes: API up → check CSRs and operators
```

## 2. API not reachable – use control plane localhost kubeconfig

```bash
ssh core@<control-plane-ip>
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes
oc get co
```

## 3. Bootstrap not complete – watch bootstrap

```bash
ssh core@<bootstrap-ip>
sudo journalctl -u bootkube.service -f
```

## 4. API works – pending CSRs

```bash
oc get csr | grep Pending
# Approve all pending (verify requestors first)
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
oc get nodes
```

## 5. API works – problematic operators

```bash
oc get co | grep -v "True.*False.*False"
oc describe co <name>   # read Message/Reason
```

## 6. Collect diagnostics

**API up:** `oc adm must-gather --dest-dir=./must-gather-$(date +%Y%m%d-%H%M%S)`

**API down (failed install):** From the install directory: `./openshift-install gather bootstrap --dir .` (IPI). For UPI, add `--bootstrap <ip> --master <ip> ...`.

## Decision tree

| Symptom | Action |
|--------|--------|
| `oc` fails (refused/timeout/TLS) | SSH to control plane → localhost kubeconfig; if TLS errors → [apiserver-cert-deadlock](../apiserver-cert-deadlock/README.md) |
| Bootstrap never completes | SSH to bootstrap → `journalctl -u bootkube.service -f`; bare metal nodes stuck → [bare-metal-node-inspection-timeout](../bare-metal-node-inspection-timeout/README.md) |
| Pending CSRs | Approve CSRs; details → [csr-management](../csr-management/README.md) |
| kube-controller-manager / kube-apiserver degraded | [kube-controller-manager-crashloop](../kube-controller-manager-crashloop/README.md), [apiserver-cert-deadlock](../apiserver-cert-deadlock/README.md) |
| Workers not joining, TLS errors | [worker-node-tls-cert-failure](../worker-node-tls-cert-failure/README.md) |
| Need install timeline / monitoring | [control-plane-kubeconfigs/INSTALL-MONITORING](../control-plane-kubeconfigs/INSTALL-MONITORING.md) |
| Destroy cluster, no metadata | [destroy-cluster-without-metadata](../destroy-cluster-without-metadata/README.md) |

## Verify install complete

```bash
oc get co | grep -v "True.*False.*False"   # only header = good
oc get nodes
./openshift-install wait-for install-complete
```

## Red Hat resources

- [Troubleshooting installation issues](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/validation_and_troubleshooting/installing-troubleshooting) (official install troubleshooting)
- [Gathering cluster data](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/support/gathering-cluster-data) (gather bootstrap vs must-gather)
- [Customer Portal](https://access.redhat.com/) (support, knowledge base)
- Full list: see [README – Red Hat and OpenShift Resources](README.md#red-hat-and-openshift-resources)
