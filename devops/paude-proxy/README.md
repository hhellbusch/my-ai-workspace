---
review: [status: unreviewed]
created: 2026-05-12
tags: proxy, paude, github, PAT, TLS, certificates
---

# Paude Proxy

Reverse proxy and traffic management layer providing TLS inspection, centralized certificate management, and API access control for the workspace.

---

## Architecture

The paude-proxy runs as an OpenShift service and intercepts all egress HTTPS traffic, performing:

- **TLS interception** — Man-in-the-middle for content inspection; requires custom CA trust
- **Access control** — Per-user PAT (Personal Access Token) management for GitHub and other services
- **Logging** — Request/response audit trail through the proxy gateway

### Certificate

Custom CA at `/etc/pki/ca-trust/source/anchors/paude-proxy-ca.crt` (issued 2026-05-12, expires 2036-05-09).

All TLS-aware tools must be configured to trust this CA:

| Tool | Configuration |
|------|--------------|
| Node.js | `NODE_EXTRA_CA_CERTS=/etc/pki/ca-trust/source/anchors/paude-proxy-ca.crt` |
| Git | Trusts system store automatically (via `ca-bundle.crt`) |
| curl / wget | Trusts system store automatically |
| Go | Trusts system store via `SSL_CERT_FILE` |

---

## Proxy Configuration

Environment variables (set globally for the Pi container):

| Variable | Value | Notes |
|----------|-------|-------|
| `HTTP_PROXY` / `http_proxy` | `http://10.89.0.2:3128` | HTTP egress |
| `HTTPS_PROXY` / `https_proxy` | `http://10.89.0.2:3128` | HTTPS egress |
| `NO_PROXY` / `no_proxy` | `localhost,127.0.0.1` | Loopback bypass |
| `NODE_EXTRA_CA_CERTS` | `/etc/pki/ca-trust/source/anchors/paude-proxy-ca.crt` | Node.js CA trust |
| `GH_TOKEN` | `paude-proxy-managed` | GitHub PAT (managed by proxy) |

### No-proxy scope

Only `localhost,127.0.0.1` is excluded. All egress to external hosts routes through the proxy, including GitHub.

---

## GitHub PAT

The token `paude-proxy-managed` is managed by the proxy layer and provides authenticated GitHub access.

### Current scopes

> To be confirmed by checking the PAT in the proxy admin UI or by running `curl -H "Authorization: token $GH_TOKEN" https://api.github.com/user`.

As of 2026-05-12, the token:
- **Works** for git HTTPS operations (clone, fetch, push) — verified via `git ls-remote`
- **Does not authenticate** the REST API endpoint (returns 401) — likely a proxy-level auth boundary, not a scope issue

### Recommended scopes

For a solo practitioner managing personal repos:

| Scope | Purpose | Needed? |
|-------|---------|---------|
| `repo` | Full control of private repos (clone, push, issues, PRs, releases, branches) | **Yes** — baseline |
| `read:org` | Read org/team membership | Only if managing org resources |
| `workflow` | Manage GitHub Actions workflows | Only if automating CI/CD |
| `read:packages` | Read GitHub Packages | Only if consuming packages |
| `write:packages` | Publish GitHub Packages | Only if publishing |

For most use cases, `repo` is sufficient.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
