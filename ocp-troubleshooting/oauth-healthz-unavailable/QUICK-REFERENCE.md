# OAuth healthz Unavailable — Quick Reference

**Symptom:** Authentication CO degraded, `OAuthServerRouteEndpointAccessibleControllerAvailable` — healthz endpoint unavailable.

## One-liner checks

```bash
# Get condition and OAuth host
oc get co authentication -o jsonpath='{range .status.conditions[?(@.type=="Degraded")]}{.message}{"\n"}{end}'
OAUTH_HOST=$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')
echo "https://$OAUTH_HOST/healthz"
curl -vvk --connect-timeout 10 "https://$OAUTH_HOST/healthz"
```

## Error → Likely cause

| Error | Likely cause | Action |
|-------|----------------|--------|
| `connection refused` | Firewall/LB blocking | Allow masters → ingress VIP/LB:443 |
| `no such host` | DNS | Fix DNS for `oauth-openshift.apps.<domain>` |
| `timeout` | LB/backend/network | Fix LB backends, ingress pods, path |

## Key commands

```bash
oc get co authentication
oc get pods -n openshift-authentication
oc get pods -n openshift-ingress
oc get route oauth-openshift -n openshift-authentication
oc logs -n openshift-authentication-operator -l name=authentication-operator --tail=100
```

## Test from inside cluster

```bash
oc run curl-oauth-test --image=registry.access.redhat.com/ubi9/ubi-minimal:latest --rm -it --restart=Never -- \
  curl -vvk --connect-timeout 10 "https://$(oc get route oauth-openshift -n openshift-authentication -o jsonpath='{.spec.host}')/healthz"
```

## Full guide

See [README.md](README.md).
