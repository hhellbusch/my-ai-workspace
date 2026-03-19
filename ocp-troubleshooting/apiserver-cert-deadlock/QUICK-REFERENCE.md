# API Server Cert Deadlock – Quick Reference

## 1. Get access (from a control plane node)

```bash
ssh core@<control-plane-ip>
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes
```

## 2. List serving cert secrets

```bash
oc get secrets -n openshift-kube-apiserver | grep -E "serving|cert"
```

Common: `localhost-serving-cert-certkey`, `localhost-recovery-serving-certkey`, `service-network-serving-certkey`, `external-loadbalancer-serving-certkey`.

## 3. Force cluster to re-issue (delete secret + restart API)

```bash
SECRET_NAME=localhost-serving-cert-certkey   # or the one that’s bad
oc delete secret -n openshift-kube-apiserver $SECRET_NAME
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
watch oc get pods -n openshift-kube-apiserver
```

## 4. Apply your own cert (then restart API)

```bash
SECRET_NAME=localhost-serving-cert-certkey
oc create secret tls $SECRET_NAME --cert=/path/to/tls.crt --key=/path/to/tls.key -n openshift-kube-apiserver --dry-run=client -o yaml | oc apply -f -
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
```

## 5. Operator not syncing – restart operator then API

```bash
oc delete pods -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator
# wait for operator to be ready
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
```

## 6. API unreachable – fix on node

```bash
SECRET_DIR=/etc/kubernetes/static-pod-certs/secrets/localhost-serving-cert-certkey
sudo cp /path/to/tls.crt $SECRET_DIR/tls.crt
sudo cp /path/to/tls.key $SECRET_DIR/tls.key
sudo chmod 644 $SECRET_DIR/tls.crt
sudo chmod 600 $SECRET_DIR/tls.key
sudo systemctl restart kubelet
```

Then verify: `curl -k https://localhost:6443/healthz` and `oc get nodes` with localhost kubeconfig.

---

Full flow: [README.md](README.md).
