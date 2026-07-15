# Red Hat Documentation Links

Conventions for `docs.redhat.com` URLs in committed workspace content (`devops/`, `docs/`, `library/`, `research/` findings).

**Why:** Red Hat reorganizes documentation frequently. Slugs move between books, chapters merge (e.g. standalone canary chapter → section 3.4 of *Performing a cluster update*), and `/latest/` redirects can 404 on old paths. AI-generated URLs are especially prone to plausible-but-dead slugs.

---

## Defaults

| Situation | Link form |
|-----------|-----------|
| Doc tied to a **specific OCP/ACM minor** (troubleshooting, install guide, versioned API) | Pin minor: `.../openshift_container_platform/4.22/html/...` |
| General reference (concept stable across minors) | Pin a verified minor **or** use `/latest/` with searchable link text (see below) |
| MCO / operator design detail | Prefer GitHub `raw.githubusercontent.com/openshift/<repo>/master/docs/...` when upstream maintains it |
| Product landing / broad topic | `/latest/` acceptable if verified |

**Avoid** committing `/latest/` URLs without verifying they resolve **and** without human-readable fallback text (chapter + section title).

---

## Link text (required for Red Hat URLs)

Link text must let a reader find the page if the URL breaks:

```markdown
<!-- Good -->
[Performing a canary rollout update](https://docs.redhat.com/.../performing-a-cluster-update#update-using-custom-machine-config-pools) — section 3.4, *Performing a cluster update*

<!-- Weak -->
[Red Hat docs](https://docs.redhat.com/.../update-using-custom-machine-config-pools)
```

Include **product**, **book/chapter name**, and **section number or title** when known.

---

## Verification (required before commit)

For each new or changed `docs.redhat.com` URL:

1. **Fetch** — `curl -sI -L -o /dev/null -w "%{http_code} %{url_effective}\n" "<url>"` (expect `200`; note final URL after redirects).
2. **Anchor** — If using `#fragment`, confirm the section exists on the resolved page (view source or search for `id="..."`).
3. **Review** — `/review` flags unverified Red Hat URLs; treat 404 on `/latest/` as a signal to pin version or update slug.

`/latest/` resolving today does not guarantee the slug tomorrow. Pinned minors also drift — prefer verification at commit time over assuming permanence.

---

## When reorganizations happen

1. Search docs.redhat.com for the **chapter title** (not the old slug).
2. Update URL; keep or migrate anchor if Red Hat preserved the `id`.
3. Pin to the minor you verified (e.g. `4.22`) unless the doc is explicitly version-agnostic.
4. Note the fix in commit message (`fix: Red Hat doc slug for canary MCP rollout`).

---

## Examples in this repo

| Pattern | Example |
|---------|---------|
| Pinned minor | [`devops/rhacm/notes/acm-bare-metal-network-requirements.md`](../devops/rhacm/notes/acm-bare-metal-network-requirements.md) — OCP 4.20, ACM 2.16 |
| Section title in link text | [`devops/ocp/notes/machine-config-pools.md`](../devops/ocp/notes/machine-config-pools.md) — canary rollout |
| Upstream design doc | MCO [`custom-pools.md`](https://github.com/openshift/machine-config-operator/blob/master/docs/custom-pools.md) |

---

## Anti-patterns

- Bare `docs.redhat.com/.../latest/...` with generic link text ("see Red Hat docs")
- Assuming chapter slugs are stable across OCP releases
- Skipping URL fetch because the path "looks right"
- Using OKD URLs (`docs.okd.io`) as stand-ins for OCP without noting the product difference
