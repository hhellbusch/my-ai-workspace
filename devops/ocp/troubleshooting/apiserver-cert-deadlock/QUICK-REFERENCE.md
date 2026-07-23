---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# API Server Cert Deadlock – Quick Reference

Fast triage, access, and remediation for API TLS trust failures after a bad or partial cert rollout.

## Decision Tree

```
API / console unreachable from outside?
│
├─ Read the oc error
│  ├─ connection refused / timeout → network or apiserver down
│  │     (see CoreOS Networking; curl -k healthz to confirm)
│  └─ x509: unknown authority / verify failed → THIS GUIDE
│
├─ curl -k https://api.<cluster-domain>:6443/healthz
│  ├─ ok + oc fails TLS → cert trust mismatch (continue below)
│  └─ fails → apiserver down or network path broken (not cert-only)
│
├─ Try emergency oc (triage only)
│  └─ oc get co --insecure-skip-tls-verify
│        ├─ works → fix secrets / operator (Steps 3–5), then restore trust
│        └─ fails → need master access
│
├─ Reach a control plane node
│  ├─ ssh core@<control-plane-ip>
│  └─ or: ssh -J core@<worker-ip> core@<control-plane-ip>
│
├─ localhost kubeconfig on master
│  └─ export KUBECONFIG=.../localhost.kubeconfig && oc get co
│        ├─ works → Steps 2–3 (fix serving secrets, restart API)
│        └─ fails → Step 6 (filesystem fix on node)
│
└─ Verify from outside
   └─ oc get co   (no --insecure-skip-tls-verify)
```

---

## 0. Triage (any node you can reach)

```bash
API_URL=https://api.<cluster-domain>:6443

# API listening? (ignores cert trust)
curl -k --connect-timeout 5 "${API_URL}/healthz"

# Cert the API presents
echo | openssl s_client -connect api.<cluster-domain>:6443 \
  -servername api.<cluster-domain> 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

| `healthz` | `oc` error | Meaning |
|-----------|------------|---------|
| `ok` | `unknown authority` | API up; fix cert trust |
| fail | any | Network or apiserver down first |
| `ok` | `connection refused` from bastion only | Path/firewall/DNS — compare worker vs bastion |

---

## 1. Emergency oc (triage only — not a permanent fix)

```bash
oc get co --insecure-skip-tls-verify
oc get secrets -n openshift-kube-apiserver --insecure-skip-tls-verify | grep serving
oc get apiserver cluster -o yaml --insecure-skip-tls-verify
```

---

## 2. Reach a control plane node

```bash
# Direct
ssh -i ~/.ssh/<install-key> core@<control-plane-ip>

# Via worker hop (bastion cannot reach masters)
ssh -i ~/.ssh/<install-key> -J core@<worker-ip> core@<control-plane-ip>

# Test master SSH from worker
nc -zv <control-plane-ip> 22
```

RHCOS `core` is SSH-key-only. BMC console can confirm boot state but usually cannot provide a shell.

---

## 3. Localhost kubeconfig (on master)

```bash
export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig
oc get nodes
oc get co kube-apiserver
```

---

## 4. List serving cert secrets

```bash
oc get secrets -n openshift-kube-apiserver | grep -E "serving|cert"
```

Common: `localhost-serving-cert-certkey`, `localhost-recovery-serving-certkey`, `service-network-serving-certkey`, `external-loadbalancer-serving-certkey`.

---

## 5. Force cluster to re-issue (delete secret + restart API)

```bash
SECRET_NAME=localhost-serving-cert-certkey   # or the one that's bad
oc delete secret -n openshift-kube-apiserver $SECRET_NAME
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
watch oc get pods -n openshift-kube-apiserver
```

---

## 6. Apply your own cert (then restart API)

```bash
SECRET_NAME=localhost-serving-cert-certkey
oc create secret tls $SECRET_NAME --cert=/path/to/tls.crt --key=/path/to/tls.key \
  -n openshift-kube-apiserver --dry-run=client -o yaml | oc apply -f -
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
```

---

## 7. Operator not syncing – restart operator then API

```bash
oc delete pods -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator
# wait for operator to be ready
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
```

---

## 8. Custom certs (openshift-config)

```bash
oc get apiserver cluster -o yaml
oc get secrets -n openshift-config
# Fix tls secret + apiserver/cluster reference, then:
oc delete pods -n openshift-kube-apiserver-operator -l app=kube-apiserver-operator
oc delete pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver
```

---

## 9. API unreachable even on master – fix on node filesystem

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

## Error → Action

| Error | Action |
|-------|--------|
| `openssl s_client` issuer changes between runs | Two apiservers / IP conflict | [Stale node IP conflict](../bare-metal-stale-node-ip-conflict/README.md) first |
| `x509: certificate signed by unknown authority` (stable issuer) | Triage §0 → emergency oc §1 or master localhost kubeconfig §3 |
| `tls: private key does not match public key` | Replace cert **and** key together (§6 or §9) |
| Console/oauth CO degraded | Fix API trust first; console is downstream |
| `unknown authority` on MCS :22623 during worker join | [Worker Node TLS](../worker-node-tls-cert-failure/README.md) — different guide |

---

Full flow: [README.md](README.md) · Navigation: [INDEX.md](INDEX.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
