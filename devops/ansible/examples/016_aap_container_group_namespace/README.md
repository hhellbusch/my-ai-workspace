---
review:
  status: unreviewed
  notes: "Example namespace + container group for AAP 2.7 operator on OCP."
---

# 016 — Isolate AAP job pods in a tenant namespace

> **Audience:** Operators who have AAP on OpenShift and want execution (EE) pods off the controller namespace.
>
> **Purpose:** Reproduce one tenant job namespace, a scoped ServiceAccount, a container group, and a sample job that lands in that namespace — not in the AAP namespace.

This is **execution isolation**, not a second AAP.
Gateway, postgres, and the controller database stay shared.
See [AAP operator on OpenShift](../../aap-operator-on-openshift.md) for that split.

Official procedure: [Control where automation runs with container groups](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/administer-con_controller_container_groups) and [OpenShift or Kubernetes API Bearer Token](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/secure-ref_controller_credential_openshift) (AAP 2.7).

---

## What this example creates

| Layer | Name |
|---|---|
| OpenShift project | `aap-jobs-smoke` |
| ServiceAccount | `aap-job-runner` (Role: pods, pods/log, pods/attach, secrets — namespace only) |
| Guardrails | LimitRange, ResourceQuota, NetworkPolicy (deny ingress from other namespaces) |
| AAP credential | `ocp-aap-jobs-smoke` (Kubernetes bearer token — **not** stored in git) |
| AAP container group | `hello-world-isolated` |
| Sample job | [015 localhost playbook](../015_aap_hello_world_smoke/README.md) pinned to that group |

Instance group lookup: **job template → inventory → organization**.
This example pins the **job template** (and its inventory) so it cannot fall back into the default group in the AAP namespace.

---

## 1. Apply OpenShift objects

```bash
oc apply -f manifests/
```

Confirm:

```bash
oc get ns,sa,role,rolebinding,limitrange,resourcequota,networkpolicy -n aap-jobs-smoke
```

---

## 2. Token and CA (keep off disk in git)

```bash
# Bound token — duration matches the AAP 2.7 sample (one year)
oc create token aap-job-runner -n aap-jobs-smoke --duration=8760h

# API server CA (validates https://api.<cluster>:6443)
oc get configmap kube-root-ca.crt -n aap-jobs-smoke -o jsonpath='{.data.ca\.crt}'
```

Do not commit the token.
Rotate by creating a new token and updating the AAP credential.

---

## 3. AAP credential

**Credential type:** OpenShift or Kubernetes API Bearer Token

| Field | Value |
|---|---|
| Name | `ocp-aap-jobs-smoke` |
| OpenShift or Kubernetes API Endpoint | `oc whoami --show-server` |
| Bearer token | from `oc create token` |
| SSL CA Certificate | `kube-root-ca.crt` contents |
| Verify SSL | true |

---

## 4. Container group

**Infrastructure → Instance Groups → Create container group**

| Field | Value |
|---|---|
| Name | `hello-world-isolated` |
| Credential | `ocp-aap-jobs-smoke` |
| Customize pod spec | on — paste [pod-spec-override.yaml](pod-spec-override.yaml) |

The EE image on the job template still wins.
`metadata.namespace` and `spec.serviceAccountName` are what keep the pod out of the AAP namespace.

---

## 5. Pin a job template

On the inventory and job template you want isolated, set **Instance groups** to `hello-world-isolated` only.
[015](../015_aap_hello_world_smoke/README.md) is a convenient localhost job for that check.

Launch the template, then:

```bash
oc get pods -n aap-jobs-smoke -w
```

A short `pause` / `sleep` in the playbook is there so the pod stays long enough to see.
`oc get pods -n <aap-ns>` should **not** grow a new `automation-job-*` for that launch.

---

## What this does not isolate

- AAP organizations, credentials, and job templates (one controller DB)
- Hub content, EDA, gateway
- Egress from the job pod (NetworkPolicy here is ingress-only)
- Super-admin or a stolen Kubernetes token credential for this namespace

Per-org copies of this namespace + SA + container group, assigned on the **Organization**, is the usual tenant pattern.
Do not give org admins the bearer-token credential for another org’s namespace.

---

## Related reading

- [015 hello-world smoke test](../015_aap_hello_world_smoke/README.md)
- [Instance groups](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/administer-assembly_ug_controller_instance_groups) — *Determine where automation runs with instance groups*, AAP 2.7
- [Namespace guardrails](../../../ocp/guides/namespace-guardrails/README.md) — object-count quotas when tenants are noisy

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
